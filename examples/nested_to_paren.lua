local filename = arg[1]
if not filename then
    print(string.format("Usage: %s <input>", arg[0]))
    os.exit(-1)
end

local contents
do
    local input_file = assert(io.open(filename))
    contents = assert(input_file:read('a'))
end


local Nested = require 'nested'
local parsed = assert(Nested.parse(contents))

local iowrite = io.write

local function print_node(t, level)
    level = level or 0
    if type(t) == 'string' then
        if string.match(t, '[][%s,():#]') then
            iowrite(string.format('%q', t))
        else
            iowrite(t)
        end
    else
        iowrite('(')
        for k, v in Nested.pairs(t) do
            print_node(k)
            iowrite(':')
            print_node(v)
            iowrite(' ')
        end
        for i, v in ipairs(t) do
            print_node(v)
            if i < #t then iowrite(' ') end
        end
        iowrite(')')
    end
end
print_node(parsed)