local nested = require 'nested'

local t = assert(nested.decode[[
1 2 3
[skip this one]
[but don't skip this one]
]])

local iterator = nested.iterate(t, { skip_root = true })
local skip
while true do
    local kp, v = iterator(skip)
    if not kp then break end
    print(nested.encode(kp), nested.encode(v))
    skip = type(v) == 'table' and v[1] == 'skip'
end
    