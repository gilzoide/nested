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
                return evaluate_step(body, env)
            end
        else
            local have_hash = false
            for k, v in iterate_table(t) do
                have_hash = have_hash or type(k) ~= 'number'
                env[k] = evaluate_step(v, env)
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
        arg = {...}
    }, { __index = _ENV or getfenv() })
    return evaluate_step(t, env)
end
nested_function.__call = nested_function.evaluate

return nested_function