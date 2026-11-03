# zyke_laptop_react_template

Part of the [zyke_laptop app templates](../README.md) for [zyke_laptop](https://zykeresources.com/package/laptop), an
in-game laptop for FiveM servers.

A starter app, "My React App", whose page is a Vite + React + TypeScript project using the SDK's hooks
([sdk.md](../docs/sdk.md#react-hooks)).

## Install

Needs zyke_laptop and zyke_lib, and Node.js 20.19 or newer with npm on the machine that builds the page (tested with
Node 24.19.0 and npm 11.17.0).

Build the page before the resource starts. `web/dist/` is the build output and is not in the repository.

```sh
cd zyke_laptop_react_template/web
npm install
npm run build
```

```cfg
ensure zyke_laptop
ensure zyke_laptop_react_template
```

The app is preinstalled. Remove `preinstalled = true` in `server/register.lua` to offer it in the app store instead;
until a player gets it there, the OS drops notifications that name the app's `appId`.

After a change to the page, run `npm run build` again and restart the resource. Players only download `web/dist/`.

## Commands

Run these in `web/`:

| Command | What it does |
| --- | --- |
| `npm run dev` | Opens the page in a normal browser at http://localhost:5173 with hot reload |
| `npm run build` | Type checks and writes the page to `web/dist/` |
| `npm run typecheck` | Type checks only |

In `npm run dev`, `web/vite.config.ts` swaps the in-game SDK address for zyke_laptop's own `nui/sdk/laptop.js` (with the
OS fonts, under `/@zyke_laptop/nui/`); the build keeps the in-game address. It finds zyke_laptop next to this resource
or next to its category folder. Otherwise:

```sh
ZYKE_LAPTOP_PATH=/path/to/zyke_laptop npm run dev
```

`web/src/mock.ts` answers every endpoint with `Laptop.mock` in dev only. Add a mock for every NUI callback you add.

## Files to read first

| File | What it holds |
| --- | --- |
| `config.lua` | The app's id and icon, read on both sides |
| `server/register.lua` | Registers the app, again when the laptop restarts |
| `client/app.lua` | Sends the page its text, passes `GetServerInfo` and `Ping` on to the server, and turns the server's pong into a `Notify` and a `SendAppMessage` |
| `server/app.lua` | The server callbacks, each checking `IsAtLaptop` first |
| `web/src/App.tsx` | Loads the text and lays out the page |
| `web/src/components/` | One card per feature: `Header` (`useLaptopContext`), `NameCard` (`useLaptopState`), `ServerCard` (`laptopPost`), `MessageCard` (`useLaptopMessage`) |
| `web/src/mock.ts` | The browser-only answers |
| `web/src/laptop-react.ts`, `web/src/laptop.d.ts` | The SDK's React hooks and types, copies of `zyke_laptop/nui/sdk/` |
| `web/vite.config.ts` | Relative paths, the `chrome103` target and the dev server's SDK |

The page reads locale text with `t("key")`; it gets every key from the `Setup` callback.

`build.target` is `chrome103`, so Vite compiles newer JavaScript syntax down, but it adds no missing browser features
and fixes no CSS. See [styling.md](../docs/styling.md#in-game-limits) for what doesn't work in game.

## Making it your own

1. Rename the folder, for example to `my_notes`. The folder name is the resource name.
2. In `config.lua`, change `id` to one unique to your app and the `icon` (a [Lucide](https://lucide.dev/icons) name).
   The `category` and `window` size are in `server/register.lua`.
3. Change `app:name` and `app:description` in `locales/en.lua`, and the `<title>` in `web/index.html`.
4. Change `description` in `fxmanifest.lua` and `name` in `web/package.json`.
5. Replace the cards in `web/src/components/` with your own, and the endpoints in `client/app.lua`, `server/app.lua` and
   `web/src/mock.ts` with yours. Server callbacks and net events are named `ResName .. ":Name"`, so they follow the
   folder name.
6. Run `npm run build` and `ensure my_notes` after `ensure zyke_laptop`.
