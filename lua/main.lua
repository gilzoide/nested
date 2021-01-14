local nested = require 'nested'
local stringstream = require 'stringstream'
require 'pl'

local args = lapp [[
Usage: nested [--table] [--indent <indent>] [<input>] [-o <output>]

Options:
  --table                       Output a `require`able lua script that returns the data as a single table
  -i,--indent (default 2)       Indentation level used.
  <input> (default stdin)       Input file. If absent, reads from stdin
  -o,--output (default stdout)  Output file. If absent, writes to stdout
]]

if args.input_name == '-' then args.input:close(); args.input = io.stdin end
if args.output_name == '-' then args.output:close(); args.output = io.stdout end

local stream = assert(stringstream.new(args.input, nil, 4096))
local contents = assert(nested.decode(stream, {
    text_filter = args.table and nested.bool_number_filter or nil,
    table_constructor = function() return OrderedMap() end,
}))

if args.table then
    local ret = args.indent <= 0 and 'return' or 'return '
    args.output:write(ret .. pretty.write(contents, string.rep(' ', args.indent)))
else
    assert(nested.encode_to_file(contents, args.output, args.indent))
end
