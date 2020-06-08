local command = require 'nested'.command

--- LPeg parser
local lpeg = require 'lpeglabel'
lpeg.locale(lpeg)

local grammar
do
    local escape_sequences = {
        ['0']  = '\0',
        ['a']  = '\a',
        ['b']  = '\b',
        ['f']  = '\f',
        ['r']  = '\r',
        ['n']  = '\n',
        ['t']  = '\t',
        ['v']  = '\v',
        ['\\'] = '\\',
        ['"']  = '"',
        ["'"]  = "'",
    }

    local function from_hexa(s)
        return string.char(tonumber(s, 16))
    end

    local EOL = lpeg.S'\n'
    local EOF = lpeg.P(-1)
    local EOLOrEOF = EOL + EOF
    local Comment = lpeg.P'#' * (1 - EOL)^0
    local OneSpaceNotEOL = Comment + ((lpeg.space + lpeg.S',;') - EOL)
    local SpaceNotEOL = OneSpaceNotEOL^0
    local Space = (EOL + OneSpaceNotEOL)^0

    local Escaped = (lpeg.P'/' / '') * ((
        lpeg.S[[0abfrntv\"']] / escape_sequences
        + (lpeg.P'x' * lpeg.C(lpeg.xdigit * lpeg.xdigit)) / from_hexa
        + (lpeg.P'u{' * lpeg.C(lpeg.xdigit^1) * lpeg.P'}') / from_hexa
    ) + lpeg.T'ErrInvalidEscapeSequence')

    local Unquoted = lpeg.C((1 - lpeg.space - lpeg.S'[](),:;')^1)
    local function create_escaped_quote(opening, closing, label)
        opening = lpeg.P(opening)
        closing = lpeg.P(closing)
        return opening
            * lpeg.Cs((Escaped + (1 - closing))^0)
            * (closing + lpeg.T(label))
    end
    local Quoted =
        create_escaped_quote("'", "'", "ErrClosingSingleQuote")
        + create_escaped_quote('"', '"', "ErrClosingDoubleQuote")

    local function create_raw_quote(opening, closing, label)
        opening = lpeg.P(opening)
        closing = lpeg.P(closing)
        return opening
            * lpeg.C((1 - closing)^0)
            * (closing + lpeg.T(label))
    end
    local RawQuoted =
        create_raw_quote("r'", "'", "ErrClosingSingleQuote")
        + create_raw_quote('r"', '"', "ErrClosingDoubleQuote")
        + create_raw_quote("`", "`", "ErrClosingBackticks")

    local Text = RawQuoted + Quoted + Unquoted + (lpeg.P':' * lpeg.T'ErrStartingColon')
    local KeyValue =
        lpeg.V'Text'
        * lpeg.P':' * lpeg.Cc(command.KeyValue)
        * SpaceNotEOL
        * (lpeg.V'Block' + lpeg.V'SExpr' + lpeg.V'Text')
    local SExpr =
        lpeg.P'(' * lpeg.Cc(command.OpenNested)
        * Space
        * (lpeg.V'Expr' * Space)^0
        * (lpeg.P')' + lpeg.T'ErrClosingParentheses') * lpeg.Cc(command.CloseNested)
    local Block =
        lpeg.P'[' * lpeg.Cc(command.OpenNested)
        * Space
        * (lpeg.V'Line')^0
        * (lpeg.P']' + lpeg.T'ErrClosingBrackets') * lpeg.Cc(command.CloseNested)
    local Expr = lpeg.V'Block' + lpeg.V'SExpr' + lpeg.V'KeyValue' + lpeg.V'Text'

    local Line =
        OneSpaceNotEOL^1
        + SpaceNotEOL * EOL
        + SpaceNotEOL * (lpeg.V'KeyValue' * SpaceNotEOL)^1 * #EOLOrEOF
        + (lpeg.B(EOL) * lpeg.Cc(command.SiblingNode))^-1 * SpaceNotEOL * (lpeg.V'Expr' * SpaceNotEOL)^1

    local Chunk = lpeg.Ct((lpeg.V'Line')^1) * EOF

    grammar = lpeg.P {
        'Chunk',
        Chunk = Chunk,
        Line = Line,
        Expr = Expr,
        Block = Block,
        SExpr = SExpr,
        KeyValue = KeyValue,
        Text = Text,
    }
end

--- Module 
local re = require 'relabel'

local function parse(text)
    local res, err, pos = grammar:match(text)
    if not res then
        local line, col = re.calcline(text, pos)
        local msg = "Error at line " .. line .. " (col " .. col .. "): "
        return nil, msg .. err
    end
    return res
end

return parse