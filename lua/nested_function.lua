local nested = require 'nested'
local unpack = unpack or table.unpack

local nested_function = {}
nested_function.__index = nested_function

local ORDERED_KEY = '__nested_function_order'
local ESCAPE_CHAR = '!'
local KEYPATH_PATTERN = '%.'

function nested_function.new()
    return setmetatable({
        [ORDERED_KEY] = {}
    }, nested_function)
end

function nested_function.__newindex(t, index, value)
    local order = rawget(t, ORDERED_KEY)
    order[#order + 1] = index
    rawset(t, index, value)
end

local function read_keypath(s)
    local result = {}
    while true do
        local pattern_first, pattern_last = s:find(KEYPATH_PATTERN)
        if not pattern_first then break end
        local key = s:sub(1, pattern_first - 1)
        result[#result + 1] = tonumber(key) or key
        s = s:sub(pattern_last + 1)
    end
    result[#result + 1] = tonumber(s) or s
    return result
end

local function iterate_nested_function(t)
    local i = 0
    local keys = t[ORDERED_KEY]
    return function()
        i = i + 1
        local idx = keys[i]
        return idx, t[idx]
    end
end

local function iterate_table(t)
    if t[ORDERED_KEY] then
        return iterate_nested_function(t)
    else
        return pairs(t)
    end
end

local loadstring_with_env
if setfenv and loadstring then
    loadstring_with_env = function(body, env)
        local chunk, err = loadstring(body)
        if not chunk then return nil, err end
        return setfenv(chunk, env)
    end
else
    loadstring_with_env = function(body, env)
        return load(body, nil, 't', env)
    end
end

local function evaluate_step(t, env)
    if type(t) == 'table' then
        env = setmetatable({}, { __index = env })
        if t[1] == 'function' then
            local arguments, body = t[2], t[3]
            if not body then body, arguments = arguments, nil end
            return function(...)
                if arguments then
                    for i = 1, #arguments do
                        env[arguments[i]] = select(i, ...)
                    end
                end
                if type(body) == 'string' then
                    local chunk, err = loadstring_with_env(body, env)
                    if not chunk then return nil, err end
                    return chunk()
                else
                    return evaluate_step(body, env)
                end
            end
        else
            local have_hash = false
            for k, v in iterate_table(t) do
                local key_not_numeric = type(k) ~= 'number'
                have_hash = have_hash or key_not_numeric
                v = evaluate_step(v, env)
                if key_not_numeric then
                    if nested.set_or_create(env, read_keypath(k), v) == nil then
                        env[k] = v
                    end
                else
                    env[k] = v
                end
            end
            if type(env[1]) == 'function' then
                local f = table.remove(env, 1)
                if have_hash then
                    return f(env)
                else
                    return f(unpack(env))
                end
            else
                return env
            end
        end
    elseif type(t) == 'string' then
        if t:sub(1, 1) == ESCAPE_CHAR then
            return t:sub(2)
        else
            return nested.get(env, read_keypath(t)) or t
        end
    else
        return t
    end
end

function nested_function.evaluate(t, ...)
    local env = setmetatable({
        self = t,
        arg = {...}
    }, { __index = _ENV or getfenv() })
    return evaluate_step(t, env)
end
nested_function.__call = nested_function.evaluate

return nested_function