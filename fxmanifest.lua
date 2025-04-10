fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'qbx_minigames'
author 'Vein'
version '1.0.0'
description 'Custom minigames for QBox Framework'

client_scripts {
    'client/main.lua',
}

ui_page 'web/build/index.html'

files {
    'web/build/index.html',
    'web/build/**/*'
}

dependencies {
    'qbx_core'
} 