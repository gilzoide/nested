local nested = require 'nested'

local text = [[
[Tank t
    x: '10' y: 20 z: `50`
]

[Tank-'t2'
    x: t.x y: t.y z: t.z

    [1 2 3]
    [3 2 1]
]

[a][b][c(d){[e][f]}]
]]
local result = assert(nested.decode(text, { text_filter = nested.bool_number_filter, table_constructor = function(opening)
    print('Opening', opening)
    return {}
end }))
print(string.format("%q %q %q", result[1].x, result[1].y, result[1].z))
print(nested.encode(result))
