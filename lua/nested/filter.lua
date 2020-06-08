local filter = {}

function filter.parse_bool(s)
    if s == 'true' then
        return true
    elseif s == 'false' then
        return false
    else
        return nil
    end
end

filter.parse_number = tonumber

-- Lua 5.1 and 5.2+ compatibility
local loadstring = loadstring or load

--- @warning Loading arbitrary code from untrusted sources is a major security flaw!!!
function filter.loadlua(s)
    local chunk = loadstring('return ' .. s)
    if chunk then
        local success, value = pcall(chunk)
        return success and value or nil
    else
        return nil
    end
end

--- Filter utilities
function filter.try_filters(s, filters)
    local result
    for i = 1, #filters do
        result = filters[i](s)
        if result ~= nil then return result end
    end
    return s
end

return filter