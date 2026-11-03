fx_version "cerulean"
game "gta5"
lua54 "yes"
use_experimental_fxv2_oal "yes"
author "https://discord.zykeresources.com"
description "Starter zyke_laptop app built with Vite, React and TypeScript"
version "1.0.0"

shared_scripts {
    "@zyke_lib/imports.lua",
    "config.lua",
}

client_scripts {
    "client/app.lua",
}

server_scripts {
    "server/register.lua",
    "server/app.lua",
}

-- web/dist is what npm run build writes, the page's source in web/src is not sent to players
files {
    "locales/*.lua",
    "web/dist/**/*",
}

-- zyke_laptop is left out on purpose: a dependency would stop this resource whenever the laptop restarts
dependencies {
    "zyke_lib",
}