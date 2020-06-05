local Nested = require 'nested'

describe("When parsing input,", function()
    it("returns list of atoms in line", function()
        local text = "1 2 3   +4'\tfive"
        local res = Nested.parse(text)
        assert.are.same({'1', '2', '3', '+4\'', 'five'}, res)
    end)

    it("returns one list per non-empty line", function()
        local text = [[

        one
        per line

        skips empty lines
        ]]
        local res = Nested.parse(text)
        assert.are.same({
            {'one'},
            {'per', 'line'},
            {'skips', 'empty', 'lines'},
        }, res)
    end)

    it("unescaped single quotes delimit a single atom", function()
        local text = "first 'second and still second' third"
        local res = Nested.parse(text)
        assert.are.same({'first', 'second and still second', 'third'}, res)

        text = [[first 'second\'escaped' third]]
        res = Nested.parse(text)
        assert.are.same({'first', "second'escaped", 'third'}, res)
    end)

    it("single quotes delimiter must be closed", function()
        local text = [[this 'is an error\'"]]
        local res, err = Nested.parse(text)
        assert.is_nil(res)
    end)

    it("unescaped double quotes delimit a single atom", function()
        local text = [[first "second and still second" third]]
        local res = Nested.parse(text)
        assert.are.same({'first', 'second and still second', 'third'}, res)

        text = [[first "second\"escaped" third]]
        res = Nested.parse(text)
        assert.are.same({'first', 'second"escaped', 'third'}, res)
    end)

    it("double quotes delimiter must be closed", function()
        local text = [[this "is an error\"']]
        local res, err = Nested.parse(text)
        assert.is_nil(res)
    end)

    it("parenthesized atoms become sublist", function()
        local text = "outside (inside)  (another inside one)"
        local res = Nested.parse(text)
        assert.are.same({'outside', {'inside'}, {'another', 'inside', 'one'}}, res)
    end)

    it("whole parenthesized line counts as a single list", function()
        local text = [[

        (first line)
        

        (second line) with outside atoms
        third line
        ]]
        local res = Nested.parse(text)
        assert.are.same({
            {'first', 'line'},
            {{'second', 'line'}, 'with', 'outside', 'atoms'},
            {'third', 'line'},
        }, res)
    end)

    it("parenthesis across multiple lines become a single list", function()
        local text = [[
        (this is 
            a single
            list
        )
        (
            likewise
        )
        back to normal
        ]]
        local res = Nested.parse(text)
        assert.are.same({
            {'this', 'is', 'a', 'single', 'list'},
            {'likewise'},
            {'back', 'to', 'normal'},
        }, res)
    end)

    describe("errors with unbalanced parenthesis", function()
        local lines = {
            "(",
            ")",
            "(()",
            "())",
        }

        for i, text in ipairs(lines) do
            it(string.format("-- %q", line), function()
                assert.has.errors(function() assert(Nested.parse(text)) end)
            end)
        end
    end)

    it("groups blocks lines", function()
        local text = [[
        block {
            first line
            second line
            (third
                line)
        } continues

        {
            another block
        }

        empty {} block

        after
        ]]
        local res = Nested.parse(text)
        assert.are.same({
            {
                'block',
                {
                    {'first', 'line'},
                    {'second', 'line'},
                    {'third', 'line'},
                },
                'continues',
            },
            {{'another', 'block'}},
            {'empty', {}, 'block'},
            {'after'},
        }, res)
    end)

    it("single line is flattened", function()
        local text = [[ single line ]]
        local res = Nested.parse(text)
        assert.are.same({ 'single', 'line' }, res)
    end)
    
    it("single block is not flattened", function()
        local text = [[{ single block }]]
        local res = Nested.parse(text)
        assert.are.same({
            {'single', 'block'},
        }, res)
    end)

    it("'=' between symbols without spaces set keyed value", function()
        local text = [[line words key=value key2=value2]]
        local res = Nested.parse(text)
        assert.are.same({
            'line', 'words',
            key = 'value',
            key2 = 'value2',
        }, res)

        text = [[
            line (sublist have=data) (this one have=too) outer=also
        ]]
        res = Nested.parse(text)
        assert.are.same({
            'line',
            { 'sublist', have = "data" },
            { 'this', 'one', have = "too" },
            outer = 'also',
        }, res)
    end)

    it("'=' between symbols may be quoted", function()
        local text = [[line words 'this is a single key'="single value" "
"=' ']]
        local res = Nested.parse(text)
        assert.are.same({
            'line', 'words',
            ['this is a single key'] = 'single value',
            ['\n'] = ' ',
        }, res)
    end)

    it("quoted '=' are not keyed values", function()
        local text = [[this is 'not key=not value']]
        local res = Nested.parse(text)
        assert.are.same({
            'this', 'is', 'not key=not value'
        }, res)
    end)

    it("'=' must match another symbol immediately", function()
        local text = [[this is= an error]]
        local res, err = Nested.parse(text)
        assert.is_nil(res)
    end)
end)
