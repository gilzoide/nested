local constructor = {}

local command = {
    SiblingText = 1,
    SiblingNode = 2,
    OpenNested = 3,
    CloseNested = 4,
    KeyValue = 5,
}
local serialized_command = {
    [command.SiblingText] = ',',
    [command.SiblingNode] = ';',
    [command.OpenNested]  = '[',
    [command.CloseNested] = ']',
    [command.KeyValue]    = ':',
}

constructor.command = command

local function quote(s)
    if s:sub(1, 1) == '`' or s:match('[,;:%[%]]') then
        s = "`" .. s:gsub('`', '``') .. "`"
    end
    return s
end

function constructor.serialize(t)
    local parts = {}
    local last_text = false
    for i, v in ipairs(t) do
        local cmd = serialized_command[v]
        if cmd then
            table.insert(parts, cmd)
            last_text = false
        else
            if last_text then
                table.insert(parts, serialized_command[command.SiblingText])
            end
            table.insert(parts, quote(v))
            last_text = true
        end
    end
    return table.concat(parts)
end

return constructor