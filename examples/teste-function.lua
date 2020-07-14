nested = require 'nested'
local nested_function = require 'nested.function'
local nested_ordered = require 'nested.ordered'

a = { 1, { segundo = 2 }, 3, b = 'B' }
callable = setmetatable({}, {
    __call = function(self, ...)
        print('CALLABLE', ...)
    end
})

local _ENV = _ENV or getfenv()
_ENV['function'] = function(arguments, body)
    if not body then body, arguments = arguments, nil end
    return function(...)
        local env = _ENV or getfenv()
        if arguments then
            env = setmetatable({}, { __index = _ENV or getfenv() })
            for i = 1, #arguments do
                env[arguments[i]] = select(i, ...)
            end
        end
        if type(body) == 'string' then
            local chunk = assert(load(body, nil, 't', env))
            return chunk(...)
        else
            return nested_function.evaluate_with_env(body, env)
        end
    end
end

local t = assert(nested.decode([=[
f: [function [x y] `
    print(string.format('%d + %d = %d', x, y, x + y))
`]

f2: [function `print 'just print'`]

self.doidera.demais: 5

[print olars a.1 a.2.segundo a a.b]
[print a.b.c outro: 1]
[f 1 5 9]
[f2 ignored but evaluated args]
[[function [print 'evaluate now']]]
[callable tables work too]
]=], nested.bool_number_filter, nested_ordered.new))

print(nested.encode(nested_function.evaluate(t)))