fx_version 'cerulean'
game 'rdr3'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
lua54 'yes'

author 'VORP @blue'
description 'A mining script for vorp core framework'
repository 'https://github.com/VORPCORE/vorp_mining'

shared_scripts {
  'config.lua',
  'translation.lua'   -- wichtig: muss vor client.lua geladen werden
}

client_scripts {
  'client.lua'
}

server_scripts {
  'server.lua'
}

dependencies {
  'syn_minigame'
}

version '1.2'
vorp_checker 'yes'
vorp_name '^4Resource version Check^3'
vorp_github 'https://github.com/VORPCORE/vorp_mining'
