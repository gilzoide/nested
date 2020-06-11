# Nested
A generic nested data structure file format.

Data is formed by nested lists with associated key-value pair metadata.
Each list can have any number of elements, either sublists or text values, and any number of metadata.
Particularly, an empty list with metadata would be like an *associative array*, also called *maps* or *dictionaries*.


## Format
- Whitespace or commas `,` separates list nodes
- Any non-whitespace sequence that don't fall in any of the following rules
  is a text value
- Parenthesis `()`, brackets `[]` or braces `{}` explicitly delimit a child list
- Single quotes `'`, double quotes `"` and backticks ``` `` ``` delimit a single text value that
  may contain otherwise special characters, like `()`, `[]`, `,` or `:`.
  The quotation marks can be escaped by being doubled, so that the text `'one ''quoted'' phrase'`
  content becomes `one 'quoted' phrase`, for example.
- A mumber sign `#` starts a comment, so the rest of the line text is discarded.
  To use `#` as the first character in a text value, the text must be quoted
- A colon `:` just after a text value marks a key-value metadata binding
  with the just parsed text value being the key and the following node
  being a value. To use `:` in a text value, the text must be quoted.
  Notice that keys are always text, but values can be either text or nested lists.
- A semicolon `;` delimits separate nested lists, so that new values parsed are
  stored in a brand new list. For example, the line `a b; c d; e f` evaluates to
  the same nested structure as `[a b] [c d] [e f]`.
