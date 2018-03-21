local path = require("lbuild.path")
local promise = require("lbuild.promise")
local runner = require("lbuild.runner")
local ffi = require("ffi")
local pktbl = nil

--function to set environment vars
ffi.cdef[[
int setenv(const char *name, const char *value, int overwrite);
char *strerror(int errnum);
int execvp(const char*path, const char*const argv[]);
]]
os.setenv = function(name, value)
    local code = ffi.C.setenv(name, value, 1)
    if code == -1 then
        error(ffi.C.strerror(ffi.errno()))
    end
end

--containerize if necessary
if os.getenv("NOCONTAINER") ~= "true" then
    --re-exec
    arg[0] = "./tools/containerize.sh"
    --move all elements in arg over
    local i = #arg
    while i ~= -1 do
        arg[i + 1] = arg[i]
        i = i - 1
    end
    arg[0] = nil
    i = #arg
    arg = ffi.new("const char*[?]", #arg+1, arg)
    arg[i] = nil
    ffi.C.execvp(arg[0], arg)
    error(ffi.string(ffi.C.strerror(ffi.errno())))
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

local ltbl
local function genltbl()
    if ltbl ~= nil then
        return
    end
    ltbl = {}
    local f = assert(io.popen("find pkgs -name pkgen.yaml"))
    local l
    for l in f:lines() do
        if l ~= "" then
            local pkgn = path:basename(path:dirname(l))
            ltbl[pkgn] = l
        end
    end
end

--generator for list files
ruletable:addgenerator(function(name)
    if path:getext(name) == ".list" then
        --it is something else
        if path:dirname(name) ~= "lists" then
            return nil
        end
        genltbl()
        local d = ltbl[path:basename(name)]
        if not d then
            return nil
        end
        local rule = {}
        rule.name = name
        rule.deps = function()
            return {d, "tools/genpklist.lua"}
        end
        function rule:run()
            return runner:run("luajit", "tools/genpklist.lua", d, name)
        end
        return rule
    end
    return nil
end)

local pkgll = (function()
    genltbl()
    local pkl = {}
    local v
    for v in pairs(ltbl) do
        table.insert(pkl, string.format("lists/%s.list", v))
    end
    return pkl
end)()

--add rule for pkgens.list file
local pkgrule = {name = "pkgens.list"}
function pkgrule:deps()
    local d = {"build.lua"}
    local v
    for _, v in ipairs(pkgll) do
        table.insert(d, v)
    end
    return d
end
function pkgrule:run()
    return promise(function(s, f)
        local m = {}
        local fn
        for _, fn in ipairs(pkgll) do
            local l
            for l in io.lines(fn) do
                table.insert(m, l)
            end
        end
        local f = assert(io.open("pkgens.list", "w"))
        local v
        for _, v in ipairs(m) do
            f:write(v .. "\n")
        end
        f:close()
        s()
    end)
end
add(pkgrule)

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
                    f(string.format("Invalid builddep list %s", name))
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
                base = "alpine:3.7"
            else
                base = "scratch"
            end
            local fromln = "FROM " .. base
            local instln
            if fname == "Dockerfile.bootstrap" then
                instln = "RUN apk --no-cache add make bash gcc libc-dev binutils ccache"
                local l
                for l in io.lines(path:dirname(name) .. "/builddeps.list") do
                    if l ~= "" then
                        instln = instln .. " " .. l
                    end
                end
            else
                instln = "ADD rootfs.tar.gz /"
            end
            local df = fromln .. "\n" .. instln .. "\n" .. "ENV PATH=\"/usr/lib/ccache/bin:${PATH}\"\nENV CCACHE_DIR=/ccache\n"
            local f = assert(io.open(name, "w"))
            f:write(df)
            f:close()
            s()
        end)
    end
    return r
end)

--add generator for isBootstrap files
ruletable:addgenerator(function(name)
    if path:filename(name) ~= ".isBootstrap" then
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
                    f(string.format("Invalid isBootstrap %s", pkgname))
                end
                r.pkgen = pkgen
                s({pkgen, "build/" .. pkgname .. "/.dir"})
            end, f)
        end)
    end
    function r:run()
        return runner:run("pkgen", "-i", r.pkgen, "-o", name, "builder")
    end
    return r
end)

local function isBootstrap(pkgf)
    local ibf = "build/" .. path:filename(path:dirname(pkgf)) .. "/.isBootstrap"
    return promise(function(s, f)
        ruletable:run(ibf):prom(function()
            local f = assert(io.open(ibf, "r"))
            local bldr = assert(f:read("*a"))
            f:close()
            s(bldr == "bootstrap")
        end)
    end)
end


local function resolvedeps(name, tbl)
    if tbl == nil then
        return promise(function(s, f)
            local t = {}
            resolvedeps(name, t):prom(function()
                s(t)
            end, f)
        end)
    end
    if pktbl == nil then
        return promise(function(s, f)
            ruletable:run("pkgens.list"):prom(function()
                if pktbl ~= nil then loadpktbl() end
                resolvedeps(name, tbl):prom(s, f)
            end, f)
        end)
    end
    local pkgen = pktbl[name]
    if pkgen == nil then
        error(string.format("Package %s not found", name))
    end
    local depf = "build/" .. path:basename(path:dirname(pkgen)) .. "/deplists/" .. name .. ".list"
    return promise(function(s, f)
        if tbl[name] ~= nil then
            s(tbl)
            return
        end
        tbl[name] = true
        table.insert(tbl, name)
        ruletable:run(depf):prom(function()
            local n = 1
            local function cb()
                n = n - 1
                if n == 0 then
                    s(tbl)
                end
            end
            local l
            for l in io.lines(depf) do
                if l ~= "" then
                    n = n + 1
                    resolvedeps(l, tbl):prom(cb)
                end
            end
            cb()
        end, f)
    end)
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
                local a = os.getenv("HOSTARCH")
                --resolve deps and convert to dep files
                local bdli = {"make", "gcc", "musl-dev", "base"}
		if pkgname ~= "ccache" then
			table.insert(bdli, "ccache")
		end
                local l
                for l in io.lines(path:dirname(name) .. "/builddeps.list") do
                    if l ~= "" then
                        table.insert(bdli, l)
                    end
                end
                local n = 1
                local bdl = {}
                local function meh()
                    n = n - 1
                    if n == 0 then
                        local deptable = {path:dirname(name) .. "/builddeps.list"}
                        local tars = {}
                        local v
                        local n2 = #bdl + 1
                        local function p()
                            n2 = n2 - 1
                            if n2 == 0 then
                                r.tars = tars
                                s(deptable)
                            end
                        end
                        for _, v in ipairs(bdl) do
                            local ar = a
                            --use the bootstrapped copy to build the new version
                            isBootstrap(pktbl[v]):prom(function(ib)
                                if ib then
                                    ar = "bootstrap"
                                end
                                local tar = "out/" .. ar .. "/" .. v .. ".tar.gz"
                                table.insert(deptable, tar)
                                table.insert(tars, tar)
                                p()
                            end)
                        end
                        p()
                    end
                end
                for _, l in ipairs(bdli) do
                    n = n + 1
                    table.insert(bdl, l)
                    resolvedeps(l):prom(function(dd)
                        local v
                        for _, v in ipairs(dd) do
                            table.insert(bdl, v)
                        end
                        meh()
                    end)
                end
                meh()
            end, f)
        end)
    end
    function r:run()
	--dedup tars
	local tt = {}
	local tdt = {}
	for i, v in ipairs(self.tars) do
		if not tdt[v] then
			tdt[v] = true
			table.insert(tt, v)
		end
	end
        return runner:run("buildcontainer", name, unpack(tt))
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
        --just update file access times
        return runner:run("touch", "-m", name)
    end
    return r
end)

--add generator for dependency list rules
ruletable:addgenerator(function(name)
    local pkgname = string.match(path:filename(name), "(.+)%.list")
    if pkgname == nil then
        return nil
    end
    if path:basename(path:dirname(name)) ~= "deplists" then
        return nil
    end
    if path:dirname(path:dirname(path:dirname(name))) ~= "build" then
        return nil
    end
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
                s({pkgen, path:dirname(name) .. "/.dir"})
            end, f)
        end)
    end
    function r:run()
        return runner:run("pkgen", "-i", r.deplst[1], "-o", name, "deps", "-p", pkgname, "-n")
    end
    return r
end)

--add rule for all
local allrule = {name = "all"}
function allrule:deps()
    genltbl()
    local d = {}
    local v
    for v in pairs(ltbl) do
        table.insert(d, string.format("meta/%s/%s.meta", os.getenv("HOSTARCH"), v))
    end
    return d
end
function allrule:run()
    return promise(function(s, f)
        s()
    end)
end
add(allrule)
