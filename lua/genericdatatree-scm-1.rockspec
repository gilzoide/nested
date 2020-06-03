package = 'genericdatatree'
version = 'scm-1'
source = {
	url = 'git://github.com/gilzoide/genericdatatree',
}
description = {
	summary = 'A generic tree data file format parser',
	detailed = [[
A generic data tree file format parser
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
		genericdatatree = 'genericdatatree.lua'
	}
}
