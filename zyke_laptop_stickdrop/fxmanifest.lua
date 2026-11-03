fx_version "cerulean"
game "gta5"
lua54 "yes"
use_experimental_fxv2_oal "yes"
author "https://discord.zykeresources.com"
description "Example for zyke_laptop's data stick exports: hands out a stick with files and checks the file a player writes back"
version "1.0.0"

shared_scripts {
    "@zyke_lib/imports.lua",
}

server_scripts {
    "config.lua",
    "server.lua",
}

files {
    "locales/*.lua",
}

-- zyke_laptop is left out on purpose: a dependency would stop this resource whenever the laptop restarts
dependencies {
    "zyke_lib",
}