local constructor = require 'nested.constructor'
local parser = require 'nested.parser'
local utils = require 'nested.utils'

local contents = assert(io.read('*a'))
contents = assert(parser.parse(contents))
io.write(constructor.serialize(contents))
