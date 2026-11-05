fx_version "cerulean"
game "gta5"
lua54 "yes"
use_experimental_fxv2_oal "yes"
author "https://discord.zykeresources.com"
description "Example zyke_laptop app: Fleeca Banking, with transfers by phone number or name, payment requests, standing payments, saved payees, bills and a searchable history"
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
    "server/players.lua",
    "server/payees.lua",
    "server/recipients.lua",
    "server/ledger.lua",
    "server/history.lua",
    "server/requests.lua",
    "server/standing.lua",
    "server/bills.lua",
    "server/transfer.lua",
    "server/schedule.lua",
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