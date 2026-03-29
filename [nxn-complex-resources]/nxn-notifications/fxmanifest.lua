fx_version 'cerulean'
game 'gta5'

name        'nxn-notifications'
description 'NEXON RELOADED — Modular In-Game Notification System'
version     '1.0.0'
author      'NEXON RELOADED'

lua54 'yes'

shared_scripts {
    'config.lua',
}

client_scripts {
    'client.lua',
}

server_scripts {
    'server.lua',
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/notifications.js',
    'html/notifications.css',
}
