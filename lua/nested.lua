--- LPeg parser
local re = require 'relabel'

local function flatten_single_table(t)
    if #t == 1 and type(t[1]) == 'table' then
        return t[1]
    else
        return t
    end
end

local function append_values(t, ...)
    local n = select('#', ...)
    if n == 1 then table.insert(t, ...)
    elseif n == 2 then rawset(t, ...)
    else error("append_values should never receive more than 2 values")
    end
    return t
end

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

local grammar = re.compile([[
Chunk <- Space {| (Line Space)* |} !.
Line <- (KeyValue SpaceNotEOL)+ &EOLOrEOF
      / (({| '' |} (Expr SpaceNotEOL)+) ~> append_values) -> flatten_single_table
Expr <- Block / SExpr / KeyValue / Text

Block <- '[' Space ({| '' |} (Line Space)* ) ~> append_values ']'^ErrClosingBlock
SExpr <- '(' Space ({| '' |} (Expr Space)* ) ~> append_values ')'^ErrClosingParentheses
KeyValue <- {: Text ':' Space Text^ErrAssignmentValue :}

Text <- RawQuoted / EscapeQuoted / { Unquoted } / ':' %{ErrStartingColon} / '#' %{ErrStartingHash}
RawQuoted <- RawSingleQuoted / RawDoubleQuoted / BacktickQuoted
RawSingleQuoted <- "r'" { [^']* } "'"^ErrClosingSingleQuote
RawDoubleQuoted <- 'r"' { [^"]* } '"'^ErrClosingDoubleQuote
BacktickQuoted <- '`' { [^`]* } '`'^ErrClosingBackticks
EscapeQuoted <- EscapeSingleQuoted / EscapeDoubleQuoted
EscapeSingleQuoted <- "'" {~ (Escaped / [^'])* ~} "'"^ErrClosingSingleQuote
EscapeDoubleQuoted <- '"' {~ (Escaped / [^"])* ~} '"'^ErrClosingDoubleQuote
Unquoted <- [^][%s,():#]+

Space <- (Comment / EOL / OneSpaceNotEOL)*
SpaceNotEOL <- OneSpaceNotEOL*
OneSpaceNotEOL <- (!%nl [%s,])
Comment <- '#' [^%nl]*
EOL <- %nl
EOLOrEOF <- (%nl / !.)

Escaped <- '\' -> '' (
    [0abfrntv\"'] -> escape_sequences
    / ('x' {%x %x}) -> from_hexa
    / ('u{' {%x+} '}') -> from_hexa
)^ErrInvalidEscapeSequence
]], {
    append_values = append_values,
    escape_sequences = escape_sequences,
    flatten_single_table = flatten_single_table,
    from_hexa = from_hexa,
})


--- Module 
local Nested = {}

function Nested.parse(text, dont_flatten_single_list)
    local res, err, pos = grammar:match(text)
    if not res then
        local line, col = re.calcline(text, pos)
        local msg = "Error at line " .. line .. " (col " .. col .. "): "
        return nil, msg .. err
    end
    if not dont_flatten_single_list then
        res = flatten_single_table(res)
    end
    return res
end

local function next_not_i(t, index)
    local value
    repeat
        index, value = next(t, index)
    until type(index) ~= 'number'
    return index, value
end
function Nested.pairs(t)
    return next_not_i, t, nil
end

return Nested
