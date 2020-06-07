local nested = require 'nested'

local COMMAND = nested.command
local SERIALIZED_COMMAND = nested.serialized_command
local SPECIAL_CHARACTER_PATTERN = nested.special_character_pattern
local QUOTE_CHARACTER = nested.quote_character
local QUOTE_CHARACTER_ESCAPE = nested.quote_character_escape

local function quote(s)
    if s:sub(1, 1) == nested or s:match(SPECIAL_CHARACTER_PATTERN) then
        s = QUOTE_CHARACTER .. s:gsub(QUOTE_CHARACTER, QUOTE_CHARACTER_ESCAPE) .. QUOTE_CHARACTER
    end
    return s
end

local function compile_parsed(t)
    local parts = {}
    local last_text = false
    for i, v in ipairs(t) do
        local cmd = SERIALIZED_COMMAND[v]
        if cmd then
            table.insert(parts, cmd)
            last_text = false
        else
            if last_text then
                table.insert(parts, SERIALIZED_COMMAND[COMMAND.SiblingText])
            end
            table.insert(parts, quote(v))
            last_text = true
        end
    end
    return table.concat(parts)
end

return compile_parsed