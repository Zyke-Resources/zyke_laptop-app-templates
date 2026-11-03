# zyke_laptop_tictactoe

Part of the [zyke_laptop app templates](../README.md) for [zyke_laptop](https://zykeresources.com/package/laptop), an
in-game laptop for FiveM servers.

An example app: **Tic-tac-toe** between two laptops, with a scoreboard that can be cast to a TV, monitor or projector.

- **Rooms.** Both players join the same table name with `Laptop.rooms.join(name)`. The `rooms` field in `server.lua`
  allows two per table and names each player in its `join` function, which the other sees in `room.members`. A move is
  `room.send({type: "move", cell})`, received as a `message` event.
- **Cast.** "Show on a screen" calls `Laptop.cast.start(snapshot)`, and every change sends `Laptop.cast.snapshot(...)`.
  `checkSnapshot` in `server.lua` keeps only known fields and adds the text; what it returns is what every viewer sees.
  The screen shows `web/cast.html`, which draws on `LaptopCast.on("snapshot", ...)`.

The server only relays the moves, so the two pages decide the game. Fine for fun; anything that pays out has to be
decided on the server.

## Install

Needs `zyke_lib` and `zyke_laptop`. Add `ensure zyke_laptop_tictactoe` after both. The app is preinstalled. Rooms need
the laptop online (Wi-Fi, a phone hotspot or Zykelink) unless `Config.Sdk.rooms.requireNetwork` is off in zyke_laptop.

To play, open it on two laptops, enter the same table name and press Join. The player whose member id sorts first plays
X, and the players take turns starting.

## Files to read first

| File | What it does |
| --- | --- |
| `server.lua` | Registers the app with `rooms` and `cast`, the join function and the snapshot check |
| `client.lua` | Gives the page its text |
| `web/app.js` | The lobby, the game, the room messages and casting |
| `web/cast.html`, `web/cast.js`, `web/cast.css` | The scoreboard a world screen shows |
| `web/mock.js` | Answers `sdk:rooms.join` in a normal browser, so you see the lobby and a waiting table. Moves and casting need two laptops in game. |
| `locales/en.lua` | Every piece of text, also the scoreboard's, which `server.lua` puts in the snapshot |

## Making it your own

1. Rename the folder and change the app's `id` in `server.lua`.
2. Room names are letters, digits, `_` and `-`, 48 at most, and per app.
3. Keep the cast page still ([styling.md](../docs/styling.md#cast-viewer-pages)). Run images through
   `IsCastImageAllowed(url)` and text through `ToCastText(text, max)` in your snapshot check.
