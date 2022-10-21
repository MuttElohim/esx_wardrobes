fx_version   'cerulean'
use_experimental_fxv2_oal 'yes'
lua54        'yes'
game         'gta5'

shared_scripts {'@es_extended/imports.lua', '@es_extended/locale.lua', 'locales/*.lua', 'config.lua'}

client_scripts {
	'client/main.lua'
}

server_scripts {
	'server/wardrobes.txt',
	'server/main.lua'
}