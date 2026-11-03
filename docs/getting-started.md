# Getting started

Other resources add apps and websites to zyke_laptop's OS (Facade, Lumen, Solace or Veil, modelled on Windows, Ubuntu,
macOS and Tails). Your page is an HTML page served from your own resource and shown inside the OS in an iframe.

- [sdk.md](sdk.md): the JavaScript SDK, `window.Laptop`.
- [lua-api.md](lua-api.md): the Lua exports.
- [styling.md](styling.md): matching the OS's look, and the in-game browser's limits.

## App or website

| | App | Website |
| --- | --- | --- |
| Registered with | `exports.zyke_laptop:RegisterApp`, on the server | `exports.zyke_laptop:RegisterSite`, on the server |
| Shown as | A window with the OS's title bar | A tab in the OS's browser, at an address such as `lscustoms.com` |
| How the player gets it | The laptop's app store, or installed at once with `preinstalled = true` | Its address, search and the directory (LS Pages, or the Onion Directory for onion sites), a link or a bookmark |
| Who sees it | Everyone, or only players its `access` rule lets through (jobs, items, ACE) | The same |

A resource can register both, such as a public academy site and an app for officers that reviews the applications.

## What a resource needs

```
my_resource/
    fxmanifest.lua
    server.lua          registers the app or site, does the real work, checks every request
    client.lua          answers the page's NUI callbacks
    locales/en.lua      player-facing text
    web/index.html      the page
    web/app.js
    web/mock.js         answers the page's requests in a normal browser
```

zyke_lib picks `locales/<language>.lua` from its own language setting and falls back to `en.lua`. To add a language,
copy `en.lua` (for example to `de.lua`) and translate the values; keep the keys.

### fxmanifest.lua

```lua
fx_version "cerulean"
game "gta5"
lua54 "yes"
use_experimental_fxv2_oal "yes"
author "Your name"
description "My shop website for zyke_laptop"
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
```

The page files and the locale files (zyke_lib reads them on both sides) must be under `files`. Do not list
`zyke_laptop` as a dependency. Start your resource after it:

```cfg
ensure zyke_laptop
ensure my_resource
```

### Registering

Register from a **server** script. The laptop forgets every registration when it restarts and fires the server event
`zyke_laptop:Ready` once it is back, so register in that handler and also right away in case the laptop already runs:

```lua
-- server.lua
local function register()
    exports.zyke_laptop:RegisterSite({
        id = "my_shop",
        url = "myshop.com",
        title = "My Shop",
        ui = "web/index.html",
        category = "shopping",
    })
end

-- The laptop drops every registration when it restarts and fires this server event once it is back
AddEventHandler("zyke_laptop:Ready", register)

-- This resource started after the laptop, so Ready has already fired
if (GetResourceState("zyke_laptop") == "started") then register() end
```

`ui` is a path inside your resource; it becomes `https://cfx-nui-my_resource/web/index.html`. Ids are letters, digits,
`_` and `-`. Your apps and sites are removed when your resource stops.

For an app only some players should have, add an `access` rule instead of deciding on the client:

```lua
exports.zyke_laptop:RegisterApp({
    id = "my_mdt",
    label = "My MDT",
    ui = "web/index.html",
    access = {jobs = {police = 0, sheriff = 0}},   -- job to lowest grade
})
```

See [lua-api.md](lua-api.md#registerapp) for every field, including `price`, `permissions`, `storage`, `rooms` and
`cast`.

### The page

Load the SDK from zyke_laptop before your own script:

```html
<script src="https://cfx-nui-zyke_laptop/nui/sdk/laptop.js"></script>
<script src="app.js"></script>
```

```js
Laptop.ready().then((context) => {
    document.title = context.kind === "app" ? "My App" : "My Shop";
});
```

The SDK sets the OS's look as CSS variables ([styling.md](styling.md)) and gives the page these features, each through
the OS's own UI:

| Feature | What it does | Example |
| --- | --- | --- |
| `Laptop.files` and `documents` | The OS's file chooser, and file types your app owns | `zyke_laptop_notes` |
| `Laptop.pay` | The OS's pay sheet for a payment your server made with `CreatePayment` | `zyke_laptop_bank` |
| `Laptop.storage` | Data kept per account on the server, the same on every laptop | |
| `Laptop.rooms` | Realtime messages between laptops | `zyke_laptop_tictactoe` |
| `Laptop.cast` | Your own viewer page on TVs, monitors and projectors in the world | `zyke_laptop_tictactoe` |
| `Laptop.account`, `badge`, `share`, `clipboard`, notification buttons | The signed-in account, a count on your icon, the share sheet, copy and paste | |
| Data stick exports (server) | Hand out and read sticks with files | `zyke_laptop_stickdrop` |

`Laptop.can("pay")` tells the page whether a feature works where it runs. See [sdk.md](sdk.md).

## How a request travels

The page never talks to the server directly:

```
page            Laptop.post("BuyItem", { item: "water" })
  |
client          RegisterNUICallback("BuyItem", function(data, cb) ... end)
  |               cb(Z.callback.request("my_resource:BuyItem", nil, data))
  |
server          Z.callback.register("my_resource:BuyItem", function(source, data) ... end)
```

NUI callbacks belong to one resource, so short names like `BuyItem` are fine. Server callbacks and net events are
global, so prefix them with your resource name.

Client:

```lua
---@param data {item: string}
---@param cb fun(result: {ok: boolean, error?: string})
RegisterNUICallback("BuyItem", function(data, cb)
    cb(Z.callback.request("my_resource:BuyItem", nil, data) or {ok = false, error = "unavailable"})
end)
```

Server:

```lua
---@param plyId integer
---@param data {item: string}
---@return {ok: boolean, error?: string} result
Z.callback.register("my_resource:BuyItem", function(plyId, data)
    -- Anyone can send this callback without a laptop, so check the player is at one
    if (not exports.zyke_laptop:IsAtLaptop(plyId)) then return {ok = false, error = "notAtLaptop"} end
    if (type(data) ~= "table" or type(data.item) ~= "string") then return {ok = false, error = "invalid"} end

    -- Look the price up on the server, take the money, give the item
    return {ok = true}
end)
```

Always call `cb`, also on errors: `Laptop.post` has no timeout and waits until `cb` is called.

### The server trusts nothing from the page

A player can call your NUI and server callbacks without ever opening the laptop. On the server:

- Check `exports.zyke_laptop:IsAtLaptop(source)` in every callback.
- Check `exports.zyke_laptop:CanUseApp(source, appId)` in the callbacks of an app with an `access` rule or a price. The
  laptop checks its own SDK calls, not your callbacks. Check ownership and anything else `access` can't express too.
- Check every value's type and range. Prices, amounts and item names come from your server config, never the page.
- Do all money, item and database work on the server.

## Developing in a normal browser

Most of a page can be built in a desktop browser without touching the game.

1. Serve the folder that holds your resources over HTTP, for example `python3 -m http.server` run in it.
2. `https://cfx-nui-zyke_laptop/...` only loads in game. Have a small loader try it and fall back to a local copy of
   `zyke_laptop/nui/sdk/laptop.js`, as the templates' `mock.js` does.
3. Answer every `Laptop.post` endpoint with `Laptop.mock(name, handler)`, usually from a `mock.js`. Mocks are never
   used in game.
4. Answer the SDK's own calls with `"sdk:<feature>.<op>"`, such as `"sdk:pay.show"` or `"sdk:files.open"`. Without a
   mock they reject with `unsupported`.

```js
Laptop.mock("GetShop", () => ({ ok: true, items: [{ name: "water", label: "Water", price: 5 }] }));
Laptop.mock("BuyItem", (data) => ({ ok: data.item === "water" }));

// Stands in for the OS's pay sheet, which only exists in game
Laptop.mock("sdk:pay.show", ({ paymentId }) => ({ paymentId, status: "settled", method: "bank", amount: 50 }));
```

Outside the laptop, `Laptop.ready()` resolves with Veil's dark look and no capabilities, and calls that need the
laptop, such as `Laptop.notify`, reject. See [sdk.md](sdk.md#in-game-embedded-and-standalone).

## Testing in game

After editing a page or a Lua file, restart your resource. Its app or site is gone while it is stopped and comes back
when it starts. zyke_laptop does not need a restart.

### Developer tools

Server console commands, also in F8 for players with the ACE in zyke_laptop's `Config.Sdk.dev.permission`:

- `Config.Sdk.dev.hotReload = true` (zyke_laptop's `shared/unlocked/sdk.lua`): restarting your resource keeps its
  windows open, and the pages reload with their `saveState`. `laptop_sdk_reload [resource]` reloads the pages without
  a restart.
- `laptop_sdk_check [resource]`: your registrations and the warnings they printed (fields left out and why), pages
  and cast pages that are not files of your resource, apps without an icon, payees the config refuses and unknown
  access jobs. Run it after every change to the registration.
- `laptop_sdk_health [resource]`: payments waiting or in review, settled payments not fulfilled after 10 minutes,
  storage use, live rooms and casts, and errors and refusals in the last hour.

[`sdk/zyke_laptop.lua`](../sdk/zyke_laptop.lua) declares every export for LuaLS, so your editor knows the
registration's fields.

Check in game:

- The app shows in the app store (or on the desktop when preinstalled), or the site loads at its address.
- A full round trip: the page posts, the server answers, the page shows it.
- Restart your resource, and then zyke_laptop, while the laptop is open: the app or site comes back both times.
- With an `access` rule: a player without the job doesn't get the app, gets it when given the job, and its server
  callbacks refuse them.
- With payments: a paid order is delivered once, also when your resource restarted between paying and delivering.

## Copying a template

Pick a folder from the [README](../README.md). Each folder's README lists what to rename: at least the folder, the app
or site id, the address, the callback and event prefixes, and any database table, so two copies never collide.
