fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'dqrkuss_carwipe'
author 'dqrkuss'
description 'Scheduled cleanup of empty cars with a countdown, admin panel, safe zones and a keep list'
version '1.0.1'

shared_scripts {
    'shared/i18n.lua',
    'config/main.lua',
    'config/advanced.lua',
    'shared/rules.lua',
}

server_scripts {
    'server/framework.lua',
    'server/admin.lua',
    'server/vehicles.lua',
    'server/touch.lua',
    'server/keep.lua',
    'server/zones.lua',
    'server/garage.lua',
    'server/garages/*.lua',
    'server/wipe.lua',
    'server/commands.lua',
    'server/panel.lua',
}

client_scripts {
    'client/handoff.lua',
    'client/main.lua',
    'client/panel.lua',
}

ui_page 'web/dist/index.html'

files {
    'locales/*.json',
    'web/dist/index.html',
    'web/dist/assets/*',
}
