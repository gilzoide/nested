rockspec_format = "3.0"
package = "nested"
version = "scm-3"
source = {
    url = "git://github.com/gilzoide/nested"
}
description = {
    summary = "A generic nested data structure textual format",
    detailed = [[
Nested data file format and nested tables functionality.
Includes Nested <=> Lua tables serialization, get/set by keypaths, deep iterators.
Also include a CLI script for converting Nested files to `require`able Lua scripts.
]],
    license = "Unlicense",
    labels = {
        "datastructure",
        "serialization"
    },
    maintainer = "gilzoide <gilzoide@gmail.com>"
}
dependencies = {
    "lua >= 5.1"
}
build = {
    type = "builtin",
    modules = {
        nested = "lua/nested.lua"
    },
    copy_directories = {
        "docs"
    },
    install = {
        bin = {
            nested = "lua/main.lua"
        }
    }
}
