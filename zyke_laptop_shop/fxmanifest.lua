fx_version "cerulean"
game "gta5"
lua54 "yes"
use_experimental_fxv2_oal "yes"
author "https://discord.zykeresources.com"
description "Example zyke_laptop website: Corner Supply, a web shop paid through the laptop's pay sheet that gives the items on the server"
version "1.0.0"

shared_scripts {
    "@zyke_lib/imports.lua",
    "config.lua",
    "shared/products.lua",
}

client_scripts {
    "client.lua",
}

server_scripts {
    "@oxmysql/lib/MySQL.lua",
    "server/register.lua",
    "server/database.lua",
    "server/orders.lua",
}

files {
    "locales/*.lua",
    "web/**/*",
}

-- zyke_laptop is left out on purpose: a dependency would stop this resource whenever the laptop restarts
dependencies {
    "oxmysql",
    "zyke_lib",
}