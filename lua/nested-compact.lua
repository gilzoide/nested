local nested = require 'nested'

local arg = arg or {...}

if arg[1] == '-' then arg[1] = false end
if arg[2] == '-' then arg[2] = false end
local input = arg[1] or io.stdin
local contents = assert(nested.decode_file(input))
local output = arg[2] or io.stdout
assert(nested.encode_to_file(output, contents, true))