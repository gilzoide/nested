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
		nested = 'nested.lua'
	}
}
