local nested = require 'nested'

local pretty = require 'pl.pretty'
local args = require 'pl.lapp' [[
Usage: nested-compact [--tight] [<input>] [<output>]

Options:
  --tight                       Output without indentation
  <input> (default stdin)       Input file. If absent or '-', reads from stdin
  <output> (default stdout)     Output file. If absent or '-', writes to stdout
]]

if args.input == '-' then args.input = io.stdin end
if args.output == '-' then args.output = io.stdout end

local contents = assert(nested.decode_file(args.input, nested.bool_number_filter))
local output = io.output(arg[2] or io.stdout)
output:write('return ' .. pretty.write(contents, args.tight and ''))
output:close()