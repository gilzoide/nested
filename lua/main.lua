local nested = require 'nested'
local lapp = require 'pl.lapp'
local OrderedMap = require 'pl.OrderedMap'

local args = lapp [[
Usage: nested [--table] [--indent <indent>] [<input>] [-o <output>]

Options:
  --table                       Output a `require`able lua script that returns the data as a single table
  -i,--indent (default 2)       Indentation level used.
  <input> (default stdin)       Input file. If absent, reads from stdin
  -o,--output (default stdout)  Output file. If absent, writes to stdout
]]

local have_stringstream, stringstream = pcall(require, 'stringstream')
local stream = have_stringstream and assert(stringstream.new(args.input, nil, 4096)) or args.input:read('*a')
local contents = assert(nested.decode(stream, {
    text_filter = args.table and nested.bool_number_filter or nil,
    table_constructor = function() return OrderedMap() end,
}))

if args.table then
    local ret = args.indent <= 0 and 'return' or 'return '
    args.output:write(ret .. pretty.write(contents, string.rep(' ', args.indent)))
else
    local encoded_value = assert(nested.encode(contents, args.indent))
    args.output:write(encoded_value)
end
