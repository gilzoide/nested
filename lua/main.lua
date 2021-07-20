local nested = require 'nested'
local lapp = require 'pl.lapp'
local OrderedMap = require 'pl.OrderedMap'
local pretty = require 'pl.pretty'

local args = lapp [[
Usage:
  nested [<input>] [-o <output>] [--table] [--indent <indent>]
  nested (-h | --help)
  nested --version  

Options:
  <input> (default stdin)       Input file. If absent, reads from stdin.
  -o,--output (default stdout)  Output file. If absent, writes to stdout.
  --table                       Output a `require`able lua script that returns the data as a single table.
  -i,--indent (default 2)       Indentation level used.
                                If passed any negative number, provides the most compact output.

  -h,--help                     Print this usage help and exit.
  --version                     Print app version and exit.
]]

if args.version then
    print('nested version ' .. nested._VERSION)
    return
end

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
