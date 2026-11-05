# zyke_laptop_terminal_template

Part of the [zyke_laptop app templates](../README.md) for [zyke_laptop](https://zykeresources.com/package/laptop), an
in-game laptop for FiveM servers.

A minimal terminal app to copy and rename: "My Tools", id `template_terminal`. It has no window; it adds two commands
to the Terminal of every OS, and opening the app runs `stopwatch` in the Terminal.

- **`greet [name]`**, a server command. It asks for a name when none was typed, offers a menu of styles with a hint and
  a disabled option, counts down on a live status line, prints the greeting with the number of players online, and
  asks y/n whether to shout it too. Everything runs in `server.lua`.
- **`stopwatch`**, a program: `web/stopwatch.html`, which the Terminal runs in a hidden frame. It opens a full-screen
  view, draws the time and laps ten times a second, takes keys through `onKey`, follows the window's size through
  `onResize` and prints the result when it exits.

See [docs/terminal.md](../docs/terminal.md) for the whole API.

## Install

Needs `zyke_lib` and `zyke_laptop`. Add `ensure zyke_laptop_terminal_template` after both. "My Tools" is preinstalled.
Open a Terminal and type `help`: the two commands are listed under My Tools.

## Files to read first

| File | What it does |
| --- | --- |
| `server.lua` | `RegisterApp` with a `terminal` field and no `ui` (again on `zyke_laptop:Ready`), and `greet`, the server command |
| `client.lua` | Answers the program's `Setup` post with the locale text |
| `web/stopwatch.html`, `web/stopwatch.js` | The program, drawing through `Laptop.terminal.screen` |
| `locales/en.lua` | Every piece of text, for Lua (`T`) and for the page |

## Making it your own

1. Rename the folder, for example to `my_tools`. The folder name is the resource name.
2. Change the app's `id` (`template_terminal`) in `server.lua` to one unique across every resource.
3. Rename the commands. A name has to be free across every started resource and can't be one of the Terminal's own,
   so prefix generic ones. Keep `launch` starting with one of your commands, or leave it out.
4. Change `app:name` and `app:description` in `locales/en.lua`, and the `icon` and `category` in `server.lua`.
5. Add `ui` to the registration when the app also needs a window; the commands keep working in the Terminal.
6. Check every argument and answer a server command gets: they are the player's own typing.
