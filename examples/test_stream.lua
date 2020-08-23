local nested = require 'nested'

local stream = nested.decode_iterate([[
a: b
c: d

"some escaped text"
"escaped key": 200

nested: {
    1 2 3;
    4 5 6
}

{ another nested 
 }
]])

for line, column, event, token, quote in stream do
    print(line, column, event, token, quote)
end
