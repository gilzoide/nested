-- Ignore: blank ,\t\r
-- Always special: \n()[]:;
-- Special if first in token: '"`#
----------  Decoder  ----------
local TOKEN = {
    'SPACE', 'COMMENT', 'NEWLINE', 'EOF',
    'OPEN_BRACKETS', 'CLOSE_BRACKETS',
    'OPEN_PAREN', 'CLOSE_PAREN',
    'OPEN_BRACES', 'CLOSE_BRACES',
    'KEYVALUE', 'SIBLING_DELIMITER',
    -- 'QUOTES', 'TEXT' -- both return as strings rather than numeric codes
}
for i = 1, #TOKEN do TOKEN[TOKEN[i]] = i end

local TOKEN_BY_PREFIX = {
    [' '] = 'SPACE', [','] = 'SPACE', ['\t'] = 'SPACE', ['\r'] = 'SPACE',
    ['#'] = 'COMMENT',
    ['\n'] = 'NEWLINE',
    [''] = 'EOF',
    ['['] = 'OPEN_BRACKETS', [']'] = 'CLOSE_BRACKETS',
    ['('] = 'OPEN_PAREN', [')'] = 'CLOSE_PAREN',
    ['{'] = 'OPEN_BRACES', ['}'] = 'CLOSE_BRACES',
    [':'] = 'KEYVALUE',
    [';'] = 'SIBLING_DELIMITER',
    ["'"] = 'QUOTES', ['"'] = 'QUOTES', ['`'] = 'QUOTES',
}
local MATCHING_CLOSING_BLOCK = {
    [TOKEN.OPEN_BRACKETS] = TOKEN.CLOSE_BRACKETS,
    [TOKEN.OPEN_PAREN] = TOKEN.CLOSE_PAREN,
    [TOKEN.OPEN_BRACES] = TOKEN.CLOSE_BRACES,
}
-- Each function returns token, advance
-- Quotes error if not closed properly
local LEXICAL_SCANNERS = {
    SPACE = function(s)
        local pos = s:match('[ ,;\t\r]+()')
        return TOKEN.SPACE, pos
    end,
    COMMENT = function(s)
        local pos = s:match('#[^\n]+()')
        return TOKEN.COMMENT, pos
    end,
    NEWLINE = function(s) return TOKEN.NEWLINE, 2 end,
    EOF = function(s) return TOKEN.EOF, 0 end,
    OPEN_BRACKETS = function(s) return TOKEN.OPEN_BRACKETS, 2 end,
    CLOSE_BRACKETS = function(s) return TOKEN.CLOSE_BRACKETS, 2 end,
    OPEN_PAREN = function(s) return TOKEN.OPEN_PAREN, 2 end,
    CLOSE_PAREN = function(s) return TOKEN.CLOSE_PAREN, 2 end,
    OPEN_BRACES = function(s) return TOKEN.OPEN_BRACES, 2 end,
    CLOSE_BRACES = function(s) return TOKEN.CLOSE_BRACES, 2 end,
    KEYVALUE = function(s) return TOKEN.KEYVALUE, 2 end,
    SIBLING_DELIMITER = function(s) return TOKEN.SIBLING_DELIMITER, 2 end,
    QUOTES = function(s)
        local delimiter = s:match('[\'\"`]')
        local components = {}
        for m, pos in s:sub(2):gmatch('([^' .. delimiter .. ']*' .. delimiter .. '?)' .. delimiter .. '()') do -- ([^']*'?)'()
            components[#components + 1] = m
            if m:sub(-1) ~= delimiter then
                return table.concat(components), pos + 1, delimiter
            end
        end
        error(string.format('Unmatched closing %q', delimiter), 0)
    end,
    TEXT = function(s)
        return s:match('([^ ,\t\r\n%[%](){}:;]+)()')
    end,
}

local function peek_token_type_name(s)
    local prefix = s:sub(1, 1)
    return TOKEN_BY_PREFIX[prefix] or 'TEXT'
end

local function read_next_token(s)
    local rule = peek_token_type_name(s)
    return LEXICAL_SCANNERS[rule](s)
end

local function token_description(t)
    -- TODO: more user friendly token description
    return type(t) == 'number' and TOKEN[t] or t
end

local function read_block(state, s, expected_closing)
    local table_constructor = state.table_constructor
    local block = table_constructor()
    local initial_length = #s
    local toplevel, key, token, previous_token, advance, quotation_mark
    repeat
        previous_token = token
        token, advance, quotation_mark = read_next_token(s)
        if type(token) == 'string' then
            if key or peek_token_type_name(s:sub(advance)) ~= 'KEYVALUE' then
                local value = state.text_filter and state.text_filter(token, quotation_mark)
                if value == nil then value = token end
                block[key or #block + 1], key = value, nil
            else
                key = token
            end
        elseif token == TOKEN.NEWLINE then
            state.line = state.line + 1
            state.column = 0 -- after advance, column will be 1
        elseif token ~= expected_closing and (token == TOKEN.EOF or token == TOKEN.CLOSE_BRACKETS or token == TOKEN.CLOSE_PAREN or token == TOKEN.CLOSE_BRACES) then
            error(string.format('Expected closing block with %s, but found %s', token_description(expected_closing), token_description(token)), 0)
        elseif token == TOKEN.OPEN_BRACKETS or token == TOKEN.OPEN_PAREN or token == TOKEN.OPEN_BRACES then
            local child_block, read_length = read_block(state, s:sub(advance), MATCHING_CLOSING_BLOCK[token])
            block[key or #block + 1], key = child_block, nil
            advance = advance + read_length
        elseif token == TOKEN.KEYVALUE then
            if type(previous_token) ~= 'string' then
                error(string.format('Key-value mapping must appear right after text, found %s instead', token_description(previous_token)), 0)
            end
        elseif token == TOKEN.SIBLING_DELIMITER then
            if toplevel == nil then
                toplevel = table_constructor()
                toplevel[1] = block
            end
            block = table_constructor()
            toplevel[#toplevel + 1] = block
        else
             -- TODO: after thorough testing, remove unecessary assertion
            assert(token == expected_closing or token == TOKEN.SPACE or token == TOKEN.COMMENT, 'FIXME!!!')
        end
        s = s:sub(advance)
        state.column = state.column + advance - 1
    until token == expected_closing
    return toplevel or block, initial_length - #s
end

--- TODO: support streamed IO
local function decode(s, text_filter, table_constructor)
    table_constructor = table_constructor or function() return {} end
    local state = { line = 1, column = 1, text_filter = text_filter, table_constructor = table_constructor }
    local success, result = pcall(read_block, state, s, TOKEN.EOF)
    if not success then return nil, string.format('Error at line %u (col %u): %s', state.line, state.column, result)
    else return result 
    end
end

local function decode_file(stream, ...)
    local previous = io.input()
    stream = io.input(stream)
    local contents = stream:read('*a')
    stream:close()
    io.input(previous)
    return decode(contents, ...)
end

----------  Metadata iterator  ----------
local function metadata(t)
    return coroutine.wrap(function()
        for k, v in pairs(t) do
            if type(k) ~= 'number' then coroutine.yield(k, v) end
        end
    end)
end

----------  Iterators  ----------
local ORDER = 'order'
local PREORDER = 'preorder'
local POSTORDER = 'postorder'
local TABLE_ONLY = 'table_only'
local INCLUDE_KV = 'include_kv'
local function iterate_step(keypath, t, parent, options)
    local is_table = type(t) == 'table'
    if options[TABLE_ONLY] and not is_table then return end
    local is_postorder = options[ORDER] == POSTORDER
    if not is_postorder then coroutine.yield(keypath, t, parent) end
    if is_table then
        local keypath_index = #keypath + 1
        for i = 1, #t do
            keypath[keypath_index] = i
            iterate_step(keypath, t[i], t, options)
        end
        if options[INCLUDE_KV] then
            for k, v in metadata(t) do
                keypath[keypath_index] = k
                iterate_step(keypath, v, t, options)
            end
        end
        keypath[keypath_index] = nil
    end
    if is_postorder then coroutine.yield(keypath, t, parent) end
end
local function iterate(t, options)
    options = options or {}
    return coroutine.wrap(function() iterate_step({}, t, nil, options) end)
end

----------  Encoder  ----------
local function encode_into(state, t)
    local function append(v) state[#state + 1] = v end
    if type(t) == 'table' then
        local keypath = state.keypath
        assert(state[t] == nil, string.format("Cycle detected at keypath %q", table.concat(keypath, ' ')))
        state[t] = true
        local compact = state.compact
        if compact and state[#state] == ' ' then state[#state] = nil end
        if state[#state] == ']' then
            state[#state] = ';'
        else
            append('[')
        end
        for i, v in ipairs(t) do
            keypath[#keypath + 1] = i
            encode_into(state, v)
            if not compact or state[#state] ~= ']' then append(' ') end
            keypath[#keypath] = nil
        end
        for k, v in metadata(t) do
            -- TODO: error if k is table
            keypath[#keypath + 1] = k
            encode_into(state, k)
            append(':')
            if not compact then append(' ') end
            encode_into(state, v)
            append(' ')
            keypath[#keypath] = nil
        end
        if state[#state] == ' ' then state[#state] = nil end
        append(']')
    else
        local encoded_value = tostring(t)
        if encoded_value:match('[ ,\t\r\n%[%]():;]') or encoded_value:match('^[\'\"`#]') then
            -- TODO: if compact, find out the quotation mark that requires less escaping
            encoded_value = '"' .. encoded_value:gsub('"', '""') .. '"'
        end
        append(encoded_value)
    end
end

local function encode(t, compact)
    local state = { compact = compact, keypath = {} }
    local success, err = pcall(encode_into, state, t)
    if not success then
        return nil, err
    else
        local i = compact and 2 or nil
        local j = compact and #state - 1 or nil
        return table.concat(state, '', i, j)
    end
end

local function encode_to_file(stream, ...)
    local encoded_value, err = encode(...)
    if not encoded_value then return nil, err end
    local previous = io.output()
    stream = io.output(stream)
    stream:write(encoded_value)
    stream:close()
    return true
end

----------  Keypaths  ----------
local function get_internal(t, create_subtables, keypath, ...)
    if type(keypath) ~= 'table' then keypath = { keypath, ...} end
    for i = 1, #keypath do
        local key = keypath[i]
        local ttype = type(t)
        if ttype ~= 'table' then
            keypath[i] = nil
            local keypath_with_error = encode(keypath)
            keypath[i] = key
            return nil, string.format("Cannot index %s at keypath %s", ttype, keypath_with_error)
        end
        
        local subtable = t[key]
        if subtable == nil and create_subtables then
            subtable = {}
            t[key] = subtable
        end
        t = subtable
    end
    return t
end
local function get(t, ...)
    return get_internal(t, false, ...)
end
local function get_or_create(t, ...)
    return get_internal(t, true, ...)
end

local function set_internal(t, create_subtables, keypath, ...)
    local value
    if type(keypath) ~= 'table' then
        keypath = { keypath, ...}
        value = table.remove(keypath)
    else
        value = ...
    end
    local subtable, key = t, nil
    for i = 1, #keypath - 1 do
        key = keypath[i]
        local next_subtable = subtable[key]
        if next_subtable == nil and create_subtables then
            next_subtable = {}
            subtable[key] = next_subtable
        end
        local ttype = type(next_subtable)
        if ttype ~= 'table' then
            key, keypath[i + 1] = keypath[i + 1], nil
            local keypath_with_error = encode(keypath)
            keypath[i + 1] = key
            return nil, string.format("Cannot index %s at keypath %s", ttype, keypath_with_error)
        end
        subtable = next_subtable
    end
    key = keypath[#keypath]
    subtable[key] = value
    return t
end
local function set(t, ...)
    return set_internal(t, false, ...)
end
local function set_or_create(t, ...)
    return set_internal(t, true, ...)
end

----------  Filter  ----------
local function bool_number_filter(s, quoted)
    if quoted then return nil
    elseif s == 'true' then return true
    elseif s == 'false' then return false
    else return tonumber(s)
    end
end

----------  Module  ----------
return {
    decode = decode,
    decode_file = decode_file,
    encode = encode,
    encode_to_file = encode_to_file,
    metadata = metadata,
    bool_number_filter = bool_number_filter,
    get = get,
    get_or_create = get_or_create,
    set = set,
    set_or_create = set_or_create,
    iterate = iterate,
    ORDER = ORDER,
    PREORDER = PREORDER,
    POSTORDER = POSTORDER,
    TABLE_ONLY = TABLE_ONLY,
    INCLUDE_KV = INCLUDE_KV,
}

-- TODO: document stuff