--- Nested data file format and nested tables functionality.
-- @module nested


--- Decode a nested structure from text.
--
-- In case of unmatched quotes or unbalanced block delimiters, returns `nil` plus error message.
--
-- @param text  Text to be decoded
-- @param[opt] text_filter  Function to filter data from text values.
--   Receives the text and quotation mark as parameters.
-- 
--   If it returns a non-`nil` value, the text is replaced by it in the resulting table.
-- @param[opt] table_constructor  Function used for constructing tables.
--   Receives  as parameter the opening character: `nil` for toplevel tables, `(`, `[` or `{`.
--   Must return a table.
-- 
--   This is useful for injecting metatables into resulting nested structure.
-- @return[1] nested table decoded
-- @return[2] `nil`
-- @return[2] error message
-- @todo support streamed IO
-- @function decode

--- Decode a nested structure from file.
--
-- This uses @{decode}, so the same caveats apply.
--
-- @param file_or_filename  File or filename to read from, opened with @{io.input}
-- @param[opt] text_filter  Forwarded to @{decode}
-- @param[opt] table_constructor  Forwarded to @{decode}
-- @return[1] nested table decoded
-- @return[2] `nil`
-- @return[2] error message
-- @see decode
-- @function decode_file


--- Encode a nested table structure to text.
--
-- Values are encoded using @{tostring}, so a `__tostring` method may be called.
--
-- @param t  Table
-- @param[opt] compact  Remove unnecessary whitespace and use `;` for sibling tables whenever possible
-- @return[1] encoded nested structure
-- @return[2] `nil`
-- @return[2] error message in case of cyclic references
-- @function encode

--- Encode a nested table structure to file.
--
-- This uses @{encode}, so the same caveats apply.
--
-- @param t  Table
-- @param file_or_filename  File or filename to write to, opened with @{io.output}
-- @param[opt] compact  Remove unnecessary whitespace and use `;` for sibling tables whenever possible
-- @function encode


--- Iterate over non-numeric key-value pairs.
-- 
-- This is a shallow iteration. For iterating over nested tables, use @{iterate} instead.
--
-- This uses @{pairs}, so the `__pairs` metamethod may be called in Lua 5.2+
-- 
-- @param t  Table
-- @usage for k, v in nested.kpairs(t) do
--     ...
-- end
-- @function kpairs

--- Iterate in depth over a nested table.
--
-- On each call, returns a sequence table with the current key path, value and parent table.
--
-- @param t  Table
-- @param options  Table with any of the following fields:
-- 
--   - `order`: if equal to `"postorder"`, perform a postorder traversal, otherwise perform a preorder traversal.
--   - `table_only`: if truthy, yield table values only.
--   - `include_kv`: if truthy, iterate on key-value pairs as well as numeric indices.
--
-- @usage for keypath, value, parent in nested.iterate(t) do
--     ...
-- end
-- @function iterate


--- Get the value of a nested table.
--
-- If the given key path cannot be indexed, returns `nil` plus a message with
-- where on the key path indexing failed.
--
-- @param t  Table
-- @param[opt] ...  Values passed in form the key path, with which each nested table will be indexed.
--   If only one value is passed and it is a table, it is treated as the keypath.
-- @return[1] value
-- @return[2] `nil`
-- @return[2] error message
-- @function get

--- Similar to @{get}, but creates the nested structure if it doesn't exist yet.
--
-- @param t  Table
-- @param[opt] ...  Values that form the key path.
-- @return[1] value
-- @return[2] `nil`
-- @return[2] error message
-- @see get
-- @function get_or_create

--- Set the value of a nested table.
--
-- If the given key path cannot be indexed, returns `nil` plus a message with
-- where on the key path indexing failed.
--
-- @param t  Table
-- @param[opt] ...  The first values passed in form the key path, and the last one is the value to be set.
--   If the key path has only one table value, then it is treated as the keypath.
--
--   To unset a value, `nil` have to be passed explicitly as the last argument.
-- @return[1] `t`
-- @return[2] `nil`
-- @return[2] error message
-- @function set

--- Similar to @{set}, but creates the nested structure if it doesn't exist yet.
--
-- @param t  Table
-- @param[opt] ...  Values to form the key path and value to be set.
-- @return[1] `t`
-- @return[2] `nil`
-- @return[2] error message
-- @see set
-- @function set_or_create


--- Simple text filter that reads unquoted boolean and number values, meant to be passed to @{decode}.
--
-- Literal `true` and `false` values are recognized as the boolean `true` and `false` lua values.
-- Quoted versions, like `"true"` and `'false'` are not parsed and treated as strings.
--
-- Numbers are read with @{tonumber}. Similar to booleans, quoted numbers are not parsed.
--
-- @param text
-- @param quotation_mark
-- @usage local data = nested.decode(text, nested.bool_number_filter)
-- @function bool_number_filter