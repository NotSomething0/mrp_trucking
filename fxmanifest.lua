fx_version 'cerulean'
game 'gta5'

lua54 'yes'
use_experimental_fxv2_oal 'yes'

shared_scripts {
  '@ox_lib/init.lua',
  '@ox_core/lib/init.lua',
  'shared/classes/*.lua',
  'shared/enums/*.lua',
  'shared/truckingConfig.lua',
  'shared/sh_util.lua'
}

client_script {
  'client/classes/*.lua',
  'client/cl_main.lua',
  'client/cl_depotPedManager.lua'
}

server_scripts {
  'server/classes/*.lua',
  'server/sv_*.lua'
}