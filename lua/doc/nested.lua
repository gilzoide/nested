--- Nested data file format and nested tables functionality.
-- @module nested

--- Current version string
-- @field _VERSION

--- Postorder key to be passed to @{iterate} options (`'postorder'`)
-- @field POSTORDER

--- Postorder only value to be passed to @{iterate} options (`'only'`)
-- @field POSTORDER_ONLY

--- Table only key to be passed to @{iterate} options (`'table_only'`)
-- @field TABLE_ONLY

--- Include key-value key to be passed to @{iterate} options (`'include_kv'`)
-- @field INCLUDE_KV

--- Skip root key to be passed to @{iterate} options (`'skip_root'`)
-- @field SKIP_ROOT

---------------------------------------------------------------------------------------------------
-- Decoding
-- @section decoding

--- Decode a nested structure from text.
--
-- In case of unmatched quotes or unbalanced block delimiters, returns `nil` plus error message.
--
-- @param text  Text to be decoded
-- @param[opt] options  Table with any of the optional following fields:
-- 
--   - `text_filter`: Function to filter data from text values.
--       Receives the text, quotation mark, starting line and column as parameters.
--       If it returns a non-`nil` value, the text is replaced by it in the resulting table.
--   - `table_constructor`: Function used for constructing tables.
--       Receives as parameter the opening character: `''` for toplevel tables, `(`, `[` or `{`,
--       the starting line and column as parameters
--       Must return a table.
--       This is useful for injecting metatables into resulting nested structure.
--   - `root_constructor`: Function used for constructing the root table.
--       Defaults to `table_constructor`, if specified.
--
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
-- @param[opt] options  Forwarded to @{decode}
-- @return[1] nested table decoded
-- @return[2] `nil`
-- @return[2] error message
-- @see decode
-- @function decode_file

--- Iterator function that parses nested structure from text input, yielding meaningful tokens.
--
-- This allows one to fully customize the results from parsing, for example
-- stopping before reading the whole text and ignoring whole branches from the input.
--
-- Each time the coroutine is resumed, it yields the current line and column, the parsing event
-- and additional information if needed. Check out the usage example for possible values and
-- meaning of each value.
--
-- Check out the implementation of @{decode} for a concrete example of usage.
--
-- Unless the given parameter is not a string, the coroutine should not error.
--
-- @usage
-- for line, column, event, token, quote in nested.decode_iterate(text) do
--     if event == 'TEXT' then
--         -- token: string representing the text value
--         -- quote: nil if text is not quoted, or one of ' " ` otherwise
--     elseif event == 'KEY' then
--         -- token: the key used in a key-value form "key:"
--         -- quote: nil if the key is not quoted, or one of ' " ` otherwise
--     elseif event == 'OPEN_NESTED' then
--         -- token: the opening token for nested tables, one of [ { (
--     elseif event == 'CLOSE_NESTED' then
--         -- token: the closing token for nested tables, one of ] } )
--     elseif event == 'ERROR' then
--         -- token: the error message
--         -- iteration ends after the first error, no need for `break`
--     end
-- until not event
--
-- @param text  Text to be decoded
-- @treturn function  Coroutine function for parsing
-- @function decode_iterate


---------------------------------------------------------------------------------------------------
-- Encoding
-- @section encoding

--- Encode a nested table structure to text.
--
-- Non-table values are encoded using @{tostring}, so `__tostring` metamethods may be called for userdata.
--
-- Althought the nested textual format doesn't support references between tables other than
-- parent/child relations, Lua does. For this matter, anchors of the form `&N`, where `N` is a number,
-- are placed in tables that are referenced somewhere else, with the references for the table
-- written in the form `*N` with the same numerical `N` used before.
--
-- In the same line, although the nested textual format only supports text as keys, table keys in
-- Lua might be booleans, functions, userdata or other tables. This function will encode them,
-- but be aware that the resulting text might error when read again with `decode`, and that
-- nested is not a complete serialization scheme for Lua tables.
--
-- @param t  Table
-- @param[opt=2] indent  Indentation level to use, in spaces.
--   If > 0, each value will be placed in a new line, prefixed by the given number of space characters.
--   If == 0, no new lines will be used and values will be written separated by a single space character.
--   If < 0, no new lines will be used and values will be written in a compacted and probably illegible way.
-- @param[opt] apply_tostring_to_tables
--   If truthy, if a table has a `__tostring` metamethod, it will be applied instead of the default nested traversal.
-- @treturn string  Encoded nested structure
-- @function encode

--- Encode a nested table structure to file.
--
-- This uses @{encode}, so the same caveats apply.
--
-- @param t  Table
-- @param file_or_filename  File or filename to write to, opened with @{io.output}
-- @param[opt] indent  Forwarded to @{encode}.
-- @param[opt] apply_tostring_to_tables  Forwarded to @{encode}.
-- @return[1] true
-- @return[2] nil
-- @return[2] Error message if writing to file failed
-- @function encode_to_file


---------------------------------------------------------------------------------------------------
-- Iterating over tables.
-- @section iterating

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
-- On each call, returns a sequence table with the current key path, value, parent table and boolean flag
-- signaling if going deeper (preorder traversal) into the nested structure or not (postorder traversal).
--
-- @param t  Table
-- @param[opt] options  Table with any of the following fields:
-- 
--   - `postorder`: if truthy, also yield values when traversing back from the default preorder traversal.
--       If equal to `"only"`, perform only the postorder traversal.
--   - `table_only`: if truthy, yield table values only.
--   - `include_kv`: if truthy, iterate on key-value pairs as well as numeric indices.
--   - `skip_root`: if truthy, iterate on key-value pairs as well as numeric indices.
--
-- @usage for keypath, value, parent, going_deeper in nested.iterate(t) do
--     ...
-- end
-- @function iterate


---------------------------------------------------------------------------------------------------
-- Getting and setting nested values.
-- @section getset

--- Get the value of a nested table.
--
-- If the given key path cannot be indexed, returns `nil` plus a message with
-- where on the key path indexing failed.
--
-- @param t  Table
-- @param ...  Values passed in form the key path, with which each nested table will be indexed.
--   If only one value is passed and it is a table, it is treated as the keypath.
-- @return[1] value
-- @return[2] `nil`
-- @return[2] error message
-- @function get

--- Similar to @{get}, but creates the nested structure if it doesn't exist yet.
--
-- @param t  Table
-- @param ...  Values that form the key path, just like in @{get}.
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
-- @param ...  The first values passed in form the key path, and the last one is the value to be set.
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
-- @param ...  Values to form the key path and value to be set, just like in @{set}.
-- @return[1] `t`
-- @return[2] `nil`
-- @return[2] error message
-- @see set
-- @function set_or_create


---------------------------------------------------------------------------------------------------
-- Default filters
-- @section filter

--- Simple text filter that reads unquoted boolean and number values, meant to be passed to @{decode}.
--
-- Literal `true` and `false` values are recognized as the boolean `true` and `false` lua values.
-- Quoted versions, like `"true"` and `'false'` are not parsed and treated as strings.
--
-- Numbers are read with @{tonumber}. Similar to booleans, quoted numbers like `'1'` or `"0.5"` are
-- not parsed and treated as strings.
--
-- @param text
-- @param[opt] quotation_mark
-- @usage local data = nested.decode(text, { text_filter = nested.bool_number_filter })
-- @function bool_number_filter
