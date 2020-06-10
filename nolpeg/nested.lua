-- Ignore: blank ,;\t\r
-- Always special: \n()[]:
-- Special if first in token: '"`#
local TOKEN = {
    'SPACE', 'COMMENT', 'NEWLINE', 'EOF',
    'OPEN_BRACKETS', 'CLOSE_BRACKETS',
    'OPEN_PAREN', 'CLOSE_PAREN',
    'OPEN_BRACES', 'CLOSE_BRACES',
    'KEYVALUE', 
    -- 'QUOTES', 'TEXT' -- both return as strings rather than numeric codes
}
for i = 1, #TOKEN do TOKEN[TOKEN[i]] = i end

local TOKEN_BY_PREFIX = {
    [' '] = 'SPACE', [','] = 'SPACE', [';'] = 'SPACE', ['\t'] = 'SPACE', ['\r'] = 'SPACE',
    ['#'] = 'COMMENT',
    ['\n'] = 'NEWLINE',
    [''] = 'EOF',
    ['['] = 'OPEN_BRACKETS',
    [']'] = 'CLOSE_BRACKETS',
    ['('] = 'OPEN_PAREN',
    [')'] = 'CLOSE_PAREN',
    ['{'] = 'OPEN_BRACES',
    ['}'] = 'CLOSE_BRACES',
    [':'] = 'KEYVALUE',
    ["'"] = 'QUOTES', ['"'] = 'QUOTES', ['`'] = 'QUOTES',
}
local MATCHING_CLOSING_BLOCK = {
    [TOKEN.OPEN_BRACKETS] = TOKEN.CLOSE_BRACKETS,
    [TOKEN.OPEN_PAREN] = TOKEN.CLOSE_PAREN,
    [TOKEN.OPEN_BRACES] = TOKEN.CLOSE_BRACES,
}
-- Each function returns token, advance
local lexical_scanners = {
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
    QUOTES = function(s)
        local delimiter = s:match('[\'\"`]')
        local components = {}
        for m, pos in s:sub(2):gmatch('([^' .. delimiter .. ']*' .. delimiter .. '?)' .. delimiter .. '()') do -- ([^']*'?)'()
            components[#components + 1] = m
            if m:sub(-1) ~= delimiter then
                return table.concat(components), pos + 1
            end
        end
        return nil, string.format('Unmatched closing %q', delimiter)
    end,
    TEXT = function(s)
        return s:match('([^ ,;\t\r\n%[%]():]+)()')
    end,
}

local function peek_token_type_name(s)
    local prefix = s:sub(1, 1)
    return TOKEN_BY_PREFIX[prefix] or 'TEXT'
end
--- Read the next token 
-- @return Token and `s` without it on success
-- @return nil and error message on error (when opening quotes without closing)
local function next_token(s)
    local rule = peek_token_type_name(s)
    return lexical_scanners[rule](s)
end

local function readable_token(t) return type(t) == 'number' and TOKEN[t] or t end

local Parser = {}
Parser.__index = Parser

function Parser.new()
    return setmetatable({}, Parser)
end

function Parser:match(s)
    self.text = s
    self.line, self.column = 1, 1
    local block, err = self:read_block(s, TOKEN.EOF)
    if block == nil then return nil, string.format('Error at line %u (col %u): %s', self.line, self.column, err)
    else return block 
    end
end

function Parser:read_block(s, expected_closing, into_block)
    local block = into_block or {}
    local target = block
    local next_atom_is_nested = false
    local key, value, token, previous_token, advance
    repeat
        previous_token = token
        token, advance = next_token(s)
        -- print(readable_token(previous_token), readable_token(token))
        if token == nil then
            return nil, advance
        elseif type(token) == 'string' then
            if key then
                target[key] = token
                key = nil
            elseif peek_token_type_name(s:sub(advance)) == 'KEYVALUE' then
                key = token
            elseif next_atom_is_nested then
                target, s = self:read_block(s:sub(advance), nil, { token })
                if target == nil then return nil, s end
                advance = 1
                block[#block + 1] = target
                next_atom_is_nested = false
            else
                target[#target + 1] = token
            end
        elseif token == expected_closing then
            -- block closed correctly, advance `s` and break normally
        elseif token == TOKEN.EOF or token == TOKEN.CLOSE_BRACKETS or token == TOKEN.CLOSE_PAREN or token == TOKEN.CLOSE_BRACES then
            if expected_closing == nil then break
            else return nil, string.format('Expected closing block with %s, but found %s', TOKEN[expected_closing], TOKEN[token])
            end
        elseif token == TOKEN.OPEN_BRACKETS or token == TOKEN.OPEN_PAREN or token == TOKEN.OPEN_BRACES then
            value, s = self:read_block(s:sub(advance), MATCHING_CLOSING_BLOCK[token])
            if value == nil then return nil, s end
            target[key or #target + 1] = value
            key = nil
            next_atom_is_nested = false
        elseif token == TOKEN.KEYVALUE then
            if type(previous_token) ~= 'string' then
                return nil, string.format('Key-value mapping must appear right after text, found %s instead', TOKEN[previous_token])
            end
        elseif token == TOKEN.NEWLINE then
            self.line = self.line + 1
            self.column = 0 -- after advance, column will be 1
            if expected_closing ~= TOKEN.CLOSE_PAREN then
                next_atom_is_nested = true
            end
        else
            assert(token == TOKEN.SPACE or token == TOKEN.COMMENT, 'FIXME!!!')
        end
        s = s:sub(advance)
        self.column = self.column + advance - 1
    until token == expected_closing
    return block, s
end

local text = [[
size: 30
paranaue: 50

filho1 {
    size: 20

    filho2 {
        
    }
}

um dois tres: 4

[
    'texto entre ''quotes'' ''escapadas'''
    esse texto tem#hash#: sim
    vazio: ''
    # daqui pra frente, comentario
]

cinco:
    (1 2 5)
]]
local result = assert(Parser.new():match(text))

print(require 'inspect'(result))
