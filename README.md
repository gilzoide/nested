# Nested
A generic nested data structure textual format.

Data is formed by nested lists with associated key-value paired data.
Each list can have any number of elements, either sublists or text values, and any number of key-value data.
Particularly, a list containing only sequential data would be like regular *lists* or *arrays* and
a list containing only key-value data would be like *associative arrays*, *maps* or *dictionaries*.


## Format

- Whitespace or commas `,` separates list nodes
- Any non-whitespace sequence that don't fall in any of the following rules
  is a text value
- Parenthesis `()`, brackets `[]` or braces `{}` explicitly delimit a child list
- Starting single quotes `'`, double quotes `"` and backticks ``` `` ``` delimit a single 
  text value that may contain otherwise special characters, like `()`, `[]`, `,`, `:` or `;`.
  The quotation marks can be escaped by being doubled, so that the text `'one ''quoted'' phrase'`
  content becomes `one 'quoted' phrase`, for example. Notice that quotation marks can
  appear normally in the middle of text values, like `f'` or `double"quotes"`
- A mumber sign `#` starts a comment, so the rest of the line text is discarded.
  To use `#` as the first character in a text value, the text must be quoted
- A colon `:` just after a text value marks a key-value data binding
  with the just parsed text value being the key and the following node
  being a value. To use `:` in a text value, the text must be quoted.
  Notice that keys are always text, but values can be either text or nested lists.
- A semi-colon `;` delimits separate nested lists, so that new values parsed are
  stored in a brand new list. For example, the line `a b; c d; e f` evaluates to
  the same nested structure as `[a b] [c d] [e f]`.
