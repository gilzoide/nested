local nested = require 'nested'

local function construct_with_line(opening, line)
    return {
        line = line,
    }
end

local t = assert(nested.decode([=[
[line1]
[line2]
# line3
[line4]
# line5
# line6
[line7 [line7] [
    'this is line8' 'but table initiated at line7'
]]
]=], nil, construct_with_line))

print(nested.encode(t))