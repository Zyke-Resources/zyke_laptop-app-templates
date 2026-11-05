# zyke_laptop_bank

Part of the [zyke_laptop app templates](../README.md) for [zyke_laptop](https://zykeresources.com/package/laptop), an
in-game laptop for FiveM servers.

An example app: **Fleeca Banking**, a complete banking app.

- **Send money** by phone number, full name or server ID, or to a saved payee. The player sees the recipient's name on
  a confirm step before anything moves.
- **Request money** from someone. They see it in their app, with a notification when they are online, and pay or
  decline it. The requester sees each request's status and can withdraw an open one. Requests expire after a week.
- **Standing payments**: the same amount to the same person every N days. The server pays them on a timer, on start
  and when the payer's character is selected. One the balance can't cover is stopped, with a line in the history and a
  notification, and the player can cancel one at any time.
- **Saved payees**, added on their own or from the confirm step, and picked in every form.
- **History**: filter by money in or out and by kind (transfers, requests, standing payments, bills), search names and
  notes, page through it, and a month by month summary of money in and out. The overview shows this month with a bar
  per month.
- **Bills** paid on the laptop's pay sheet.

## Install

Needs `zyke_lib`, `oxmysql` and `zyke_laptop`:

```cfg
ensure zyke_laptop
ensure zyke_laptop_bank
```

The app is preinstalled with a desktop shortcut. The tables are made on start.

## Files to read first

| File | What it does |
| --- | --- |
| `server/transfer.lua` | The account overview and transfers. Start here. |
| `server/players.lua` | `GetSender`, the check every callback starts with, plus cooldowns, amount and note checks and notifications. |
| `server/recipients.lua` | Finding the recipient by phone number, name, server ID or saved payee, and the confirm-step check. |
| `server/ledger.lua` | The only place money moves, and the money held for offline recipients. |
| `server/requests.lua` | Payment requests: asking, paying, declining, withdrawing and expiring. |
| `server/standing.lua` | Standing payments and the code that pays them. |
| `server/schedule.lua` | The timer and the character selection that run standing payments, expiry and held money. |
| `server/payees.lua` | Saved payees. |
| `server/history.lua` | Pages of the history with its filters. |
| `server/bills.lua` | Bills: making the payment, and recording it once it settled. |
| `server/database.lua` | The tables, made on start, and the history queries. |
| `server/register.lua` | Registers the app, again on `zyke_laptop:Ready`. |
| `client/app.lua` | Passes the page's posts on to the server and shows the notifications. |
| `web/js/app.js` | The page: loads the strings and the account, then the views. |
| `web/js/flow.js`, `web/js/picker.js` | The fill in, then confirm steps every form shares, and the recipient picker. |
| `web/js/*.js` | One file per tab (`overview`, `send`, `requests`, `standing`, `payees`, `history`), plus `bills`, `transactions`, `fields`, `store`, `nav` and `util`. |
| `web/css/base.css`, `web/css/views.css` | The page and its controls, and the layout of each tab. |
| `web/mock.js` | Made-up data for a normal browser. Never runs in game. |
| `config.lua` | Limits, cooldowns, offline recipients, requests, standing payments and the bills. |
| `locales/en.lua` | Every piece of text. `web:dateLocale` and `web:currency` set how the page writes dates and money. |

## How it works

- **The server decides.** Every callback checks `IsAtLaptop` through `GetSender`, and reads the amount, note, interval
  and recipient again. The page never sends an identifier or a total: recipients are looked up on the server, payees
  and requests are sent back by their row id and checked against the player's own rows.
- **Recipients.** A phone number goes through `Z.getPhoneNumberOwner`, which also finds offline owners where the phone
  resource allows it. A name must be the exact first and last name; two characters with that name are refused, and the
  player is asked for the phone number instead. A server ID only finds players in the city. Lookups have their own
  short cooldown so numbers and names can't be guessed in bulk. The confirmed send looks the recipient up again and is
  refused when that now finds someone with another name, such as a server ID that changed hands.
- **Money** moves only in `Ledger.move`, with `Z.money` on the server. The payer's balance is checked and the
  removal's answer read, and the recipient's balance is read back after the add; when the add didn't arrive, the payer
  gets the money back. `Z.money` only reaches characters who are online, so money for an offline recipient goes to
  `zyke_laptop_bank_held` and is paid out when they are next in, with a notification. `Config.offlineRecipients = false`
  refuses offline recipients instead.
- **Requests and standing payments** change their status with an `UPDATE ... WHERE status = <old status>` first, so two
  clicks, or a payer and a withdrawing requester at once, can't both win. A standing payment is claimed by moving its
  due time on before the money moves. A payer who was away while payments fell due pays once when back, not once per
  missed period.
- **Notifications** come from the server as one `zyke_laptop_bank:Notify` event with a locale key, shown as an OS
  notification (or the framework's while the laptop isn't out) and refreshing the open app through `SendAppMessage`.
  Request notifications open the app on the Requests tab. The app icon carries a badge with the open requests.
- **Sounds**: the notifications use the OS's send and receive sounds, a refused action plays
  `Laptop.sound.play("error")`, and a sent transfer or paid request plays a keypad sound nearby players hear
  (`PlayAppSound`).
- **Bills**: the server makes the payment with `CreatePayment`, the page shows it with `Laptop.pay`. The bill counts as
  paid in `zyke_laptop:PaymentSettled`, which writes it to the history and calls `MarkPaymentFulfilled`. Payments
  settled while the resource was stopped are swept on start and on `zyke_laptop:Ready`, in batches until none are left.
  The payment id is a unique column, so a bill handled twice is still one row. A bill can be paid once every
  `Config.billPeriodDays`.
- **The page** is plain HTML, CSS and JavaScript modules with no build step. Buttons that move money or remove
  something ask again on the first click instead of a dialog, and the forms use button rows instead of `<select>`
  lists, which don't open on the laptop's screen.

## Making it your own

1. Rename the folder, change `appId` in `config.lua`, and the `label` and `icon` in `server/register.lua`.
2. Rename the callbacks and the events (`zyke_laptop_bank:...`) and the `zyke_laptop_bank_*` tables in
   `server/database.lua`, so two copies never meet.
3. For a banking resource zyke_lib doesn't support yet, add it to zyke_lib and keep the `Z.money` calls, rather than
   calling its exports here. If it keeps its own history, read that in `TransactionDb` instead.

## In a browser

See [Developing in a normal browser](../docs/getting-started.md#developing-in-a-normal-browser). Open
`zyke_laptop_bank/web/index.html`; fix the SDK path at the top of `mock.js` if your zyke_laptop sits elsewhere. Sam
Reed is online (phone 555-0142, server ID 2) and Jamie Cole is away (phone 555-0199), so money to Jamie shows as held.
`Laptop.mock("sdk:pay.show")` confirms every payment.
