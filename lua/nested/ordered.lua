local nested_ordered = {}

local KEY_ORDER_KEY = '__key_order'

function nested_ordered.new()
    return setmetatable({
        [KEY_ORDER_KEY] = {},
    }, nested_ordered)
end

function nested_ordered.__newindex(t, index, value)
    local order = rawget(t, KEY_ORDER_KEY)
    order[#order + 1] = index
    rawset(t, index, value)
end

function nested_ordered.__pairs(t)
    local i = 0
    local keys = t[KEY_ORDER_KEY]
    return function()
        i = i + 1
        local idx = keys[i]
        return idx, t[idx]
    end
end

return nested_ordered