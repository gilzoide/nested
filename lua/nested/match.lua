local nested = require 'nested'
local nested_keypath = require 'nested.keypath'

local function match(t, pattern)
    local ktype, keypath, value_in_t
    for k, v in pairs(pattern) do
        ktype = type(k)
        if ktype == 'number' then
            keypath = nested_keypath.match(v)
            if not nested.get(t, keypath) then return false end
        else
            if ktype == 'string' then
                keypath = nested_keypath.match(k)
            else
                keypath = k
            end
            value_in_t = nested.get(t, keypath)
            if value_in_t == nil then return false end
            local callable, result = pcall(v, value_in_t)
            if callable then
                if not result then return false end
            elseif type(v) == 'table' then
                if not match(value_in_t, v) then return false end
            else
                if v ~= value_in_t then return false end
            end
        end
    end

    return true
end

return match