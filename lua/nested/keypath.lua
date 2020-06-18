local nested_keypath = {}

nested_keypath.escape_sequence = '\\'
nested_keypath.keypath_pattern = '%.'

function nested_keypath.match(s, keypath_pattern, escape_sequence)
    escape_sequence = escape_sequence or nested_keypath.escape_sequence
    local escape_length = #escape_sequence
    if s:sub(1, escape_length) == escape_sequence then
        return { s:sub(escape_length + 1) }
    end
    keypath_pattern = keypath_pattern or nested_keypath.keypath_pattern
    local result = {}
    while true do
        local pattern_first, pattern_last = s:find(keypath_pattern)
        if not pattern_first then break end
        local key = s:sub(1, pattern_first - 1)
        result[#result + 1] = tonumber(key) or key
        s = s:sub(pattern_last + 1)
    end
    result[#result + 1] = tonumber(s) or s
    return result
end

return nested_keypath