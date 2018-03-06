#!/bin/luajit

local path = require("lbuild.path")

local fname = arg[1]
local pkl = {string.format("%s=%s\n", path:basename(path:dirname(fname)), fname)}

local f = assert(io.popen(string.format("pkgen -i %s pkgs", fname)))
local v, l
for l in f:lines() do
    if l ~= "" then
        table.insert(pkl, string.format("%s=%s\n", l, fname))
    end
end
f:close()

f = assert(io.open(arg[2], "w"))
for _, v in ipairs(pkl) do
    f:write(v)
end
f:close()
