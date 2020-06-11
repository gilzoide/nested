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
-- print(require 'inspect'(result))