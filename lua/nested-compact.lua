local nested = require 'nested'

local args = require 'pl.lapp' [[
Usage: nested-compact [--tight] [<input>] [<output>]

Options:
  --tight                       Remove unecessary whitespaces and use ';' to delimit sibling lists
  <input> (default stdin)       Input file. If absent or '-', reads from stdin
  <output> (default stdout)     Output file. If absent or '-', writes to stdout
]]

if args.input == '-' then args.input = io.stdin end
if args.output == '-' then args.output = io.stdout end

local contents = assert(nested.decode_file(args.input))
assert(nested.encode_to_file(args.output, contents, args.tight))