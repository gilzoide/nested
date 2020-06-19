local nested = require 'nested'
local nested_keypath = require 'nested.keypath'

local NOT_PREFIX = '!'

local function truthy(v)
    return v ~= nil and v ~= false
end
local function xor(a, b)
    return truthy(a) ~= truthy(b)
end

local function keypath_invert(v)
    if type(v) == 'string' then
        local invert = v:sub(1, 1) == NOT_PREFIX
        if invert then v = v:sub(2) end
        return nested_keypath.match(v), invert
    else
        return v, false
    end 
end

local function match(t, pattern)
    local call_success, invert, ktype, keypath, result, value_in_t
    for k, v in pairs(pattern) do
        ktype = type(k)
        if ktype == 'number' then
            call_success, result = pcall(v, t)
            if not call_success then
                keypath, invert = keypath_invert(v)
                result = xor(invert, nested.get(t, keypath))
            end
        else
            keypath, invert = keypath_invert(k)
            value_in_t = nested.get(t, keypath)
            if value_in_t == nil then
                result = false
            else
                call_success, result = pcall(v, value_in_t)
                if not call_success then
                    if type(v) == 'table' then
                        result = match(value_in_t, v)
                    else
                        result = v == value_in_t
                    end
                end
            end
            result = xor(invert, result)
        end
        if not result then return false end
    end

    return true
end

return match