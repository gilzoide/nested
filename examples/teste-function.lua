nested = require 'nested'
local nested_function = require 'nested_function'

a = { 1, { segundo = 2 }, 3, b = 'b' }
local t = assert(nested.decode([=[
f: [function [x y][
    print OYES x y
]]

f2: [function [
    print 'just print'
]]

[print olars a.1 a.2.segundo a a.b]
[print a.b.c outro: 1]
[f 1 5 9]
[f2 ignored but evaluated args]
[[function [print 'evaluate now']]]
]=], nested.bool_number_filter, nested_function.new))

t()