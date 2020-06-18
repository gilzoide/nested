local nested = require 'nested'
local nested_match = require 'nested.match'
local nested_function = require 'nested.function'

local t = nested.decode([=[
a: 5
b: 30
c: [
    d e f
    g: 200
    h: [
        is: true
        but-this: false
    ]
]

]=], nested.bool_number_filter)

local pattern = nested.decode([=[
a
c.1
c.h.but-this: [function true]
c.g: [> 100]
!b: [> 100]
!c.non-existent
]=], nested.bool_number_filter, nested_function.new)

pattern = pattern({
    ['>'] = function(const)
        return function(v)
            return v > const
        end
    end,
})
print(nested.encode(pattern))
print(nested_match(t, pattern))
