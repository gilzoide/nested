local nested = require 'nested'

local t = { a = {'the original'} }
t.self = t
t.aloop = t.a

print(nested.encode(t))
