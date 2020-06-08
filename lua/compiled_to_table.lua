local nested = require 'nested'
local filter = require 'nested.filter'
local utils = require 'nested.utils'

local inspect = require 'inspect'

local contents = assert(io.read('*a'))
contents = assert(nested.build(contents, filter.parse_bool, filter.parse_number))
print(inspect(contents))
