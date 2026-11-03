# zyke_laptop_notes

Part of the [zyke_laptop app templates](../README.md) for [zyke_laptop](https://zykeresources.com/package/laptop), an
in-game laptop for FiveM servers.

An example app: **Notes**, a text editor that keeps its notes as `.note` files. It has no server code beyond the
registration.

- `documents` in the registration gives the app the `.note` type. Opening one in Files opens Notes with it in
  `Laptop.context.files`, or the `filesOpened` event when Notes is already open.
- Open, Save and Save as use `Laptop.files.open({types})` and `Laptop.files.save({suggestedName, content, types})`;
  `Laptop.files.write(handle, content)` saves again without asking. Notes can go in Documents, Persistent on Veil, or a
  data stick.
- `Laptop.badge(1)` while a note has unsaved changes, `Laptop.badge(0)` after.
- `Laptop.saveState` keeps the draft while the laptop sleeps.
- The file buttons turn off when `Laptop.can("files")` is false.

## Install

Needs `zyke_lib` and `zyke_laptop`. Add `ensure zyke_laptop_notes` after both. Notes is preinstalled.

## Files to read first

| File | What it does |
| --- | --- |
| `server.lua` | Registers the app with its `.note` document type, again on `zyke_laptop:Ready` |
| `client.lua` | Gives the page its text |
| `web/app.js` | The editor: open, save, save as, the badge and the saved draft |
| `web/mock.js` | Stands in for the OS's files and badge in a normal browser (`Laptop.mock("sdk:files.open", ...)` and others), ignored in game |
| `locales/en.lua` | Every piece of text |

## Making it your own

1. Rename the folder, and change the app's `id` in `server.lua`.
2. Pick your own extension in `documents` and in `types()` in `web/app.js`, one no other resource uses. Files are text,
   64 KiB at most by default (`Config.Sdk.files.maxFileBytes` in zyke_laptop).
3. Change `app:name`, `app:description` and `file:type` in `locales/en.lua`.

File content comes from the player's laptop: treat it as client input if it ever reaches your server.
