nested = require 'nested'
local nested_function = require 'nested.function'

a = { 1, { segundo = 2 }, 3, b = 'b' }
callable = setmetatable({}, {
    __call = function(self, ...)
        print('CALLABLE', ...)
    end
})
local t = assert(nested.decode([=[
f: [function [x y][
    print OYES x y
]]

f2: [function `print 'just print'`]

self.doidera.demais: 5

[print olars a.1 a.2.segundo a a.b]
[print a.b.c outro: 1]
[f 1 5 9]
[f2 ignored but evaluated args]
[[function [print 'evaluate now']]]
[callable tables work too]
]=], nested.bool_number_filter, nested_function.new))

print(nested.encode(t()))