local nested = require 'nested'

local function construct_with_line(opening, line)
    return {
        line = line,
    }
end

local t = assert(nested.decode([=[
[line1 'a' 'b']
[line2 'c d']
# line3
[line4]
# line5
# line6
[line7 [line7] [
    'this is line8' 'but table initiated at line7'
]]
[line10 "
line11
line12
" [line13] [line13 "
line14
line15
  " [line16]]]
]=], nil, construct_with_line))

print(nested.encode(t))