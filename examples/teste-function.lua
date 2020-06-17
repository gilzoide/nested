local nested = require 'nested'
local nested_function = require 'nested_function'

a = { b = 'b' }
local t = assert(nested.decode([=[
[print olars 1 2 a a.b]
[print a.b.c outro]
]=], nested.bool_number_filter, nested_function.new))

t()