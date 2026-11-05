# Terminal commands and programs

An app can add commands to the Terminal of every OS. Players run them like the built-in ones, `help` lists them under
the app's label, and Tab completes their names. There are two kinds:

- A **server command** is a Lua function on your server. It prints to the Terminal and asks the player questions while
  it runs, and every answer comes back to the server. Use it for anything that reads or changes server data.
- A **program** is a page of your resource that the Terminal runs in a hidden frame. It prints, asks and draws a
  full-screen view through `Laptop.terminal`, for a live tool or a game.

[`zyke_laptop_terminal_template`](../zyke_laptop_terminal_template) has one of each. zyke_laptop ships a bigger
example, Field Kit, in `examples/terminal`.

## Contents

- [Registering](#registering)
- [Terminal apps](#terminal-apps)
- [Text and tones](#text-and-tones)
- [Server commands](#server-commands)
- [Programs](#programs)
- [Limits and config](#limits-and-config)

## Registering

Commands go in the `terminal` field of [`RegisterApp`](lua-api.md#registerapp):

```lua
exports.zyke_laptop:RegisterApp({
    id = "my_tools",
    label = "My Tools",
    icon = "square-terminal",
    terminal = {
        launch = "stopwatch",          -- optional: what opening the app runs in the Terminal
        commands = {
            {
                name = "greet",
                usage = "greet [name]",
                description = "Say hello from the server",
                run = function(term, args)
                    term.print("Hello, " .. (args[1] or "you"), "success")
                end,
            },
            {name = "stopwatch", description = "A stopwatch", program = "web/stopwatch.html"},
        },
    },
})
```

| Field | Type | Meaning |
| --- | --- | --- |
| `launch` | `string` | Optional. A command line, 200 characters at most, that opening the app runs. It must start with one of the app's own commands. |
| `commands` | `table[]` | 32 at most. |
| `commands[].name` | `string` | Lower case letters, digits, `_` and `-`, starting with a letter, 32 at most. |
| `commands[].usage` | `string` | Optional, 80 characters at most. Shown by `help`; the name when left out. |
| `commands[].description` | `string` | Optional, 120 characters at most. Shown by `help`. |
| `commands[].run` | `function(term, args)` | A server command, see [Server commands](#server-commands). |
| `commands[].program` | `string` | A program: a page of your resource (`"web/game.html"`) or an `https://` address. |

Each command has exactly one of `run` and `program`. A command that breaks a rule is left out with a warning in the
server console, and the rest are registered. Refused names:

- The Terminal's own commands, on any OS: `help`, `ls`, `cd`, `cat`, `echo`, `clear`, `exit`, `top`, `ps`, `kill`,
  `curl`, `sudo`, `man`, `which`, the Windows ones such as `dir`, `cls` and `del`, the PowerShell aliases, and the shells
  (`sh`, `bash`, `zsh`, `pwsh`, `powershell`, `cmd`, `su`). The full list is in zyke_laptop's
  `server/locked/sdk/terminal.lua`.
- A name another started resource already registered. Prefix your names when they are generic.

Built-in commands always win, so an app can never replace one. Labels and descriptions are read on the server, so
`T("...")` gives the server's language.

## Terminal apps

An app with at least one valid command needs no `ui`. It is a terminal app: it shows in the app store, the menus, the
desktop and search like any other app, with its icon, `price`, `access` and `os`, and opening it runs `launch` in the
Terminal. Without `launch` it opens the Terminal with a line that lists the app's commands. The Terminal is one window,
so opening the app while the Terminal is open runs the line there.

An app with both `ui` and `terminal` opens its page as usual, and its commands work in the Terminal as well.

Access rules, licences and the server owner's `Config.Sdk.allowlist` apply to every command: a player who can't use
the app can't run its commands either.

## Text and tones

Everything printed takes the same text, in Lua and in JavaScript:

- a string; each `\n` starts a new line
- a segment, `{text, tone?, color?, bg?}`
- a list of segments and strings, which make one line

| Tone | Use |
| --- | --- |
| `dim` | Hints, labels, timestamps |
| `accent` | Values, highlights |
| `bold` | Headings |
| `success`, `warning`, `error` | Results |
| `path`, `user` | The colours the prompt uses for paths and the user name |

`color` and `bg` take `#rgb` or `#rrggbb` for exact colours. Unknown tones and colours are dropped, tabs become four
spaces and other control characters are removed.

```lua
term.print({{text = "Plate ", tone = "dim"}, {text = "ABC 123", tone = "accent"}, {text = " STOLEN ", color = "#fff", bg = "#c01c28"}})
```

## Server commands

`run(term, args)` runs in a thread of its own on the server. `args` are the words typed after the name. The session
ends when the function returns.

| Field | Meaning |
| --- | --- |
| `term.plyId` | The player's server ID. |
| `term.command`, `term.args` | The command's name and its arguments. |
| `term.cwd` | The directory the Terminal is in, as it shows it. |
| `term.os` | `"facade"`, `"lumen"`, `"solace"` or `"veil"`. |
| `term.cols`, `term.rows` | The window's size in characters when the command started. |
| `term.account` | The signed-in account, the shape of `Laptop.account()`: `kind`, `name`, `address` and `appUserId`. |

| Method | Meaning |
| --- | --- |
| `term.print(text, tone?)` | Prints a line or lines. The tone colours a plain string. Prints of one server tick reach the player together. |
| `term.status(text)` | One live line under the output, such as a progress bar. `term.status(nil)` clears it; it also goes when the command ends. |
| `term.clear()` | Clears the window. |
| `term.ask(prompt, {secret?, initial?})` | Waits for a typed line and returns it. `secret` hides the typing like a password prompt, `initial` fills the input. |
| `term.choose(prompt, options, {initial?})` | Shows a menu and returns the picked option's **1-based** index. Options are strings or `{label, hint?, disabled?}`; a disabled one is shown but can't be picked. 50 options at most. |
| `term.confirm(question, initial?)` | Asks for y or n and returns a boolean. An empty answer takes `initial` (false when left out). |
| `term.sleep(ms)` | Waits, and returns `false` when the session ended meanwhile. |
| `term.cancelled()` | `true` once the session ended. |

`ask`, `choose` and `confirm` yield and return `nil` when the player pressed Ctrl+C (or Escape in a menu), did not
answer within `askTimeout` seconds, or went away. A second question while one is open replaces it.

The session ends when the function returns, when it errors (the server console names your resource and the command,
and the player sees that the command failed), on Ctrl+C, when the Terminal window closes or the laptop powers off,
when the player leaves, and when your resource stops or registers the app again without that command. After the end
every call does nothing and questions return `nil` at once, so a long command checks what `ask` and `sleep` return
and stops there:

```lua
run = function(term, args)
    local plate = args[1] or term.ask("Plate: ")
    if (not plate) then return end

    for step = 0, 10 do
        term.status({{text = "Searching ", tone = "dim"}, {text = ("#"):rep(step) .. ("."):rep(10 - step), tone = "accent"}})

        if (not term.sleep(150)) then return end
    end

    term.status(nil)

    local kind = term.choose("Look up", {"Owner", {label = "Insurance", hint = "fleet only"}, {label = "Warrants", disabled = true}})
    if (not kind) then return end

    term.print("Owner    Alex Sample", "dim")

    if (term.confirm("Save to the report?", true)) then term.print("Saved.", "success") end
end,
```

The arguments and answers are the player's own typing. Check them like any client input before you use or store them,
and read everything else on the server.

## Programs

A program page loads the SDK like every page and reaches the Terminal through `Laptop.terminal`:

```html
<script src="https://cfx-nui-zyke_laptop/nui/sdk/laptop.js"></script>
```

The page runs as the app, so it keeps the app's other features: `Laptop.storage` when the registration declares
`storage`, `Laptop.post` to your own NUI callbacks for its text, `Laptop.rooms`, `Laptop.pay` and so on. It runs in a
hidden frame that is never on screen, so animate with `setInterval` or `setTimeout`, not `requestAnimationFrame`.

| Member | Meaning |
| --- | --- |
| `active` | `true` only in a page the Terminal runs. Elsewhere every call rejects with `unsupported`. |
| `command`, `args`, `cwd` | The command's name, its arguments and the Terminal's directory. |
| `size` | `{cols, rows}`, kept current. |
| `print(text, tone?)`, `status(text \| null)`, `clear()` | As on the server. |
| `ask(prompt, {secret?, initial?})` | Resolves with the typed line, or `null` for Ctrl+C. |
| `choose(prompt, options, {initial?})` | Resolves with the picked option's **0-based** index, or `null` for Escape or Ctrl+C. |
| `confirm(question, initial?)` | Resolves with a boolean, or `null` for Ctrl+C. |
| `screen.open({captureCtrlC?})` | Covers the scrollback with a grid and resolves with `{cols, rows}`. |
| `screen.draw(rows)` | Replaces the whole frame, one text per row. Rows past the bottom are dropped, each row is cut at `cols` and a short row is padded. Calls closer than 16 ms apart send only the newest frame. |
| `screen.close()`, `screen.isOpen` | Back to the scrollback, which shows what it held before. |
| `onKey(handler)` | Every key while the screen is open, as `{key, code, ctrl, alt, shift}`. Returns a function that stops listening. |
| `onResize(handler)` | The new `{cols, rows}` when the window or the font size changes. |
| `onCancel(handler)` | Ctrl+C, or the window closing. |
| `exit()` | Ends the program; the Terminal removes the page and shows its prompt. |

Ctrl+C ends a program. On a screen opened with `captureCtrlC: true` it reaches `onKey` instead, like any other key,
and the program decides; outside the screen it always ends the program. `onCancel` handlers run first, and the page has
about 300 ms before its frame goes, enough to stop timers or send one last request. The program also ends when its
window closes, when its page fails to load, and when the app goes away, such as its resource stopping.

```js
(async () => {
    const term = Laptop.terminal;

    await Laptop.ready();

    const level = await term.choose("Speed", ["Relaxed", "Normal", { label: "Fast", hint: "good luck" }], { initial: 1 });
    if (level === null) return term.exit();

    let size = await term.screen.open();
    let x = 0;

    const draw = () => term.screen.draw([[{ text: " MY GAME ", bg: "#1c71d8", color: "#fff" }, { text: "  q quits", tone: "dim" }], " ".repeat(x) + "@"]);

    term.onKey((key) => {
        if (key.key === "q") {
            term.screen.close();
            term.print("Bye!", "success");

            return term.exit();
        }

        if (key.key === "ArrowRight") x = Math.min(size.cols - 1, x + 1);
        if (key.key === "ArrowLeft") x = Math.max(0, x - 1);

        draw();
    });

    term.onResize((next) => {
        size = next;
        draw();
    });

    draw();
})();
```

The types are in [`sdk/laptop.d.ts`](../sdk/laptop.d.ts) as `ZykeLaptop.TerminalApi`. A program can't be tried in a
normal browser on its own, since it needs the Terminal; test it in game, or in zyke_laptop's dev mock as its
`examples/README.md` describes.

## Limits and config

The server owner sets these in `Config.Sdk.terminal` in zyke_laptop's `shared/unlocked/sdk.lua`:

| Key | Default | Meaning |
| --- | --- | --- |
| `enabled` | `true` | Turns terminal commands of other resources on or off. Off, a `terminal` field is left out with a warning. |
| `maxSessions` | `3` | Server commands one player may have running at once. One more answers `busy`. |
| `askTimeout` | `300` | Seconds a question waits before it returns `nil`. |
| `maxOutputLines` | `2000` | Lines one run of a server command may print. After that the output is dropped and one warning line is printed. |
| `rate` | `{count = 5, rate = 1}` | How fast one player may start server commands: a burst of `count`, then `rate` a second. |

Fixed limits: 32 commands per app, 64 arguments of 512 characters, answers of 1000 characters, 200 lines per print,
2000 characters per segment.

`laptop_sdk_check` lists each app's commands and the warnings their registration printed, and `laptop_sdk_health`
counts the live sessions and the commands that errored.