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

function nested.build(compiled)
    assert(type(compiled) == 'string', "String expected, found " .. type(compiled))
    
    local pos = 1
    local s = compiled
    while #s > 0 do
        local first = s:sub(1, 1)

    end
end

function nested.loadfile(filename)
    local f, err, code = io.open(filename)
    if not f then return nil, err, code end
    local contents = f:read('*a')
    f:close()
    return nested.build(contents)
end

return nested