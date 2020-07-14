local nested = require 'nested'
local nested_keypath = require 'nested.keypath'
local unpack = unpack or table.unpack

local nested_function = {}

nested_function.escape_char = '\\'
nested_function.keypath_pattern = '%.'

local function read_keypath(s)
    return nested_keypath.match(s, nested_function.keypath_pattern, nested_function.escape_char)
end

local function iscallable(v)
    if type(v) == 'function' then
        return true
    else
        local mt = getmetatable(v)
        return mt and mt.__call
    end
end

local function evaluate_step(t, read_env, ...)
    if type(t) == 'table' then
        local env = setmetatable({}, { __index = read_env })
        if select('#', ...) > 0 then env.arg = { ... } end
        local have_hash = false
        for k, v in pairs(t) do
            local key_not_numeric = type(k) ~= 'number'
            have_hash = have_hash or key_not_numeric
            v = evaluate_step(v, env)
            if key_not_numeric then
                if nested.set(env, read_keypath(k), v) == nil then
                    env[k] = v
                end
            else
                env[k] = v
            end
        end
        if iscallable(env[1]) then
            local f = table.remove(env, 1)
            if have_hash then
                return f(env)
            else
                return f(unpack(env))
            end
        else
            return env
        end
    elseif type(t) == 'string' then
        local escape_length = #nested_function.escape_char
        if t:sub(1, escape_length) == nested_function.escape_char then
            return t:sub(escape_length + 1)
        else
            return nested.get(read_env, read_keypath(t)) or t
        end
    else
        return t
    end
end

function nested_function.evaluate_with_env(t, read_env, ...)
    return evaluate_step(t, read_env, ...)
end

function nested_function.evaluate(t, ...)
    return evaluate_step(t, _ENV or getfenv(), ...)
end

return nested_function