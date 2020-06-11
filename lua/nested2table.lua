local nested = require 'nested'
local inspect = require 'inspect'

local arg = arg or {...}

if arg[1] == '-' then arg[1] = false end
if arg[2] == '-' then arg[2] = false end
local input = arg[1] or io.stdin
local contents = assert(nested.decode_file(input, nested.bool_number_filter))
local output = io.output(arg[2] or io.stdout)
output:write('return ' .. inspect(contents))
output:close()