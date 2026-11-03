fx_version "cerulean"
game "gta5"
lua54 "yes"
use_experimental_fxv2_oal "yes"
author "https://discord.zykeresources.com"
description "Example zyke_laptop app: Fleeca Banking, with the bank balance, transfers between players and a transaction history"
version "1.0.0"

shared_scripts {
    "@zyke_lib/imports.lua",
    "config.lua",
    "shared/money.lua",
}

client_scripts {
    "client/app.lua",
}

server_scripts {
    "@oxmysql/lib/MySQL.lua",
    "server/register.lua",
    "server/database.lua",
    "server/bills.lua",
    "server/transfer.lua",
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