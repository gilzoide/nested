## Nested textual format:

- Whitespace, commas `,` and semi-colons `;` separates list nodes
- Any non-whitespace sequence that don't fall in any of the following rules
  is a text value
- Parenthesis `()`, brackets `[]` or braces `{}` delimit a child list
- Starting single quotes `'`, double quotes `"` and backticks \` delimit a single 
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

It's interesting to notice that **Nested** is a superset of the [JSON](https://www.json.org) language,
although it does not enforce the same semantics for non-textual values like numbers and `null`, nor
text escape sequences.

