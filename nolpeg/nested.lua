-- Ignore: blank ,;\t\r
-- Always special: \n()[]:
-- Special if first in token: '"`#
local TOKEN = {
    'SPACE', 'COMMENT', 'NEWLINE', 'EOF',
    'OPEN_BLOCK', 'CLOSE_BLOCK',
    'OPEN_PAREN', 'CLOSE_PAREN',
    'KEYVALUE', 
    -- 'QUOTES', 'TEXT' -- both return as strings rather than numeric codes
}
for i = 1, #TOKEN do TOKEN[TOKEN[i]] = i end

local TOKEN_STARTER = {
    [' '] = 'SPACE', [','] = 'SPACE', [';'] = 'SPACE', ['\t'] = 'SPACE', ['\r'] = 'SPACE',
    ['#'] = 'COMMENT',
    ['\n'] = 'NEWLINE',
    [''] = 'EOF',
    ['['] = 'OPEN_BLOCK',
    [']'] = 'CLOSE_BLOCK',
    ['('] = 'OPEN_PAREN',
    [')'] = 'CLOSE_PAREN',
    [':'] = 'KEYVALUE',
    ["'"] = 'QUOTES', ['"'] = 'QUOTES', ['`'] = 'QUOTES',
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
    OPEN_BLOCK = function(s) return TOKEN.OPEN_BLOCK, 2 end,
    CLOSE_BLOCK = function(s) return TOKEN.CLOSE_BLOCK, 2 end,
    OPEN_PAREN = function(s) return TOKEN.OPEN_PAREN, 2 end,
    CLOSE_PAREN = function(s) return TOKEN.CLOSE_PAREN, 2 end,
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

--- Read the next token 
-- @return Token and `s` without it on success
-- @return nil and error message on error (when opening quotes without closing)
local function next_token(s)
    local starter = s:sub(1, 1)
    local rule = TOKEN_STARTER[starter] or 'TEXT'
    return lexical_scanners[rule](s)
end

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

function Parser:read_block(s, expected_closing)
    local block = {}
    local current_child = 0
    local key, value
    repeat
        local token, advance = next_token(s)
        print(type(token) == 'number' and TOKEN[token] or token, advance)
        if token == nil then return nil, advance
        elseif type(token) == 'string' then
            value = token
        elseif token == expected_closing then
            -- block closed correctly, advance `s` and break normally
        elseif token == TOKEN.CLOSE_BLOCK or token == TOKEN.CLOSE_PAREN or token == TOKEN.EOF then
            if expected_closing == nil then break
            else return nil, string.format('Expected closing block with %s, but found %s', TOKEN[expected_closing], TOKEN[token])
            end
        elseif token == TOKEN.OPEN_BLOCK or token == TOKEN.OPEN_PAREN then
            value, s = self:read_block(s:sub(advance), token == TOKEN.OPEN_BLOCK and TOKEN.CLOSE_BLOCK or TOKEN.CLOSE_PAREN)
            if value == nil then return nil, s end
        elseif token == TOKEN.KEYVALUE then
            key = value
            value = nil
        elseif token == TOKEN.NEWLINE then
            self.line = self.line + 1
            self.column = 0 -- after advance, column will be 1
        end
        s = s:sub(advance)
        self.column = self.column + advance - 1
    until token == expected_closing
    return block, s
end

local text = [[
um dois tres: 4

[
    'texto entre ''quotes'' ''escapadas'''
    esse texto tem#hash#: sim
    # daqui pra frente, comentario
]

cinco: (1 2 5)
]]
local result = assert(Parser.new():match(text))

print(require 'inspect'(result))
