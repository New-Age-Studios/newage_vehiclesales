fx_version 'cerulean'
game 'gta5'

description 'newage_vehiclesales'
--repository ''
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    '@qbx_core/modules/lib.lua',
    'config/config.lua',
    'shared/locale.lua'
}

client_scripts {
    '@qbx_core/modules/playerdata.lua',
    'client/mileage_bridge.lua', -- Adaptador de quilometragem (edite para trocar o sistema)
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'config/webhook.lua',
    'server/mileage_bridge.lua', -- Adaptador de quilometragem server-side (edite para trocar o sistema)
    'server/vin_bridge.lua',     -- Gerador de VIN/Chassi (edite para trocar o sistema de MDT)
    'server/main.lua'
}

ui_page 'html/index.html'

files {
    'locales/*.json',
    'html/index.html',
    'html/assets/*'
}

lua54 'yes'
use_experimental_fxv2_oal 'yes'