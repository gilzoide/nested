# Nested
A generic nested data structure file format.

Data is formed by nested lists with associated key-value pair metadata.
Each list can have any number of elements, either sublists or text values, and any number of metadata.
Particularly, an empty list with metadata would be like an *associative array*, also called *maps* or *dictionaries*.


## Format
- Whitespace or commas `,` separates list nodes
- Any non-whitespace sequence that don't fall in any of the following rules
  is a text value
- Parenthesis `()` explicitly delimit a list and ignore new lines
- A new line with any elements delimit a sublist
- A new line with only metadata definitions do not delimit new sublists
- Square brackets `[]` delimit a sublist, where each new line with
  any elements is a sublist of it
- Single `'` and double `"` quotes delimit a single text value that
  may contain otherwise special characters, like `()`, `[]`, `,` or `:`.
  The following escape sequences are allowed:
  + `\a` - bell
  + `\b` - backspace
  + `\f` - form feed
  + `\n` - newline
  + `\r` - carriage return
  + `\t` - horizontal tab
  + `\v` - vertical tab
  + `\\` - backslash
  + `\"` - double quote
  + `\'` - single quote
  + `\xHH` where `HH` is a sequence of exactly two hexadecimal digits - hexadecimal byte
  + `\u{H...}` where `H...` is a sequence of one or more hexadecimal digits - unicode characters
  
  Prefixing quotes with the `r` character, like `r'` or `r"`, make escape sequences be ignored.
- Backticks ``` `` ``` also delimit a single text value, but ignoring 
  any of the above mentioned escape sequences.
- A mumber sign `#` starts a comment, so the rest of the line text is discarded.
  To use `#` as the first character in a text value, the text must be quoted
- A colon `:` just after a text value marks a key-value metadata binding
  with the just parsed text value being the key and the following node
  being a value. To use `:` in a text value, it must be quoted.
  Notice that keys are always text, but values can be either text or lists.
  