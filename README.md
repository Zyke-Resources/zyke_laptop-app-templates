# zyke_laptop app templates

Templates, examples and the SDK reference for adding your own apps and websites to
[zyke_laptop](https://zykeresources.com/package/laptop), an in-game laptop for FiveM servers.

Each top-level folder is a working resource. Copy the one closest to what you want, rename it and build from there.

## Templates

| Resource | Start from it for |
| --- | --- |
| `zyke_laptop_app_template` | An app in plain HTML, CSS and JavaScript: registration with the optional access, price and permission fields, a server round trip, an OS notification, a message pushed from Lua and saved state. |
| `zyke_laptop_site_template` | A website with several pages, back and forward, and deep links. |
| `zyke_laptop_react_template` | An app in Vite, React and TypeScript, with the SDK's hooks and types. |

## Examples

| Resource | What it shows |
| --- | --- |
| `zyke_laptop_bank` | Fleeca Banking: transfers by phone number, name or server ID with a confirm step, payment requests, standing payments run by the server, saved payees, a filtered history with a monthly summary, and bills paid on the OS's pay sheet (`CreatePayment` and `Laptop.pay`). |
| `zyke_laptop_shop` | Corner Supply: selling inventory items. The server prices the order, the player pays on the pay sheet, the items are given when the payment settles or refunded when they can't be. |
| `zyke_laptop_garage` | My Vehicles: owned vehicles through zyke_lib, a search, and a GPS route to a vehicle that is out. |
| `zyke_laptop_notes` | Notes: its own `.note` file type, opened and saved through the OS's file chooser, with a badge for unsaved work. |
| `zyke_laptop_stickdrop` | A dead drop with no page: hand out a data stick with files and check the file the player writes back. |
| `zyke_laptop_tictactoe` | Realtime play between two laptops through rooms, with a scoreboard cast to world screens. |

More examples ship inside zyke_laptop, in `examples/`, each switched on or off in `shared/unlocked/examples.lua`. Their README says how to move one into a resource of its own.

| Folder | What it shows |
| --- | --- |
| `examples/police` | `lspd.gov`: an application form on a website, and an app only officers of a set grade get (`access` and `CanUseApp`). Start here for a job-only app. |
| `examples/mechanic` | `lscustoms.com`: a business site that reads its content from Lua and sets a GPS route to the nearest shop. |
| `examples/arcade` | Snake and 2048 as websites, with a leaderboard the server checks. |

## Docs

| File | What it covers |
| --- | --- |
| [`docs/getting-started.md`](docs/getting-started.md) | How apps and sites work, what a resource needs, developing in a browser, testing in game. |
| [`docs/sdk.md`](docs/sdk.md) | The JavaScript SDK, `window.Laptop`, and its React hooks. |
| [`docs/lua-api.md`](docs/lua-api.md) | The Lua exports and events: registration, access, payments, storage, data sticks, rooms, casting. |
| [`docs/styling.md`](docs/styling.md) | Matching the OS's look, and what the in-game browser can't do. |

`sdk/` holds `laptop.d.ts` (TypeScript types), `laptop-react.ts` (React hooks), both copies of `zyke_laptop/nui/sdk/`, and `zyke_laptop.lua` (LuaLS definitions of every export). `laptop.js` itself is always loaded from the laptop.

## Installation

1. Install [zyke_laptop](https://zykeresources.com/package/laptop) and its dependencies, `zyke_lib` and `oxmysql`.
2. Place this folder in your resources as `[zyke_laptop-app-templates]`, or copy only the resources you want.
3. `ensure` them after the laptop:

```cfg
ensure zyke_laptop
ensure zyke_laptop_app_template
ensure zyke_laptop_bank
```

The React template must be built first, see its README.

No resource lists zyke_laptop as a dependency, on purpose: restarting the laptop leaves them running, and they register again on the `zyke_laptop:Ready` server event.

## Links

- [zyke_laptop](https://zykeresources.com/package/laptop)
- [Discord](https://discord.zykeresources.com)
- [Documentation](https://docs.zykeresources.com/free-resources/laptop)
