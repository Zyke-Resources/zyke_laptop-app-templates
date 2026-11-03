# zyke_laptop_app_template

Part of the [zyke_laptop app templates](../README.md) for [zyke_laptop](https://zykeresources.com/package/laptop), an
in-game laptop for FiveM servers.

A minimal app to copy and rename: "My App", id `template_app`, in plain HTML, CSS and JavaScript.

## Install

Needs `zyke_lib` and `zyke_laptop`. Add `ensure zyke_laptop_app_template` after both. "My App" is preinstalled. Remove
`preinstalled = true` in `server.lua` to offer it in the app store under Utilities instead; until a player gets it
there, the OS drops notifications that name the app.

To try the push, run `template_app_message <playerId> Hello` in the server console while the app is open.

## Files to read first

| File | What it does |
| --- | --- |
| `config.lua` | The app's id and icon, read on both sides |
| `server.lua` | `RegisterApp` (again on `zyke_laptop:Ready`) with the optional `access`, `price`, `permissions` and `storage` fields as comments; the `GetGreeting` callback, which checks `IsAtLaptop` and `CanUseApp`; the console command that pushes a message |
| `client.lua` | Answers the page's posts (`Setup` hands over the locale text), sends the notification with `Notify`, and passes pushed messages on with `SendAppMessage` |
| `web/app.js` | The page: setup, the round trip, `Laptop.on("message")`, the `theme` listener, `setTitle` and `saveState` |
| `web/style.css` | Styles built only from `--laptop-*` variables |
| `web/mock.js` | Answers `Setup`, `GetGreeting` and `Notify` in a normal browser, ignored in game |
| `locales/en.lua` | Every piece of text, for Lua (`T`) and for the page |

## Making it your own

1. Rename the folder, for example to `my_app`. The folder name is the resource name.
2. Change `id` in `config.lua` (`template_app`) to one unique across every resource.
3. Replace the callback and event prefix `zyke_laptop_app_template:` with your resource name in `client.lua` and
   `server.lua`. Rename or remove the console command `template_app_message`.
4. Change `app:name`, `app:description` and `title:withName` in `locales/en.lua`, the `icon` in `config.lua` (a
   [Lucide](https://lucide.dev/icons) name), and the `category` and window size in `server.lua`. Uncomment the optional
   fields you need there: `access` for a job app, `price` for a paid one.
5. If you move the page, update `ui = "web/index.html"` in `server.lua` and `files` in `fxmanifest.lua`.
6. An element with `data-text="key"` shows that locale key.

## In a browser

See [Developing in a normal browser](../docs/getting-started.md#developing-in-a-normal-browser). `web/mock.js` loads
zyke_laptop's `nui/sdk/laptop.js` from next to this resource or next to its category folder. Requests to the OS, such
as `setTitle`, notifications and messages, only work in game.
