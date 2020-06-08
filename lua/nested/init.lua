local utils = require 'nested.utils'

local nested = {}

local command = {
    SiblingText = 1,
    SiblingNode = 2,
    OpenNested = 3,
    CloseNested = 4,
    KeyValue = 5,
}
nested.command = command
nested.serialized_command = {
    [command.SiblingText] = ',',
    [command.SiblingNode] = ';',
    [command.OpenNested]  = '[',
    [command.CloseNested] = ']',
    [command.KeyValue]    = ':',
}

nested.special_character_pattern = '[,;:%[%]]'
nested.quote_character = '`'
nested.quote_character_escape = '``'

local read_atom, read_table
read_atom = function(s)
    local first = s:sub(1, 1)
    if first == '[' then
        return read_table(s:sub(2))
    elseif first == nested.quote_character then
        -- TODO: handle double-quotes
        local atom, pos = s:sub(2):match('(.-)' .. nested.quote_character .. '()')
        return atom, s:sub(pos + 1)
    else
        local pos = s:match('()' .. nested.special_character_pattern) or #s + 1
        return s:sub(1, pos - 1), s:sub(pos)
    end
end
read_table = function(s)
    local toplevel = nil
    local current = {}
    local atom, first, key
    repeat
        atom, s = read_atom(s)
        first, s = s:sub(1, 1), s:sub(2)
        if first == '' or first == ',' or first == ';' or first == ']' then
            current[key or #current + 1] = atom
            key = nil
        elseif first == ':' then
            key = atom
        end
        if first == ';' then
            if not toplevel then
                toplevel = { current }
            end
            current = {}
            table.insert(toplevel, current)
        end
    until first == '' or first == ']'
    return toplevel or current, s
end

function nested.build(compiled)
    assert(type(compiled) == 'string', "String expected, found " .. type(compiled))
    local t = read_table(compiled)
    return t
end

function nested.loadfile(filename)
    local contents, err, code = utils.readfile(filename)
    if not contents then return nil, err, code end
    return nested.build(contents)
end

return nested