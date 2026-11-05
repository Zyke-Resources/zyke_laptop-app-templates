# Lua API

Call the exports as `exports.zyke_laptop:Name(...)`. They only exist while zyke_laptop runs, so code that may run
before it checks first:

```lua
if (GetResourceState("zyke_laptop") ~= "started") then return end
```

[`sdk/zyke_laptop.lua`](../sdk/zyke_laptop.lua) declares every export with its LuaDoc for LuaLS. Add it to
`workspace.library` in your `.luarc.json` and type the exports where you use them:

```lua
local laptop = exports.zyke_laptop --[[@as ZykeLaptopServerExports]]
```

## Contents

Registering (server):

- [How registration works](#how-registration-works)
- [RegisterApp](#registerapp), [RegisterSite](#registersite), [UnregisterApp and UnregisterSite](#unregisterapp-and-unregistersite)
- [SDK fields](#sdk-fields): [access](#access), [price](#price), [permissions](#permissions), [storage](#storage),
  [payments](#payments), [rooms](#rooms), [cast](#cast), [terminal](#terminal)

Server:

- [IsAtLaptop](#isatlaptop), [CanUseApp](#canuseapp), [GetLaptopAccount](#getlaptopaccount)
- [Payment exports](#payment-exports), [Storage exports](#storage-exports), [Data stick exports](#data-stick-exports),
  [Room exports](#room-exports), [Cast helpers](#cast-helpers), [Licences](#licences)
- [IsConnected](#isconnected-server), [GetLaptopNetwork](#getlaptopnetwork),
  [GetLaptopOs and GetLaptopSerial](#getlaptopos-and-getlaptopserial), [PlayAppSound](#playappsound)
- [Server events](#server-events)

Client:

- [SendAppMessage and SendSiteMessage](#sendappmessage-and-sendsitemessage), [SetAppBadge](#setappbadge)
- [OpenApp](#openapp), [OpenUrl](#openurl), [Notify](#notify), [AddBookmark](#addbookmark)
- [IsScreenOpen, IsConnected, GetActivity](#isscreenopen-isconnected-getactivity)
- [Client events](#client-events)

[Developer tools](#developer-tools), [Other exports](#other-exports)

## How registration works

- Register on the server, with one table that holds what the OS shows and what the server allows the page.
- The laptop forgets every registration when it restarts and fires the **server** event `zyke_laptop:Ready` once it is
  back. Register in its handler, and right away when the laptop already runs. See
  [getting-started.md](getting-started.md#registering) for the code.
- Everything a resource registered is removed when it stops, and its open app windows close. They stay closed after it
  starts again, unless `Config.Sdk.dev.hotReload` is on (see [Developer tools](#developer-tools)).
- Registering an id your resource already registered replaces it; that is how you update an app after your config
  changed. An id another running resource registered is refused.
- A refused registration returns `false` and a reason, and prints a warning. Fields that are wrong but not fatal are left
  out with a warning, and the rest is registered.
- To give an app to some players only, use [`access`](#access). Never register per player.
- Labels and descriptions are read on the server, so `T("...")` uses the server's language, and the locale files must
  be under `files` in the manifest.

## RegisterApp

Server.

```lua
local registered, err = exports.zyke_laptop:RegisterApp(app)
```

`err` is `"invalid"` or `"taken"`. `app` holds the fields below plus any of the [SDK fields](#sdk-fields):

| Field | Type | Default | Meaning |
| --- | --- | --- | --- |
| `id` | `string` | required | Unique app id: letters, digits, `_` and `-`, 64 at most. |
| `label` | `string` | required | Name shown in the app store, the menus and as the window title. |
| `ui` | `string` | required, unless `terminal` has a command | The page. A path inside your resource (`"web/index.html"`, a leading `/` is dropped) becomes `https://cfx-nui-<resource>/web/index.html`. An `https://` address is used as it is. Any other scheme is refused. |
| `icon` | `string` | `"box"` | A [Lucide](https://lucide.dev/icons) icon name in kebab-case, such as `"shield-check"`, or an image URL. An image must be a full URL such as `https://cfx-nui-my_resource/web/icon.png`; unlike `ui`, a path is not resolved. |
| `category` | `string` | `"other"` | `"accessories"`, `"internet"`, `"office"`, `"system"`, `"utilities"` or `"other"`. Unknown values become `"other"`. |
| `description` | `string` | none | Shown on the app's page in the store. |
| `window` | `LaptopWindowOptions` | see below | Size and behaviour of the window. |
| `favorite` | `boolean` | `false` | Listed under Favorites in the Applications menu. |
| `requiresConnection` | `boolean` | `false` | Shows a "connect first" screen instead of the app while the Onion network is not connected. |
| `singleInstance` | `boolean` | `true` | Opening the app again focuses the open window instead of opening a second one. |
| `desktop` | `boolean` | `true` | Puts a shortcut on the desktop the first time an account gets the app. |
| `preinstalled` | `boolean` | `false` | Installs the app for each account the first time it sees it, instead of offering it in the app store. |
| `os` | `string[]` | every OS | Limits the app to some OSes: `"facade"`, `"lumen"`, `"solace"`, `"veil"`. Unknown ids are dropped with a warning; a list left with no known OS refuses the registration, so a typo does not put the app on every OS. |
| `documents` | `LaptopAppDocument[]` | none | File types the app owns, 8 at most, see below. |

Registered apps never show in the recovery toolkit's session.

### LaptopWindowOptions

| Field | Type | Default | Meaning |
| --- | --- | --- | --- |
| `width` | `integer` | `760` | Width in pixels of a new window. |
| `height` | `integer` | `540` | Height in pixels of a new window. |
| `minWidth` | `integer` | `200` | Smallest width the player can resize to. |
| `minHeight` | `integer` | `120` | Smallest height. |
| `resizable` | `boolean` | `true` | `false` keeps the window at `width` x `height`. |
| `maximized` | `boolean` | `false` | Opens maximized. |
| `chrome` | `"default" \| "none"` | `"default"` | `"none"` is for built-in apps only; on a registered app it is dropped with a warning. |

A new window never takes more than 94% of the screen's work area. The first window of an app opens where the player
last left that app's window, so `width` and `height` mostly matter the first time.

### LaptopAppDocument

A file type the app owns. Opening one in Files opens the app with it in `Laptop.context.files`, or the `filesOpened`
event when it is open already. See [`zyke_laptop_notes`](../zyke_laptop_notes).

| Field | Type | Meaning |
| --- | --- | --- |
| `extension` | `string` | Required. Lower case letters and digits without the dot, 8 at most, such as `"note"`. |
| `label` | `string` | Required, 40 characters at most, such as `"Note"`. |
| `icon` | `string` | Lucide icon name. |
| `color` | `string` | `"#rrggbb"`. |

The OS keeps the extensions it opens itself or a built-in app owns (`txt`, `md`, `json`, `png`, `mp3`, `zip`, `key`,
`draw`, `deck` and others), and an extension another running resource claimed first stays with that resource. Both are
left out with a warning.

### Refusals

`RegisterApp` returns `false, "invalid"` when the `id` is not letters, digits, `_` and `-` up to 64, belongs to a
built-in app (`connection`, `browser`, `settings`, `terminal`, `hacking`, `editor`, `files`, `calculator`, `chat`,
`messenger`, `mail`, `store`, `crypto`, `mdt`, `racks`, `devicemanager`, `viewer`, `paint`, `slides` or `recovery`),
`label` or `ui` is missing, `ui` has a scheme other than `https://`, `os` lists no known OS, or `access` or `price` is
bad (so a typo never opens a job app to everyone or makes a paid app free). It returns `false, "taken"` when another
running resource registered the same id. Other bad fields are left out with a warning.

## RegisterSite

Server.

```lua
local registered, err = exports.zyke_laptop:RegisterSite(site)
```

`site` holds the fields below plus any of the [SDK fields](#sdk-fields) except `cast` and `price`:

| Field | Type | Default | Meaning |
| --- | --- | --- | --- |
| `id` | `string` | required | Unique site id, the same rules as an app id. |
| `url` | `string` | required | The address typed into the address bar, such as `"myshop.com"` or `"market5xq...onion"`. |
| `title` | `string` | required | The site's name in search, the directory and the tab. |
| `ui` | `string` | required | The page, resolved like an app's `ui`. |
| `description` | `string` | none | Shown in search results and the directory. |
| `keywords` | `string[]` | none | Words search matches without showing them. |
| `icon` | `string` | none | Icon in search and the directory. |
| `listed` | `boolean` | `true` | `false` keeps the site out of the directory and search; players reach it only by its address. |
| `category` | `string` | none | Section of LS Pages, or of the Onion Directory for an onion site: `"government"`, `"services"`, `"business"`, `"shopping"`, `"finance"`, `"news"`, `"community"`, `"games"`, `"search"` or `"other"`. An unknown value is listed under `"other"` with a warning. |
| `network` | `"clearnet" \| "onion"` | from the address | Which network reaches the site. Left out, `.onion` addresses are `"onion"` and the rest `"clearnet"`. |
| `monitored` | `boolean` | `false` | Visits are recorded as traces when the server's browsing config records monitored sites (`browsing.record = "monitored"`). |

An onion site needs the Onion network connected; on Veil every site does.

The `url` is stored lower case without scheme or trailing slashes (`"HTTPS://MyShop.com/"` becomes `"myshop.com"`).
Players can't register a registered site's host as a domain of their own.

`RegisterSite` refuses with `"invalid"` like `RegisterApp` (a bad id, a missing `url`, `title` or `ui`, a `ui` scheme
other than `https://`) and with `"taken"` when another running resource registered the same id or the same address.

## UnregisterApp and UnregisterSite

Server.

```lua
exports.zyke_laptop:UnregisterApp(appId)
exports.zyke_laptop:UnregisterSite(siteId)
```

Removes an app or site your resource registered. Rarely needed: entries go when your resource stops, and who sees an
app is decided by [`access`](#access).

## SDK fields

Fields of the same `RegisterApp` or `RegisterSite` table that decide what the server allows the page. The server
owner can turn each feature off, or limit it to some resources, with `Config.Sdk` in zyke_laptop's
`shared/unlocked/sdk.lua`.

### access

Who sees the app or site at all.

```lua
access = {
    jobs = {police = 2, sheriff = 0},   -- job to lowest grade, or {"police", "sheriff"} for any grade
    onDuty = true,                      -- with jobs: only while on duty
    items = {"police_badge"},           -- carries any of them
    ace = {"zyke_laptop.app.mdt_tools"},-- a string or a list
    any = false,                        -- true: one passing rule is enough, false: every listed rule must pass
},
```

A refused player doesn't see the app anywhere, and a site shows the browser's "can't reach" page. Every SDK call of
the page is checked against it. The app appears and goes at once as the job changes; items and ACE are checked again
within a few seconds on the next call. Losing access closes the open windows with a notification.

Your own NUI and server callbacks are not SDK calls: check [`CanUseApp`](#canuseapp) in them. Register again when the
config the rule is built from changes. A rule `access` can't express goes in your callbacks, next to `CanUseApp`, with
the closest `access` rule as the outer limit.

### price

```lua
price = {amount = 2500, currency = "either", payee = "society:fleeca"},
```

Apps only. Buying in the store runs the OS's pay sheet. `currency` is `"bank"`, `"crypto"` or `"either"`; `payee` is `"server"` (the default, the money leaves the
economy) or `"society:<name>"`. Until it is bought the app counts as not installed, and `CanUseApp` and every SDK call
answer `notLicensed`. A licence belongs to the account (Nimbus or local) by default; the server owner can make it the
character's. Leave `preinstalled` out on a paid app. See [Licences](#licences).

### permissions

```lua
permissions = {"account", "clipboard"},
```

What the app may ask the player for. The first `Laptop.account()` or `Laptop.clipboard.readText()` asks, and the
answer is kept per account (Settings → Privacy). `"job"`
adds the job to `Laptop.account()` while the server shares jobs. Notifications need no declaration. On Veil the account
and clipboard are refused without asking by default.

### storage

```lua
storage = true,                 -- the server's default, 32 KiB per app
storage = {maxBytes = 65536},   -- or a size of your own, capped by the server's config
```

Turns on `Laptop.storage` for the page. Without this field the page has no storage and `Laptop.can("storage")` is
`false`. See [Storage exports](#storage-exports).

### payments

```lua
payments = {payees = {"server", "society:fleeca"}},
```

The payees your [`CreatePayment`](#payment-exports) calls may name: an exact payee, or a kind such as `"society"` for
every society. Left out, every kind the server allows. Payments themselves need no field.

### rooms

```lua
rooms = {
    maxMembers = 2,
    messageBytes = 256,
    rate = {count = 20, rate = 10},            -- optional: one member sends a burst of count, then rate a second
    join = function(source, room, data)
        return true, {name = GetPlayerName(source)}
    end,
},
```

Turns on `Laptop.rooms` for the page. `maxMembers` and `messageBytes` are capped by the server's config (`Config.Sdk.rooms`).
`join` is optional: it runs on every join with the player, the room's name and what the page passed, and returns
whether they may join plus the member data everyone in the room sees, such as a name. `rooms = true` takes the
defaults. See [`zyke_laptop_tictactoe`](../zyke_laptop_tictactoe).

### cast

```lua
cast = {
    ui = "web/cast.html",                       -- the viewer page, a page of this resource
    snapshot = function(content) return {balance = tonumber(content.balance) or 0} end,
    delta = function(delta) return delta end,  -- optional, left out drops deltas
    signal = function(signal) return nil end,  -- optional, nil drops the message
},
```

Apps only. Turns on `Laptop.cast`. The window sends content, not pixels: your function checks each
`Laptop.cast.snapshot(content)`, and what it returns is what every viewer sees. Return plain values, and run images through [`IsCastImageAllowed`](#cast-helpers) and text
through `ToCastText`. The viewer page loads `https://cfx-nui-zyke_laptop/nui/sdk/laptop-cast.js`, see
[sdk.md](sdk.md#the-cast-viewer-page).

### terminal

```lua
terminal = {
    launch = "stopwatch",                       -- optional: what opening the app runs in the Terminal
    commands = {
        {name = "greet", usage = "greet [name]", description = "Say hello", run = function(term, args) end},
        {name = "stopwatch", description = "A stopwatch", program = "web/stopwatch.html"},
    },
},
```

Apps only. Adds commands to the Terminal: `run` is a server command that gets a session to print and ask questions
through, `program` a page the Terminal runs in a hidden frame that draws through `Laptop.terminal`. An app with a valid
command needs no `ui`; opening it runs `launch` in the Terminal. See [terminal.md](terminal.md).

## IsAtLaptop

Server.

```lua
exports.zyke_laptop:IsAtLaptop(plyId) -- returns boolean atLaptop
```

True while the player holds a laptop, or stands at a placed laptop or computer (theirs or anyone's), and is not
blocked from using laptops. Check it at the top of every server callback your page reaches.

It does not mean your app is open or the screen is on. A player who opened the OS through the client `OpenScreen` export (a screen without a laptop prop) is
not at a laptop by this check.

## CanUseApp

Server.

```lua
local allowed, code = exports.zyke_laptop:CanUseApp(plyId, appId)
local allowed, code = exports.zyke_laptop:CanUseApp(plyId, siteId, "site")
```

The same check the SDK runs on its own calls: the app is registered, the player passes its [`access`](#access) rule,
and owns a licence when it has a [`price`](#price). `code` is `"notRegistered"`, `"noAccess"` or `"notLicensed"`. Use it
next to `IsAtLaptop` in your own callbacks, which the SDK does not check:

```lua
if (not exports.zyke_laptop:CanUseApp(plyId, "my_app")) then return {ok = false, error = "noAccess"} end
```

## GetLaptopAccount

Server.

```lua
local account = exports.zyke_laptop:GetLaptopAccount(plyId, appId?, kind?)
```

The account the player's laptop is signed in to, `nil` while they use none: `kind` (`"nimbus"`, `"local"`, `"guest"`
or `"live"` on Veil and other USB boots), `name`, `address` (the Nimbus address or `nil`), `os`, and `appUserId`, an id
stable per account and app, for an app or site your resource registered. The page reads the same with
`Laptop.account()`, but only this server read is proof.

## Payment exports

Server. The amount is always decided on the server:

```
your server: CreatePayment(source, {...})       -> paymentId
your page:   Laptop.pay(paymentId)              -> the OS's pay sheet, the player confirms
laptop:      takes the money, pays the payee    -> zyke_laptop:PaymentSettled (payment)
your server: delivers the order                 -> MarkPaymentFulfilled(paymentId)
your page:   the promise resolves               -> {paymentId, status = "settled", method, amount, coin?}
```

```lua
local paymentId, err = exports.zyke_laptop:CreatePayment(source, {
    app = "fleeca_bank",
    kind = "app",                     -- "site" for a site's payment
    amount = 2500,                    -- whole dollars
    currency = "either",              -- "bank" (the default), "crypto" or "either"
    label = "Premium plan, 1 month",
    lines = {{label = "Premium plan", qty = 1, amount = 2500}}, -- each line's amount is its total, the lines add up to amount
    payee = "society:fleeca",         -- "server" (the default) or "society:<name>"
    reference = "order-123",
    idempotencyKey = "order-123",     -- the same key returns the same payment until it is cancelled, expires or fails, 64 characters at most
    expiresIn = 300,                  -- seconds, 30 to 3600
    metadata = {plan = "premium"},
})

AddEventHandler("zyke_laptop:PaymentSettled", function(payment)
    if (payment.resource ~= GetCurrentResourceName()) then return end

    -- deliver payment.metadata.plan to payment.identifier
    exports.zyke_laptop:MarkPaymentFulfilled(payment.id)
end)
```

`err` is `"invalid"`, `"notRegistered"`, `"payeeNotAllowed"`, `"conflict"` (the key was used for another payment) or
`"disabled"`. A `"player:<identifier>"` payee is off unless the server owner allows it.

Deliver in `PaymentSettled`, never when the page's promise resolves: the page can close, and only the server event is
certain. When your resource starts, and on `zyke_laptop:Ready` in case the laptop started after it, deliver what was
paid while it was down. `GetPayments` returns 100 at most and a fulfilled payment drops out, so ask again until a call
brings nothing new:

```lua
local function deliverWaiting()
    local seen = {}

    while (true) do
        local fresh = 0

        for _, payment in ipairs(exports.zyke_laptop:GetPayments({status = "settled", fulfilled = false})) do
            if (not seen[payment.id]) then
                seen[payment.id] = true
                fresh += 1
                -- deliver, then
                exports.zyke_laptop:MarkPaymentFulfilled(payment.id)
            end
        end

        if (fresh == 0) then return end
    end
end
```

Make delivering safe to run twice for one payment: the settle event and this sweep can meet, and a stop between
delivering and `MarkPaymentFulfilled` delivers again on the next start. Record the payment id with what you delivered,
as [`zyke_laptop_bank`](../zyke_laptop_bank) does with a unique column, or claim the order in your own table first, as
[`zyke_laptop_shop`](../zyke_laptop_shop) does. A delivery that must wait, such as items for a player who is offline,
leaves the payment unfulfilled and keeps coming back in this list, so keep such orders in your own table instead.

| Export | Returns | Meaning |
| --- | --- | --- |
| `GetPayment(paymentId)` | `SdkPayment?` | One of your resource's payments. |
| `GetPayments({status?, fulfilled?, identifier?, since?, limit?})` | `SdkPayment[]` | Your resource's payments, newest first, 100 at most. `since` is unix seconds. |
| `MarkPaymentFulfilled(paymentId)` | `boolean` | You delivered it. |
| `CancelPayment(paymentId)` | `boolean` | Only while it is pending, such as when the order sold out. |
| `RefundPayment(paymentId, {amount?, reason?})` | `boolean, err?` | Takes the money back from a society payee first (`"payeeFunds"` when it can't cover it) and pays the player back in what they paid with. A player who is offline gets it when they join next. `err` is also `"notFound"`, `"invalid"` or `"failed"`. |

A payment has `id`, `resource`, `app`, `identifier` (the character who pays), `label`, `amount`, `currency`, `method`
(`"bank"` or `"crypto"` once paid), `coin`, `payee`, `status` (`"pending"`, `"settling"`, `"settled"`, `"cancelled"`,
`"expired"`, `"failed"` or `"review"`), `refunded`, `fulfilled`, `lines`, `metadata`, `createdAt`, `expiresAt` and
`settledAt`. A payment the server stopped in the middle of, such as during a crash, is left in `"review"` for staff to
check by hand. See [`zyke_laptop_bank`](../zyke_laptop_bank) for a complete flow, and [`zyke_laptop_shop`](../zyke_laptop_shop) for
selling items, with refunds for an order that can't be given.

## Storage exports

Server. The data a page keeps with `Laptop.storage`, for the same app:

```lua
local settings = exports.zyke_laptop:GetAppStorage(target, appId, key?, kind?)
local saved, err = exports.zyke_laptop:SetAppStorage(target, appId, key, value, kind?)
```

`target` is a player (their current account) or an owner key such as `"nimbus:<identifier>"`. Without `key`,
`GetAppStorage` returns every key. `value` `nil` removes the key. `err` is `"invalid"`, `"tooLarge"` (8 KiB a key),
`"quota"` or `"notRegistered"`. What a page stored is client input: check it like anything else from a client.

## Data stick exports

Server. Make data sticks with files and read what players put on them:

```lua
local serial, err = exports.zyke_laptop:GiveDataStick(source, {
    label = "VAULT_PLANS",
    files = {{path = "plans/vault.txt", content = "Door A opens at 03:00"}},
})

AddEventHandler("zyke_laptop:DataStickChanged", function(serial, by)
    if (by ~= "player") then return end

    local content = exports.zyke_laptop:ReadDataStickFile(serial, "found/codes.txt")
end)
```

| Export | Returns |
| --- | --- |
| `GiveDataStick(plyId, {label?, files?})` | `serial?, err?`. `err` is also `"noSpace"` when the inventory refused the item. |
| `CreateDataStick(options)` | `serial?, metadata?, err?`: the stick and its item metadata, without giving the item. |
| `GetDataStickFiles(serial)` | `{path, kind, size, modified}[]?, label?` |
| `ReadDataStickFile(serial, path)` | `content?, err?` (`"invalid"`, `"notFound"`, `"disabled"`) |
| `WriteDataStickFile(serial, path, content, {overwrite?, kind?})` | `written, err?` (`"invalid"`, `"exists"`, `"full"`, `"disabled"`) |
| `DeleteDataStickFile(serial, path)` | `deleted, err?` |
| `FindDataStickFiles(serial, pattern, {plain?})` | `string[]` paths matching a Lua pattern |
| `SetDataStickLabel(serial, label)` | `labelled, err?` |
| `DataStickExists(serial)` | `boolean` |

Files are text; `kind = "key"` makes a key file. A write checks the stick's size, and open laptops with the stick
plugged in load it again. `zyke_laptop:DataStickChanged` fires with `by` `"player"` when a player saved on the stick,
or the writing resource's name. What a player writes is client input. See [`zyke_laptop_stickdrop`](../zyke_laptop_stickdrop).

## Room exports

Server, for an app or site with a [`rooms`](#rooms) field:

| Export | Meaning |
| --- | --- |
| `SendRoomMessage(appId, room, data, toPlyId?)` | Sends to everyone in the room, or one player; the pages get it with `from` `"server"`. |
| `GetRoomMembers(appId, room)` | `{plyId, memberId, data?}[]` |
| `KickFromRoom(appId, room, plyId)` | The page gets `close` with `"kicked"`. |
| `CloseRoom(appId, room)` | Everyone gets `close` with `"closed"`. |

The server event `zyke_laptop:RoomEvent (appId, room, "join" | "leave", plyId, data)` follows joins and leaves.

## Cast helpers

Server, for your [`cast`](#cast) functions:

```lua
exports.zyke_laptop:IsCastImageAllowed(url) -- true for an image every viewer's game may load
exports.zyke_laptop:ToCastText(value, maxLength) -- text cut to a length, nil when it is not usable text
```

An image from any other host would tell that host who looked at the screen, so pass only images this allows.

## Licences

Server, for a paid app (see [`price`](#price)):

```lua
exports.zyke_laptop:HasAppLicence(plyId, appId) -- true for a free app
exports.zyke_laptop:GrantAppLicence(target, appId) -- such as for a promotion
exports.zyke_laptop:RevokeAppLicence(target, appId)
```

`target` is a player or an owner key. A refunded store purchase takes the licence back by itself.

## IsConnected (server)

```lua
exports.zyke_laptop:IsConnected(plyId) -- returns boolean connected
```

Server. Whether the player's laptop says it is connected to the Onion network. The client reports this, so never
gate anything that pays out on it.

## GetLaptopNetwork

```lua
exports.zyke_laptop:GetLaptopNetwork(plyId) -- returns LaptopNetwork? network
```

Server. The internet connection the player's laptop is online through, checked again when you ask. `nil` when the
player has no laptop on screen, or it is offline, or on a Zykelink plan with no time left.

| Field | Type | Meaning |
| --- | --- | --- |
| `kind` | `"phone" \| "hotspot" \| "zykelink"` | Tethered to the phone, a Wi-Fi hotspot on the map, or Zykelink satellite internet. |
| `id` | `string` | The hotspot's id, `"phone"` for the phone, `"zykelink"` for Zykelink. |
| `ssid` | `string` | The network name. |
| `coords` | `vector3` | Where the traffic comes from: the hotspot, or the player for the phone. |

## GetLaptopOs and GetLaptopSerial

```lua
exports.zyke_laptop:GetLaptopOs(plyId) -- "facade" | "lumen" | "solace" | "veil" | nil
exports.zyke_laptop:GetLaptopSerial(plyId) -- string? serial
```

Server. The OS the player runs right now (`"veil"` from a USB stick, otherwise the one installed), and the serial of
the laptop it runs on, to tie data to one laptop rather than the player. Both are `nil` while the player's OS is off.

## PlayAppSound

Server.

```lua
exports.zyke_laptop:PlayAppSound(plyId, name) -- returns boolean played
```

Plays a world sound at the player's ped that everyone near them hears, for something physical your app does:
`"keypad"` for a PIN or card step, `"plug"` for a cable, `"notice"` for a small notice tone and `"cardReader"` for a
card reader's approval beep.

It only works for a resource that registered an app or site, while the player's laptop is on. Each player gets a few
sounds at a time, and the same sound in the same area plays once a second, whoever asks. Returns `false` for an
unknown name, no laptop on or a spent budget. The sound files and how far they carry are the `sdk*` entries in
zyke_laptop's `shared/unlocked/sounds.lua`.

```lua
if (pinAccepted) then exports.zyke_laptop:PlayAppSound(plyId, "cardReader") end
```

## Server events

`AddEventHandler` on the server:

| Event | Arguments | When |
| --- | --- | --- |
| `zyke_laptop:Ready` | none | The laptop started (or restarted) and placed laptops are back. Register your apps and sites. |
| `zyke_laptop:PaymentSettled` | `payment` | A payment was paid. Deliver, then `MarkPaymentFulfilled`. Check `payment.resource`. |
| `zyke_laptop:PaymentFailed` | `payment, code` | A payment could not be settled. |
| `zyke_laptop:PaymentRefunded` | `payment, amount, reason` | Money went back to the player. |
| `zyke_laptop:DataStickChanged` | `serial, by` | Files on a stick changed, `by` is `"player"` or a resource. |
| `zyke_laptop:RoomEvent` | `appId, room, "join" \| "leave", plyId, data` | Someone joined or left a room of an app. |
| `zyke_laptop:NetworkChanged` | `plyId, network?` | `GetLaptopNetwork` changed. |

## SendAppMessage and SendSiteMessage

Client.

```lua
exports.zyke_laptop:SendAppMessage(appId, data) -- returns boolean delivered
exports.zyke_laptop:SendSiteMessage(siteId, data) -- returns boolean delivered
```

Sends `data` to every open window of the app, or every open tab of the site, on this client. The page receives it as a
`message` event:

```js
Laptop.on("message", (data) => {
    if (data.refresh) loadData();
});
```

`data` must survive JSON. To reach a player's page from the server, trigger your own client event and call them
there:

```lua
-- client
RegisterNetEvent("my_resource:Refresh", function()
    if (GetResourceState("zyke_laptop") ~= "started") then return end

    exports.zyke_laptop:SendSiteMessage("my_shop", {refresh = true})
end)
```

`delivered` is `false` when no OS is running on this client; the message is dropped then, not kept. `true` means it
was sent to the OS, not that a page of yours was open to receive it.

## SetAppBadge

Client.

```lua
exports.zyke_laptop:SetAppBadge(appId, count)
```

Puts a count on the app's icon, `0` hides it. The page does the same with `Laptop.badge(count)`.

## OpenApp

Client.

```lua
exports.zyke_laptop:OpenApp(appId, params) -- returns boolean delivered
```

Opens an app, built-in or registered, and passes `params` (optional table) to its window, readable in the page's
`context.params`. An open single-instance app is focused, and gets the new params when you pass some. An app the player
has not installed opens its page in the app store. Returns `false` when no OS runs.

## OpenUrl

Client.

```lua
exports.zyke_laptop:OpenUrl(url) -- returns boolean delivered
```

Opens the address in the OS's browser. Returns `false` when no OS runs.

## Notify

Client.

```lua
exports.zyke_laptop:Notify(notification) -- returns boolean delivered
```

Shows an OS notification. `notification` is a `LaptopNotification`:

| Field | Type | Meaning |
| --- | --- | --- |
| `title` | `string` | Required. Without it nothing is sent and the export returns `false`. |
| `text` | `string` | Body text. |
| `icon` | `string` | Lucide icon name or image URL. |
| `appId` | `string` | App that opens when the notification is clicked. A notification for an app the player has not installed is dropped by the OS. |
| `params` | `table` | Passed to `appId` when it opens. |
| `url` | `string` | Address opened in the browser when clicked. Checked before `appId`. |
| `duration` | `integer` | Milliseconds the banner shows. Left out, the OS's default (5000, or 6000 on Facade). |
| `id` | `string` | A notification with the same id is replaced. |
| `actions` | `{id, label}[]` | Up to two buttons. A click fires the client event `zyke_laptop:NotificationAction`. |
| `data` | any | JSON of 1 KiB at most, handed back with an action. |
| `sound` | `string \| false` | Played instead of the chime: `"click"`, `"send"`, `"receive"`, `"success"`, `"error"` or `"notification"`. `false` shows the banner silently. |

With Do Not Disturb on, the notification only goes to the list. It only chimes while the laptop's screen is open; one
that arrives with the laptop closed shows silently in the list. Returns `false` when no OS runs.

```lua
exports.zyke_laptop:Notify({title = "My Shop", text = "Your order is ready", icon = "package", url = "myshop.com"})
```

Don't show a toast in the page that repeats the notification ([styling.md](styling.md#ux-rules)). The OS is not
certain to drop a notification for an app the player may not use, so for an app with an `access` rule check the job on
the client before sending.

## AddBookmark

Client.

```lua
exports.zyke_laptop:AddBookmark(bookmark) -- returns boolean kept
```

Gives the player a bookmark, shared by every OS's browser.

| Field | Type | Meaning |
| --- | --- | --- |
| `id` | `string` | Required, unique within your resource. The browser adds each id once, so calling again is harmless. |
| `url` | `string` | Required. |
| `title` | `string` | Optional. |
| `force` | `boolean` | Adds it again even if the player deleted it, for a player asking for the address again. |

The bookmark waits on the client (through relogs) until a browser saved it, so one given while no OS runs reaches the
next one that boots. At most 50 wait; the oldest are dropped first. Returns `false` only when `id` or `url` is missing.

## IsScreenOpen, IsConnected, GetActivity

Client.

```lua
exports.zyke_laptop:IsScreenOpen() -- boolean: the laptop's screen is open on this client
exports.zyke_laptop:IsConnected() -- boolean: the OS is connected to the Onion network
exports.zyke_laptop:GetActivity() -- string?: what the player is doing with a laptop
```

`GetActivity` returns `nil` when the player is not using a laptop, or one of `"holding"`, `"using"`, `"screen"`,
`"ports"`, `"servicing"`, `"placing"`, `"racking"`.

## Client events

Local events (`AddEventHandler`) the laptop raises on the client:

| Event | Arguments | When |
| --- | --- | --- |
| `zyke_laptop:ScreenOpened` | `mode` | The screen opened. |
| `zyke_laptop:ScreenClosed` | none | The screen closed. |
| `zyke_laptop:AppOpened` | `appId` | The first window of an app opened. |
| `zyke_laptop:AppClosed` | `appId` | The last window of an app closed. |
| `zyke_laptop:ConnectionChanged` | `connected` | The Onion network connected or disconnected. |
| `zyke_laptop:ActivityChanged` | `activity?` | `GetActivity()` changed. |
| `zyke_laptop:NotificationAction` | `resource, notificationId, actionId, data` | The player clicked a button of a notification sent with `Notify`. Check `resource`. |

`zyke_laptop:Ready` is a server event only; there is no client registration.

## Developer tools

`laptop_sdk_check`, `laptop_sdk_health`, `laptop_sdk_reload` and `Config.Sdk.dev.hotReload`: see
[getting-started.md](getting-started.md#developer-tools).

## Other exports

Documented in zyke_laptop's `README.md`, the [online documentation](https://docs.zykeresources.com/free-resources/laptop) and [`sdk/zyke_laptop.lua`](../sdk/zyke_laptop.lua):

| Family | Examples | Where |
| --- | --- | --- |
| Mail | `SendMail`, `CreateMailbox`, `GetMailAddress`, `OpenMail` | README, "Mail" |
| Messenger (Natter) | `SendMessengerMessage`, `RegisterMessengerBusiness`, `GetMessengerNumber`, `OpenMessenger` | Online documentation and `sdk/zyke_laptop.lua` |
| Shroud chat | `RegisterChatRoom`, `RegisterChatContact`, `SendChatMessage`, `OpenChat` | Online documentation and `sdk/zyke_laptop.lua` |
| Crypto | `GiveCrypto`, `ChargeCrypto`, `GetCryptoBalance`, `GetCryptoPrice` | README, "Crypto" |
| Domains and providers | `RegisterDomainProvider`, `GetDomain`, `GrantDomain`, `IsDomainOwner` | README, "Domains" |
| Sitewright blocks | `RegisterSiteBlock`, `RefreshSiteBlock` | README, "Live data blocks" |
| Racks | `RegisterRackWorkload`, `GetRacks`, `SetRackShare` | README, "Laptop racks" |
| MDT | `CreateMdtCall`, `SendMdtAlert`, `RegisterMdtWeapon` | README, "MDT" |
| Hacking | `RequestHack`, `StartHack`, `CancelHack` | README, "Intrusion toolkit" |
| Hardware and devices | `GetLaptopHardware`, `RegisterDeviceType`, `PlugDevice` | Online documentation and `sdk/zyke_laptop.lua` |
