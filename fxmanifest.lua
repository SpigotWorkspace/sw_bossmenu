fx_version 'cerulean'
game 'gta5'

name "sw_bossmenu"
description "Bossmenu for ESX jobs"
author "SpigotWorkspace"

ui_page 'html/index.html'

files {
	'@es_extended/locale.js',
	'html/**',
}

shared_scripts {
	'@es_extended/locale.lua',
	'locales/*.lua',
	'config.lua'
}

client_scripts {
	'@es_extended/locale.js',
	'client/*.lua'
}

server_scripts {
	'@oxmysql/lib/MySQL.lua',
	'adminconfig.lua',
	'server/*.lua'
}

dependency 'es_extended'
