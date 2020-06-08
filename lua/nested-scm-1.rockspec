package = 'nested'
version = 'scm-1'
source = {
	url = 'git://github.com/gilzoide/nested',
}
description = {
	summary = 'A generic nested data structure file format parser',
	detailed = [[
A generic nested data structure file format parser
]],
	license = 'LGPLv3',
	maintainer = 'gilzoide <gilzoide@gmail.com>'
}
dependencies = {
	'lua >= 5.1',
	'lpeglabel >= 1.6',
}
build = {
	type = 'builtin',
	modules = {
		['nested.init'] = 'nested/init.lua',
		['nested.filter'] = 'nested/filter.lua',
		['nested.utils'] = 'nested/utils.lua',
		['nested.compiler'] = 'nested/compiler.lua',
		['nested.plain_text_parser'] = 'nested/plain_text_parser.lua',
	},
	install = {
		bin = {
			['nested'] = 'main.lua'
		}
	},
}
