# zyke_laptop_stickdrop

Part of the [zyke_laptop app templates](../README.md) for [zyke_laptop](https://zykeresources.com/package/laptop), an
in-game laptop for FiveM servers.

An example of the data stick exports, with no app or page: a dead drop. A console command gives a player a data stick
with orders and a code. The player plugs it into a laptop, finds the code, writes it into a new `answer.txt` on the
stick and saves. The server reads it, answers with `reply.txt` on the same stick, and renames the stick once the code is
right.

- `GiveDataStick(playerId, {label, files})` makes the stick and gives it; `WriteDataStickFile` adds a file once the
  serial is known.
- `zyke_laptop:DataStickChanged (serial, by)` reports the player's save (`by` is `"player"`).
- `GetDataStickFiles` reads the label, `ReadDataStickFile` the answer, `SetDataStickLabel` renames.
- The code is derived from the serial and a secret, so the resource keeps no state and old sticks still work after a
  restart.

## Install

Needs `zyke_lib` and `zyke_laptop` with the data stick item set up (`Config.Settings.ports.dataStick`). Add
`ensure zyke_laptop_stickdrop` after both, and change `secret` in `config.lua`.

```
stickdrop_give <playerId>
```

The console prints the stick's serial and code, for testing.

## Files to read first

| File | What it does |
| --- | --- |
| `server.lua` | The command, the code and the check of the returned file |
| `config.lua` | The stick labels and the secret |
| `locales/en.lua` | The text written into the files on the stick |

## Making it your own

Hand the stick out from your own code instead of the command, and replace the `print` with your payout, the next heist
step or a mail (`exports.zyke_laptop:SendMail`). What a player writes on a stick is client input: read only what you
need, as this example does with the digits.
