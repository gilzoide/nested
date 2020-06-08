local nested = require 'nested'
local utils = require 'nested.utils'

local inspect = require 'inspect'

local contents = assert(io.read('*a'))
contents = assert(nested.build(contents))
print(inspect(contents))
