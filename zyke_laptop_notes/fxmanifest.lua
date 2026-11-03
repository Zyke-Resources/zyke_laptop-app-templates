fx_version "cerulean"
game "gta5"
lua54 "yes"
use_experimental_fxv2_oal "yes"
author "https://discord.zykeresources.com"
description "Example zyke_laptop app: Notes, a document app with its own .note files, opened and saved through the OS"
version "1.0.0"

shared_scripts {
    "@zyke_lib/imports.lua",
}

client_scripts {
    "client.lua",
}

server_scripts {
    "server.lua",
}

files {
    "locales/*.lua",
    "web/**/*",
}

-- zyke_laptop is left out on purpose: a dependency would stop this resource whenever the laptop restarts
dependencies {
    "zyke_lib",
}