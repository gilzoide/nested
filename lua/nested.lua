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
                return table.concat(components), pos + 1
            end
        end
        error(string.format('Unmatched closing %q', delimiter), 0)
    end,
    TEXT = function(s)
        return s:match('([^ ,\t\r\n%[%]():;]+)()')
    end,
}

local OPTION_ORDERED = 'ordered'
local SAVED_KEY_ORDER_KEY = '__nested_keys'

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
    local block = {}
    local initial_length = #s
    local toplevel, key, token, previous_token, advance
    repeat
        previous_token = token
        token, advance = read_next_token(s)
        if type(token) == 'string' then
            if key or peek_token_type_name(s:sub(advance)) ~= 'KEYVALUE' then
                local value = state.text_filter and state.text_filter(token)
                if value == nil then value = token end
                block[key or #block + 1], key = value, nil
            else
                key = token
                if state[OPTION_ORDERED] then
                    local saved_key_order = block[SAVED_KEY_ORDER_KEY]
                    if saved_key_order == nil then
                        block[SAVED_KEY_ORDER_KEY] = { key }
                    else
                        saved_key_order[#saved_key_order + 1] = key
                    end
                end
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
            if toplevel == nil then toplevel = { block } end
            block = {}
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
local function decode(s, text_filter, ordered)
    local state = { line = 1, column = 1, text_filter = text_filter, [OPTION_ORDERED] = ordered }
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
-- without saved key order
local function knext(t, index)
    local value
    repeat index, value = next(t, index) until type(index) ~= 'number'
    return index, value
end

-- with saved key order
local function create_ordered_key_iterator(t)
    local i = 0
    local keys = t[SAVED_KEY_ORDER_KEY]
    return function()
        i = i + 1
        local idx = keys[i]
        return idx, t[idx]
    end
end

local function metadata(t)
    if t[SAVED_KEY_ORDER_KEY] then
        return create_ordered_key_iterator(t)
    else
        return knext, t, nil
    end
end

----------  Encoder  ----------
local function encode(t, compact)
    if type(t) == 'table' then
        -- TODO: detect cycles
        local result = {}
        local function append(v) result[#result + 1] = v end
        for i, v in ipairs(t) do
            local encoded_value = encode(v, compact)
            if type(v) == 'table' then
                if compact and result[#result] == ' ' then result[#result] = nil end
                if result[#result] == ']' then
                    result[#result] = ';'
                else
                    append('[')
                end
                append(encoded_value)
                append(']')
            else
                append(encoded_value)
            end
            if not compact or result[#result] ~= ']' then append(' ') end
        end
        for k, v in metadata(t) do
            -- TODO: error if k is table
            append(encode(k) .. ':')
            if not compact then append(' ') end
            append(encode(v))
            append(' ')
        end
        if result[#result] == ' ' then result[#result] = nil end
        return table.concat(result)
    else
        local encoded_value = tostring(t)
        if encoded_value:match('[ ,\t\r\n%[%]():;]') or encoded_value:match('^[\'\"`#]') then
            -- TODO: if compact, find out the quotation mark that requires less escaping
            encoded_value = '"' .. encoded_value:gsub('"', '""') .. '"'
        end
        return encoded_value
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

----------  Filter  ----------
local function bool_number_filter(s)
    if s == 'true' then return true
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
}

-- TODO: document stuff