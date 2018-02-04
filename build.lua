local path = require("lbuild.path")
local promise = require("lbuild.promise")
local runner = require("lbuild.runner")
local ffi = require("ffi")
local pktbl = nil

--function to set environment vars
ffi.cdef[[
int setenv(const char *name, const char *value, int overwrite);
char *strerror(int errnum);
]]
os.setenv = function(name, value)
    local code = ffi.C.setenv(name, value, 1)
    if code == -1 then
        error(ffi.C.strerror(ffi.errno()))
    end
end

--set HOSTARCH
if os.getenv("HOSTARCH") == nil then
    local harch = jit.arch
    if harch == "x64" then
        harch = "x86_64"
    end
    os.setenv("HOSTARCH", harch)
end

--load the package table
local function loadpktbl()
    local t = {}
    local l
    for l in io.lines("pkgens.list") do
        local pkg, path = string.match(l, "([^=]*)=([^=]*)")
        t[pkg] = path
    end
    pktbl = t
end

--generator for list files
ruletable:addgenerator(function(name)
    if path:getext(name) == ".list" then
        --it is something else
        if path:dirname(name) ~= "lists" then
            return nil
        end
        local rule = {}
        rule.name = name
        function rule:deps()
            return promise(function(s, f)
                ruletable:run("pkgens.list"):prom(function()
                    if pktbl == nil then
                        loadpktbl()
                    end
                    local pkgen = pktbl[path:basename(name)]
                    if pkgen == nil then
                        f("Invalid list dep")
                    end
                    self.pkgen = pkgen
                    s({pkgen})
                end, f)
            end)
        end
        function rule:run()
            return runner:run("pkgen", "-i", self.pkgen, "-o", name, "pkgs")
        end
        return rule
    end
    return nil
end)

--add rule for pkgens.list file
addcmd("pkgens.list", (function()
    local f = assert(io.popen("find pkgs -name \"pkgen.yaml\""))
    local pkl = {}
    local l
    for l in f:lines() do
        table.insert(pkl, l)
    end
    f:close()
    return pkl
end)(), {"./tools/genpktbl.sh"})

--add generator for making dirs
ruletable:addgenerator(function(name)
    if path:filename(name) ~= ".dir" then
        return nil
    end
    local r = {}
    local dn = path:dirname(name)
    function r:deps()
        --depend on parent dir, if there is one
        if string.match(dn, "/") then
            return { path:dirname(dn) .. "/.dir" }
        else
            --gah, figure out a better solution later
            return {".gitignore"}
        end
    end
    function r:run()
        return promise(function(s, f)
            runner:run("mkdir", "-p", dn):prom(function()
                runner:run("touch", name):prom(s, f)
            end, f)
        end)
    end
    return r
end)

--add generator for making source tars
ruletable:addgenerator(function(name)
    if path:filename(name) ~= "src.tar" then
        return nil
    end
    if path:dirname(path:dirname(name)) ~= "build" then
        return nil
    end
    local r = {}
    local pkgname = path:basename(path:dirname(name))
    function r:deps()
        return promise(function(s, f)
            ruletable:run("pkgens.list"):prom(function()
                if pktbl == nil then
                    loadpktbl()
                end
                local pkgen = pktbl[pkgname]
                if pkgen == nil then
                    f("Invalid src.tar dep")
                end
                r.pkgen = pkgen
                s({pkgen, "build/" .. pkgname .. "/.dir"})
            end, f)
        end)
    end
    function r:run()
        return runner:run("pkgen", "-i", r.pkgen, "-o", name, "src")
    end
    return r
end)

--add generator for making build dep lists
ruletable:addgenerator(function(name)
    if path:filename(name) ~= "builddeps.list" then
        return nil
    end
    if path:dirname(path:dirname(name)) ~= "build" then
        return nil
    end
    local r = {}
    local pkgname = path:basename(path:dirname(name))
    function r:deps()
        return promise(function(s, f)
            ruletable:run("pkgens.list"):prom(function()
                if pktbl == nil then
                    loadpktbl()
                end
                local pkgen = pktbl[pkgname]
                if pkgen == nil then
                    f("Invalid src.tar dep")
                end
                r.pkgen = pkgen
                s({pkgen, "build/" .. pkgname .. "/.dir"})
            end, f)
        end)
    end
    function r:run()
        return runner:run("pkgen", "-i", r.pkgen, "-o", name, "builddeps")
    end
    return r
end)

--add generator for build scripts
ruletable:addgenerator(function(name)
    local arch = string.match(path:filename(name), "build%-(.+)%.mk")
    if arch == nil then
        return nil
    end
    if path:dirname(path:dirname(name)) ~= "build" then
        return nil
    end
    local r = {}
    local pkgname = path:basename(path:dirname(name))
    function r:deps()
        return promise(function(s, f)
            ruletable:run("pkgens.list"):prom(function()
                if pktbl == nil then
                    loadpktbl()
                end
                local pkgen = pktbl[pkgname]
                if pkgen == nil then
                    f(string.format("Invalid build script dep %s", pkgname))
                end
                r.pkgen = pkgen
                s({pkgen, "build/" .. pkgname .. "/.dir"})
            end, f)
        end)
    end
    if arch == "bootstrap" then
        arch = os.getenv("HOSTARCH")
    end
    function r:run()
        return runner:run("pkgen", "-i", r.pkgen, "-o", name, "--build", arch, "build")
    end
    return r
end)

--add generator for Dockerfiles
ruletable:addgenerator(function(name)
    local fname = path:filename(name)
    if fname ~= "Dockerfile" and fname ~= "Dockerfile.bootstrap" then
        return nil
    end
    if path:dirname(path:dirname(name)) ~= "build" then
        return nil
    end
    local r = {}
    local pkgname = path:basename(path:dirname(name))
    function r:deps()
        if fname == "Dockerfile.bootstrap" then
            return {path:dirname(name) .. "/builddeps.list"}
        else
            return {path:dirname(name) .. "/rootfs.tar.gz"}
        end
    end
    function r:run()
        return promise(function(s, f)
            local base
            if fname == "Dockerfile.bootstrap" then
                base = "alpine"
            else
                base = "scratch"
            end
            local fromln = "FROM " .. base
            local instln
            if fname == "Dockerfile.bootstrap" then
                instln = "RUN apk --no-cache add make bash gcc libc-dev binutils"
                local l
                for l in io.lines(path:dirname(name) .. "/builddeps.list") do
                    if l ~= "" then
                        instln = instln .. " " .. l
                    end
                end
            else
                instln = "ADD rootfs.tar.gz /"
            end
            local df = fromln .. "\n" .. instln .. "\n"
            local f = assert(io.open(name, "w"))
            f:write(df)
            f:close()
            s()
        end)
    end
    return r
end)

local function isBootstrap(pkgf)
    local f = assert(io.popen(string.format("pkgen -i %s builder", pkgf)))
    local bldr = assert(f:read("*a"))
    f:close()
    return bldr == "bootstrap"
end

--add generator for rootfs tars
ruletable:addgenerator(function(name)
    local fname = path:filename(name)
    if fname ~= "rootfs.tar.gz" then
        return nil
    end
    if path:dirname(path:dirname(name)) ~= "build" then
        return nil
    end
    local r = {}
    local pkgname = path:basename(path:dirname(name))
    function r:deps()
        return promise(function(s, f)
            ruletable:run(path:dirname(name) .. "/builddeps.list"):prom(function()
                local bdlist = {}
                local dlist = {path:dirname(name) .. "/builddeps.list"}
                local a = os.getenv("HOSTARCH")
                --use the bootstrapped copy to build the new version
                if isBootstrap(pkgname) then
                    a = "bootstrap"
                end
                local l
                for l in io.lines(path:dirname(name) .. "/builddeps.list") do
                    if l ~= "" then
                        local tarball = "out/" .. a .. "/" .. l .. ".tar.gz"
                        table.insert(dlist, tarball)
                        table.insert(bdlist, tarball)
                    end
                end
                for _, l in ipairs({"make", "gcc", "musl-dev"}) do
                    local tarball = "out/" .. a .. "/" .. l .. ".tar.gz"
                    table.insert(dlist, tarball)
                    table.insert(bdlist, tarball)
                end
                self.tars = bdlist
                s(dlist)
            end, f)
        end)
    end
    function r:run()
        return runner:run("buildcontainer", name, unpack(self.tars))
    end
    return r
end)

--add generator for generating containers
ruletable:addgenerator(function(name)
    local fname = path:filename(name)
    if fname ~= ".container" and fname ~= ".container.bootstrap" then
        return nil
    end
    if path:dirname(path:dirname(name)) ~= "build" then
        return nil
    end
    local r = {}
    local pkgname = path:basename(path:dirname(name))
    function r:deps()
        if fname == ".container.bootstrap" then
            return {path:dirname(name) .. "/Dockerfile.bootstrap"}
        else
            return {path:dirname(name) .. "/rootfs.tar.gz", path:dirname(name) .. "/Dockerfile"}
        end
    end
    function r:run()
        local df
        local csuf = ""
        if fname == ".container.bootstrap" then
            df = path:dirname(name) .. "/Dockerfile.bootstrap"
            csuf = "-bootstrap"
        else
            df = path:dirname(name) .. "/Dockerfile"
        end
        return promise(function(s, f)
            runner:run("docker", "build", "-f", df, "-t", "panux/builder:" .. pkgname .. csuf, path:dirname(name)):prom(function()
                runner:run("touch", name):prom(s, f)
            end, f)
        end)
    end
    return r
end)

--add rule for building packages
ruletable:addgenerator(function(name)
    local pkgname = string.match(path:filename(name), "(.+)%.meta")
    if pkgname == nil then
        return nil
    end
    if path:dirname(path:dirname(name)) ~= "meta" then
        return nil
    end
    local arch = path:basename(path:dirname(name))
    local r = {}
    function r:deps()
        local deps = {
            "build/" .. pkgname .. "/build-" .. arch .. ".mk",
            "build/" .. pkgname .. "/src.tar",
            path:dirname(name) .. "/.dir",
        }
        if arch == "bootstrap" then
            table.insert(deps, "build/" .. pkgname .. "/.container.bootstrap")
        else
            table.insert(deps, "build/" .. pkgname .. "/.container")
        end
        return deps
    end
    function r:run()
        local csuf = ""
        if arch == "bootstrap" then
            csuf = "-bootstrap"
        end
        return runner:run("./tools/runbuild.sh", "panux/builder:"  .. pkgname .. csuf, arch, "build/" .. pkgname, name)
    end
    return r
end)

--add meta-rules for package files
ruletable:addgenerator(function(name)
    local pkgname = string.match(path:filename(name), "(.+)%.tar%.gz")
    if pkgname == nil then
        return nil
    end
    if path:dirname(path:dirname(name)) ~= "out" then
        return nil
    end
    local arch = path:basename(path:dirname(name))
    local r = {}
    function r:deps()
        return promise(function(s, f)
            ruletable:run("pkgens.list"):prom(function()
                if pktbl == nil then
                    loadpktbl()
                end
                local pkgen = pktbl[pkgname]
                if pkgen == nil then
                    error(string.format("Invalid package %s", pkgname))
                end
                local pkgn = path:basename(path:dirname(pkgen))
                s({"meta/" .. arch .. "/" .. pkgn .. ".meta"})
            end, f)
        end)
    end
    function r:run()
        return runner:run("touch", "-m", name)
    end
    return r
end)
