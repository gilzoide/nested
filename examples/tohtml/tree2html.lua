local GenericDataTree = require 'genericdatatree'

local text = assert(io.open 'index.html.gdt'):read('a')
local tree = assert(GenericDataTree.parse(text))

local self_closing = {
    area = true,
    base = true,
    br = true,
    col = true,
    embed = true,
    hr = true,
    img = true,
    input = true,
    link = true,
    meta = true,
    param = true,
    source = true,
    track = true,
    wbr = true,
}

local write = io.write
local function indent(level)
    for i = 1, level do
        write('  ')
    end
end
function print_tag(t, level)
    level = level or 0
    if type(t[1]) == 'table' then
        for i, n in ipairs(t) do
            print_tag(t[i], level)
        end
        return
    end

    local tag = t[1]
    indent(level)
    if type(tag) == 'table' then print("DEBUG", tag[1]) end
    write('<', tag)
    for k, v in GenericDataTree.pairs(t) do
        write(' ', k)
        if v ~= 'true' then write('="', v, '"') end
    end
    if tag == '!DOCTYPE' or tag == '!doctype' then
        write('>\n')
    elseif self_closing[tag] then 
        write(' />\n')
    else
        write('>\n')
        for i = 2, #t do
            local node = t[i]
            if type(node) == 'table' then
                print_tag(node, level + 1)
            else
                indent(level + 1)
                write(node:match('^%s*(.-)%s*$'), '\n')
            end
        end
        if #t >= 2 then indent(level) end
        write('</', tag, '>\n')
    end
end

print_tag(tree)
