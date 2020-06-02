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

local grammar = re.compile([[
Chunk <- Space {| (Line Space)* |} -> flatten_single_table !.
Line <- (({| '' |} (Expr SpaceButEOL)+) ~> append_values) -> flatten_single_table
Expr <- Block / SExpr / Atom

Block <- '{' Space {| (Line Space)* |} '}'^ErrClosingBlock
SExpr <- '(' Space ({| '' |} (Expr Space)* ) ~> append_values ')'^ErrClosingParentheses
Atom <- {: Symbol ('=' Symbol^ErrAssignmentValue)? :}

Symbol <- SingleQuoted / DoubleQuoted / { Unquoted }
SingleQuoted <- "'" {~ ("\'" -> "'" / [^'])* ~} "'"^ErrClosingSingleQuote
DoubleQuoted <- '"' {~ ('\"' -> '"' / [^"])* ~} '"'^ErrClosingDoubleQuote
Unquoted <- [^%s(){}=]+

Space <- %s*
SpaceButEOL <- (!%nl %s)*
]], {
    flatten_single_table = flatten_single_table,
    append_values = append_values,
})

--- Module 
local GenericDataTree = {}

function GenericDataTree.parse(text)
    local res, err, pos = grammar:match(text)
    if not res then
        local line, col = re.calcline(text, pos)
        local msg = "Error at line " .. line .. " (col " .. col .. "): "
        return nil, msg .. err
    end
    return res
end

return GenericDataTree
