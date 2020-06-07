local compile = require 'nested.compiler'
local parse = require 'nested.plain_text_parser'
local utils = require 'nested.utils'

local contents = assert(io.read('*a'))
contents = assert(parse(contents))
io.write(compile(contents))
