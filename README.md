# Nested
A generic nested data structure textual format.

Data is formed by nested lists with associated key-value paired data.
Each list can have any number of elements, either sublists or text values, and any number of key-value data.
Particularly, a list containing only sequential data would be like regular *lists* or *arrays* and
a list containing only key-value data would be like *maps* or *dictionaries*.


## Format

- Whitespace, commas `,` and semi-colons `;` separates list nodes
- Any non-whitespace sequence that don't fall in any of the following rules
  is a text value
- Parenthesis `()`, brackets `[]` or braces `{}` delimit a child list
- Starting single quotes `'`, double quotes `"` and backticks <code>\`</code> delimit a single
  text value that may contain otherwise special characters, like `()`, `[]`, `,`, `:` or `;`.
  The quotation marks can be escaped by being doubled, so that the text `'one ''quoted'' phrase'`
  content becomes `one 'quoted' phrase`, for example. Notice that quotation marks can
  appear normally in the middle of text values, like `f'` or `double"quotes"`
- A number sign `#` starts a comment, so the rest of the line text is discarded.
  To use `#` as the first character in a text value, the text must be quoted
- A colon `:` just after a text value marks a key-value data binding
  with the just parsed text value being the key and the following node
  being a value. To use `:` in a text value, the text must be quoted.
  Notice that keys are always text, but values can be either text or nested lists.

It's interesting to notice that lots of valid [JSON](https://www.json.org) files are also valid **Nested** files,
although **Nested** does not enforce the same semantics for non-textual values like numbers and `null`, nor
text escape sequences.


## Implementations
For now, there is an implementation in Lua. [Lua tables](https://www.lua.org/pil/2.5.html)
are exactly a representation of data with both sequential and key-pair values.

Install it using [LuaRocks](https://luarocks.org/):

    $ luarocks install nested

Or just copy `lua/nested.lua` into your Lua path and `require` it, the module has no dependencies.

There is also a Command Line Interface script for reading and reformatting nested data in the file `lua/main.lua`.
When installing with [LuaRocks](https://luarocks.org/), the CLI script is installed as the `nested` command.

    $ luarocks install nested-cli


## Documentation
[LDoc](https://github.com/lunarmodules/LDoc) based documentation for the Lua module is
available at [github pages](https://gilzoide.github.io/nested/) and can be generated with
the following command:

    $ ldoc lua/doc -d docs

