local nested = require 'nested'

describe("When parsing nested content", function()
    it("single elements form a table with this element", function()
        assert.same({ 'hello' }, nested.decode"hello")
        assert.same({ 'world' }, nested.decode"world")
    end)

    it("quotes define a single text and may be escaped by doubling", function()
        assert.same({ 'hello world' }, nested.decode"'hello world'")
        assert.same({ 'hello   world' }, nested.decode"'hello   world'")
        assert.same({ 'this is\nmultiline' }, nested.decode[[
`this is
multiline`
        ]])
        assert.same({ '\'', '"', '`', 'oy " es' }, nested.decode[['''' """" ```` "oy "" es"]])
    end)

    it("unescaped whitespace, commas and semi-colons are skipped", function()
        assert.same({}, nested.decode"    ")
        assert.same({}, nested.decode[[

        ]])
        assert.same({}, nested.decode",,,   ,,,")
        assert.same({}, nested.decode", ; , ; , ; ,")
        assert.same({ 'element' }, nested.decode"  element  ")
        assert.same({ 'element' }, nested.decode[[ 

        element
        ]])
        assert.same({ 'element' }, nested.decode",,element     ,   ,,,")
        assert.same({ 'element' }, nested.decode", ; , ; ,element; ,")
    end)

    it("sequential elements form a sequence table", function()
        assert.same({ 'hello', 'world' }, nested.decode"hello world")
        assert.same({ 'hello world', 'again' }, nested.decode"'hello world' ,    again")
    end)

    it("key-value pairs form a table with key-value pairs", function()
        assert.same({ a = 'a', b = 'b', c = 'c' }, nested.decode[[
            a: a
            b:b
            c:
            c
        ]])
    end)

    it("sequential and key-value pairs may appear in the same table in any other", function()
        assert.same({ '1', '2', '3', a = 'a', b = 'b', c = 'c' }, nested.decode[[
        1 2,
        3; a: a
b:    ,b;c:
        c]])
    end)

    it("quotes in middle of text is not considered escape sequences", function()
        assert.same({ 'text"not', 'escaped"' }, nested.decode[[  text"not escaped" ]])
        assert.same({ "another'one" }, nested.decode[[ another'one;]])
        assert.same({ "o`-``o" }, nested.decode[[  o`-``o  ]])
    end)
end)
