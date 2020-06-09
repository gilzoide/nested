-- Ignore: blank ,;\t\r
-- Always special: \n()[]:
-- Special if first in token: '"`#
local TOKENS = {
    'SPACE', 'NEWLINE', 'EOF',
    'OPEN_BLOCK', 'CLOSE_BLOCK', 'SIBLING_BLOCK',
    'OPEN_PAREN', 'CLOSE_PAREN',
    'KEYVALUE', 'QUOTES', 'COMMENT',
}
for i = 1, #TOKENS do TOKENS[TOKENS[i]] = i end
local TOKEN_STARTER = {
    [' '] = 'SPACE', [','] = 'SPACE', [';'] = 'SPACE', ['\t'] = 'SPACE', ['\r'] = 'SPACE',
    ['\n'] = 'NEWLINE',
    [''] = 'EOF',
    ['['] = 'OPEN_BLOCK',
    [']'] = 'CLOSE_BLOCK',
    ['('] = 'OPEN_PAREN',
    [')'] = 'CLOSE_PAREN',
    [':'] = 'KEYVALUE',
    ["'"] = 'QUOTES', ['"'] = 'QUOTES', ['`'] = 'QUOTES',
    ['#'] = 'COMMENT',
}
-- Each function returns token, advance
local scanners = {
    SPACE = function(s)
        local pos = s:match('[ ,;\t\r]+()')
        return TOKENS.SPACE, pos
    end,
    NEWLINE = function(s) return TOKENS.NEWLINE, 2 end,
    OPEN_BLOCK = function(s) return TOKENS.OPEN_BLOCK, 2 end,
    CLOSE_BLOCK = function(s) return TOKENS.CLOSE_BLOCK, 2 end,
    SIBLING_BLOCK = function(s) return TOKENS.SIBLING_BLOCK, 2 end,
    OPEN_PAREN = function(s) return TOKENS.OPEN_PAREN, 2 end,
    CLOSE_PAREN = function(s) return TOKENS.CLOSE_PAREN, 2 end,
    KEYVALUE = function(s) return TOKENS.KEYVALUE, 2 end,
    QUOTES = function(s)
        local delimiter = s:match('[\'\"`]')
        -- TODO: escape sequence
        local pos = s:sub(2):match(delimiter .. '()')
        if pos then
            return s:sub(2, pos - 1), pos + 1
        else
            return nil, string.format('Unmatched closing %q', delimiter)
        end
    end,
    COMMENT = function(s)
        local pos = s:match('#[^\n]+()')
        return TOKENS.COMMENT, pos
    end,
    TEXT = function(s)
        return s:match('([^ ,;\t\r\n%[%]():]+)()')
    end,
    EOF = function(s) return TOKENS.EOF, 0 end
}

--- Read the next token 
-- @return Token and `s` without it on success
-- @return false and error message on error (when opening quotes without closing)
-- @return nil on end of input
local function next_token(s)
    local starter = s:sub(1, 1)
    local rule = TOKEN_STARTER[starter] or 'TEXT'
    return scanners[rule](s)
end

local text = [[
um dois tres: 4

[
    texto 'olars gente'
]
]]
repeat
    local token, advance = assert(next_token(text))
    text = text:sub(advance)
    print(type(token) == 'number' and TOKENS[token] or token, advance)
until not token or token == TOKENS.EOF