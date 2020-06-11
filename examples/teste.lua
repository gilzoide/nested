local nested = require 'nested'

local text = [[
Tank t
    x: 10 y: 20 z: 50
;

Tank-'t2'
    x: t.x y: t.y z: t.z

    [1 2 3]
    [3 2 1]
;

a; b; c
]]
local result = assert(nested.decode(text))
print(nested.encode(result, false))
--[[
-- regular
[Tank t x: 10 y: 20 z: 50] [Tank-'t2' [1 2 3] [3 2 1] x: t.x y: t.y z: t.z] [a] [b] [c]
-- compact
[Tank t z:50 x:10 y:20;Tank-'t2'[1 2 3;3 2 1]z:t.z x:t.x y:t.y;a;b;c]
--]]