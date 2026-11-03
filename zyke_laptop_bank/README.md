# zyke_laptop_bank

Part of the [zyke_laptop app templates](../README.md) for [zyke_laptop](https://zykeresources.com/package/laptop), an
in-game laptop for FiveM servers.

An example app: **Fleeca Banking**. The bank balance and latest transactions, transfers to another player by server ID
with an optional note, and bills paid on the laptop's pay sheet.

## Install

Needs `zyke_lib`, `oxmysql` and `zyke_laptop`:

```cfg
ensure zyke_laptop
ensure zyke_laptop_bank
```

The app is preinstalled with a desktop shortcut.

## Files to read first

| File | What it does |
| --- | --- |
| `server/transfer.lua` | The checks and the money. Start here. |
| `server/bills.lua` | Bills: making the payment, and recording it once it settled. |
| `server/database.lua` | The `zyke_laptop_bank_transactions` table, made on start, and its two queries. |
| `server/register.lua` | Registers the app, again on `zyke_laptop:Ready`. |
| `client/app.lua` | Passes the page's posts on to the server and shows the notifications. |
| `web/app.js` | The page: loading the account, the form, and the refresh message. |
| `web/mock.js` | Made-up data for a normal browser. Never runs in game. |
| `config.lua` | Limits, cooldown, history length and the bills. |
| `locales/en.lua` | Every piece of text. `web:dateLocale` and `web:currency` set how the page writes dates and money. |

## How it works

- Transfers: the server checks again that the sender is at a laptop, the amount is a whole number within the limits,
  the recipient is someone else and online with a character, and the balance covers it. A short per-player cooldown
  stops a double click sending twice.
- The money moves with `Z.money`, and the balances are read back to make sure it did. If the recipient's side fails,
  the sender gets the money back.
- The recipient gets an OS notification, and their open app refreshes through `SendAppMessage`. Without the laptop out
  they get the framework's notification. The sender's confirmation is the OS notification and the new balance.
- Sounds: the notifications use the OS's send and receive sounds (`sound` in `Notify`), a refused transfer plays
  `Laptop.sound.play("error")`, and a sent transfer plays a keypad sound nearby players hear (`PlayAppSound`).
- Bills: the server makes the payment with `CreatePayment`, the page shows it with `Laptop.pay`. The bill counts as paid
  in `zyke_laptop:PaymentSettled`, which writes it to the history and calls `MarkPaymentFulfilled`. Payments settled
  while the resource was stopped are swept on start and on `zyke_laptop:Ready`, in batches until none are left. The
  payment id is a unique column, so a bill handled twice is still one row. A bill can be paid once every
  `Config.billPeriodDays`.

## Making it your own

1. Rename the folder, change `appId` in `config.lua`, and the `label` and `icon` in `server/register.lua`.
2. Rename the callbacks and the event (`zyke_laptop_bank:...`) and the table in `server/database.lua`, so two copies
   never meet.
3. For a banking resource zyke_lib doesn't support yet, add it to zyke_lib and keep the `Z.money` calls, rather than
   calling its exports here. If it keeps its own history, read that in `buildAccount` instead of `TransactionDb`.

## In a browser

See [Developing in a normal browser](../docs/getting-started.md#developing-in-a-normal-browser). Open
`zyke_laptop_bank/web/index.html`; fix the SDK path at the top of `mock.js` if your zyke_laptop sits elsewhere. Server
ID 2 is the only "online" player, and `Laptop.mock("sdk:pay.show")` confirms every payment.
