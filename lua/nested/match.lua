local nested = require 'nested'
local nested_keypath = require 'nested.keypath'

local NOT_PREFIX = '!'

local function truthy(v)
    return v ~= nil and v ~= false
end
local function xor(a, b)
    return truthy(a) ~= truthy(b)
end

local function match(t, pattern)
    local ktype, keypath, value_in_t
    for k, v in pairs(pattern) do
        ktype = type(k)
        if ktype == 'number' then
            local callable, result = pcall(v, t)
            if callable then
                if not result then return false end
            else
                local invert = v:sub(1, 1) == NOT_PREFIX
                if invert then v = v:sub(2) end
                keypath = nested_keypath.match(v)
                if not xor(invert, nested.get(t, keypath)) then return false end
            end
        else
            local invert = k:sub(1, 1) == NOT_PREFIX
            if invert then k = k:sub(2) end
            if ktype == 'string' then
                keypath = nested_keypath.match(k)
            else
                keypath = k
            end
            value_in_t = nested.get(t, keypath)
            if value_in_t == nil then
                if not invert then return false end
            else
                local callable, result = pcall(v, value_in_t)
                if callable then
                    if not xor(invert, result) then return false end
                elseif type(v) == 'table' then
                    if not xor(invert, match(value_in_t, v)) then return false end
                else
                    if not xor(invert, v == value_in_t) then return false end
                end
            end
        end
    end

    return true
end

return match