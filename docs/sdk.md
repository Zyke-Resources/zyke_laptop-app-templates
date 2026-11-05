# JavaScript SDK

`window.Laptop` connects your page to the laptop it runs in, and to your own resource. Load it before your own script:

```html
<script src="https://cfx-nui-zyke_laptop/nui/sdk/laptop.js"></script>
```

Always load it from zyke_laptop like this, never a copy bundled with your page: the laptop and its SDK change
together. Loading it twice is harmless. It also sets the OS's look as CSS variables, see [styling.md](styling.md).

## Contents

- [In game, embedded and standalone](#in-game-embedded-and-standalone)
- [Properties](#properties)
- [Errors](#errors)
- [Methods](#methods): [ready](#readycallback), [post](#postendpoint-data), [mock](#mockendpoint-handler),
  [notify](#notifyoptions), [can](#cancapability), [close](#close), [setTitle](#settitletitle),
  [openUrl](#openurlurl-options), [pushUrl](#pushurlurl-options), [openApp](#openappappid-params),
  [getContext](#getcontext), [saveState](#savestatestate), [on and off](#onevent-handler-and-offevent-handler)
- [Files](#laptopfiles), [account](#laptopaccount), [badge](#laptopbadgecount), [clipboard](#laptopclipboard), [sound](#laptopsound),
  [pay](#laptoppaypaymentid), [storage](#laptopstorage), [rooms](#laptoprooms), [cast](#laptopcast),
  [share](#laptopshareoptions), [permissions](#laptoppermissions), [racks](#laptopracks), [terminal](#laptopterminal)
- [Events](#events)
- [The context](#the-context)
- [The cast viewer page](#the-cast-viewer-page)
- [TypeScript](#typescript)
- [React hooks](#react-hooks)

## In game, embedded and standalone

| | `Laptop.inGame` | `Laptop.embedded` |
| --- | --- | --- |
| Meaning | The page's address is `https://cfx-nui-<resource>/...` | The page runs inside a frame, the laptop's window or tab |
| In game, in the laptop | `true` | `true` |
| Opened in a normal browser | `false` | `false` |

- `Laptop.post` sends real requests when `inGame` is true, and answers from `Laptop.mock` handlers when it is false.
- Every method that asks the laptop rejects at once with the code `unsupported` when `embedded` is false.
- The SDK's own calls (`files`, `account`, `badge`, `clipboard`, `pay`, `storage`, `rooms`, `cast`, `share`,
  `permissions`) are answered by `Laptop.mock("sdk:<feature>.<op>", handler)` when one is registered, such as
  `Laptop.mock("sdk:pay.show", ...)`, so a page using them can be built in a normal browser. See
  [Developing in a browser](getting-started.md#developing-in-a-normal-browser).
- `Laptop.ready()` resolves at once with a standalone context when `embedded` is false: Veil's dark look with the blue
  accent, `standalone: true`, `kind`, `id` and `windowId` null, and no capabilities. See [the context](#the-context).
- When embedded but the laptop does not answer within 5 seconds, `ready()` resolves with the same standalone context and
  logs a warning.
- `saveState` resolves `true` when not embedded and only updates `Laptop.context.state`.

## Properties

| Property | Type | Value |
| --- | --- | --- |
| `Laptop.version` | `number` | The protocol version, `2`. |
| `Laptop.resource` | `string \| null` | The resource that owns the page, read from its `cfx-nui-<resource>` address. `null` in a normal browser. |
| `Laptop.inGame` | `boolean` | See above. |
| `Laptop.embedded` | `boolean` | See above. |
| `Laptop.context` | `Context \| null` | The current [context](#the-context). `null` until the laptop answered. The SDK updates this one object in place as events arrive. |
| `Laptop.files`, `.clipboard`, `.sound`, `.storage`, `.rooms`, `.cast`, `.permissions`, `.racks`, `.terminal` | objects | See below. |

## Errors

Every method that asks the laptop returns a promise. A refusal rejects with an `Error` whose message starts with
`[Laptop]` and that carries a `code` to branch on:

```js
try {
    await Laptop.pay(paymentId);
} catch (error) {
    if (error.code === "cancelled") return;

    showError(error.code);
}
```

| Code | Meaning |
| --- | --- |
| `invalid` | An argument is wrong, the message says which. |
| `unsupported` | Not available where the page runs: outside the laptop, an app-only call from a site, or a feature the laptop has off. |
| `notRegistered` | The server has no registration of this app or site from this page's resource. |
| `notAllowed` | The server's config doesn't let this resource use the feature or permission. |
| `noAccess` | The player doesn't pass the registration's `access` rule. |
| `notLicensed` | A paid app the player hasn't bought. |
| `denied` | The player said no to a permission, or turned the app's notifications off. |
| `cancelled` | The player closed the chooser, the pay sheet, the share sheet or the Cast menu. |
| `busy` | The OS is showing another sheet or chooser for this window, or the payment is being paid already. |
| `rateLimited` | Too many calls in a short time. |
| `tooLarge`, `quota` | Over a size limit, or over the app's storage. |
| `notFound`, `gone` | The file, payment or room doesn't exist, or a file handle is no longer valid. |
| `offline` | The laptop has no internet connection, or the player is gone. |
| `notReady` | The server isn't ready yet, try again shortly. |
| `noFunds`, `expired` | A payment the player couldn't pay, or that ran out of time. |
| `timeout` | No answer in time: 10 seconds for most calls, 15 for calls the server answers. Calls that wait for the player, such as the file chooser and the pay sheet, never time out. |
| `failed` | Anything else; the message says what. |

## Methods

### ready(callback?)

```ts
ready(callback?: (context: Context) => void): Promise<Context>
```

Resolves with the context once the laptop answered; every call returns the same promise. Wait for it before you read
`Laptop.context` or call `Laptop.can`.

```js
Laptop.ready().then((context) => {
    render(context.params);
});
```

### post(endpoint, data?)

```ts
post<T = unknown>(endpoint: string, data?: unknown): Promise<T>
```

POSTs `data` as JSON to your resource's `RegisterNUICallback(endpoint)` and resolves with its reply. A leading `/` on
the endpoint is dropped. `data` left out is sent as `{}`.

- The reply is parsed as JSON. An empty reply resolves `null`; a reply that is not JSON resolves as the raw text.
- There is no timeout. If the Lua callback never calls `cb`, the promise never settles.
- Outside the game (`inGame` false) it calls the handler registered with `Laptop.mock(endpoint)`, or rejects with
  `No mock for "<endpoint>"` when there is none.

```js
const result = await Laptop.post("BuyItem", { item: "water", amount: 2 });
```

```lua
RegisterNUICallback("BuyItem", function(data, cb)
    cb(Z.callback.request("my_resource:BuyItem", nil, data) or {ok = false})
end)
```

The SDK checks nothing on your callbacks. Check `IsAtLaptop` and `CanUseApp` on the server, see
[lua-api.md](lua-api.md#canuseapp).

### mock(endpoint, handler)

```ts
mock(endpoint: string, handler: (data: unknown) => unknown): Sdk
```

Answers `Laptop.post(endpoint)` while the page runs outside the game, and the SDK's own calls when `endpoint` is
`"sdk:<feature>.<op>"`, such as `"sdk:files.open"`, `"sdk:pay.show"`, `"sdk:storage.get"` or `"sdk:rooms.join"`. The
handler gets the posted data and may return a value or a promise; throwing rejects the call. Returns `Laptop`, so calls
chain. Mocks are kept in game too but never used there.

```js
Laptop.mock("GetShop", () => ({ items: [] })).mock("sdk:pay.show", ({ paymentId }) => ({ paymentId, status: "settled", method: "bank", amount: 50 }));
```

### notify(options)

```ts
notify(options: NotifyOptions | string): Promise<{ id: string }>
```

Shows an OS notification and resolves with its id, the one you gave or one the OS made. A string is the title. Rejects
with `denied` when the player turned the app's notifications off.

| Option | Type | Notes |
| --- | --- | --- |
| `title` | `string` | Required, trimmed, cut to 120 characters. Empty rejects. |
| `text` | `string` | Optional, cut to 500 characters. |
| `icon` | `string` | Optional Lucide icon name (such as `"shield-check"`) or an image URL. Paths starting with `/`, `./` or `../` resolve against your page. Left out: the app's own icon, or `"globe"` for a site. |
| `duration` | `number` | Optional milliseconds the banner shows, clamped to 1000 to 30000. |
| `id` | `string` | A notification of this app with the same id is replaced. |
| `actions` | `{ id, label }[]` | Up to two buttons. `id` is letters, digits, `_` and `-`, up to 32; `label` up to 24 characters. |
| `data` | any | JSON of 1 KiB at most, handed back with the action. |
| `sound` | `"click" \| "send" \| "receive" \| "success" \| "error" \| "notification" \| null` | Optional. Played as the banner shows instead of the notification chime; `null` shows the banner silently. |

A notification only chimes while the laptop's screen is open, with the player's volume, UI-sounds switch and Do Not
Disturb. One that arrives with the laptop closed goes to the list silently.

Clicking the notification opens your app, or your site's address for a site. A click on an action comes back as the
`notificationAction` event `{ notificationId, action, data }` while the page is open, or opens the app with it in
`context.launch.notificationAction`. With Do Not Disturb on it only goes to the notification list.

```js
await Laptop.notify({ id: "order-12", title: "Order ready", actions: [{ id: "track", label: "Track" }], data: { order: 12 } });

Laptop.on("notificationAction", ({ action, data }) => {
    if (action === "track") showOrder(data.order);
});
```

### can(capability)

```ts
can(capability: Capability): boolean
```

Whether a feature works for this page here and now: `"files"`, `"documents"`, `"account"`, `"pay"`, `"storage"`,
`"badge"`, `"notifyActions"`, `"share"`, `"clipboard"`, `"clipboardRead"`, `"cast"` or `"rooms"`. It reads
`context.capabilities`, which the `capabilities` event keeps current, so it is `false` until `ready()` resolved and
always `false` standalone. Use it to hide what won't work.

### close()

```ts
close(): Promise<true>
```

Closes the app's window, or the site's browser tab.

### setTitle(title)

```ts
setTitle(title: string): Promise<true>
```

Sets the app's window title or the site's tab title. Trimmed and cut to 120 characters; empty rejects.

### openUrl(url, options?)

```ts
openUrl(url: string, options?: { newTab?: boolean }): Promise<{ windowId: string } | true>
```

Opens an address in the OS's browser (Ledge, Emberfox, Savanna or Veil Browser). The url is cut to 500 characters.

- From an app: opens the browser at the address and resolves `{ windowId }`.
- From a site: navigates the site's own tab, or opens a new tab with `{ newTab: true }`, and resolves `true`. An address
  the browser cannot read rejects.

### pushUrl(url, options?)

```ts
pushUrl(url: string, options?: { replace?: boolean }): Promise<true>
```

Sites only. Moves the tab to another address of the same site without loading the page again, like
`history.pushState`, so the browser's back and forward step through your pages.

- `url` is resolved against the address the tab shows, so `"/units/12"` and `"?tab=2"` work.
- It must stay on the same host, or it rejects.
- `{ replace: true }` replaces the current entry, like `history.replaceState`.
- A [`location`](#events) event follows, the same event back and forward raise.

```js
await Laptop.pushUrl("/units/" + unit.id);

Laptop.on("location", (location) => showPage(location.path, location.state));
```

### openApp(appId, params?)

```ts
openApp(appId: string, params?: Record<string, unknown>): Promise<{ windowId: string }>
```

Opens an app and resolves with its window id. `params` reach the app in `context.params`.

- An app that is already open (and single instance) is focused instead. Params you pass replace its params and it gets
  a `params` event; without params it keeps the ones it has.
- An app the player has not installed opens its page in the app store instead.
- Rejects when no such app exists on this OS, such as an unknown id or an app limited to other OSes.

### getContext()

```ts
getContext(): Promise<Context>
```

Asks the laptop for a fresh context, stores it as `Laptop.context`, applies the theme and raises `context`. Rarely
needed: the SDK keeps the context current from events.

### saveState(state)

```ts
saveState(state: unknown): Promise<true>
```

Keeps a small JSON value for the app's window, or for the address the site's tab shows (like `history.state`). When
the laptop wakes after being closed, put away, a relog or a server restart, the page gets it back in `context.state`.

- At most 16 KiB of JSON once encoded as UTF-8.
- `null` (or `undefined`) forgets it.
- `Laptop.context.state` is updated at once, before the laptop answers.
- An app's state goes with the window; closing the window drops it. A site's state goes with the tab's current history
  entry. For data that should outlive the window or follow the account, use [`Laptop.storage`](#laptopstorage).
- Rejects where nothing is kept, such as a page shown inside a Shroud message.

```js
Laptop.ready().then((context) => {
    showTab(context.state?.tab ?? "home");
});

const pickTab = (tab) => {
    showTab(tab);
    Laptop.saveState({ tab });
};
```

### on(event, handler) and off(event, handler)

```ts
on(event: EventName, handler: (data) => void): () => void
off(event: EventName, handler: (data) => void): void
```

`on` returns a function that removes the handler. A handler that throws is logged and does not stop the others. See
[Events](#events).

## Laptop.files

The OS's file chooser. The page only sees files the player picked.

```ts
files.open(options?: { types?: FileType[]; startIn?: "documents" | "persistent" | "stick" }): Promise<OpenedFile[]>
files.save(options: { suggestedName: string; content: string; types?: FileType[]; startIn?: ... }): Promise<FileHandle>
files.read(handle: FileHandle | string): Promise<OpenedFile>
files.write(handle: FileHandle | string, content: string): Promise<FileHandle>
files.release(handle: FileHandle | string): Promise<true>
```

- `open` shows the chooser and resolves with what the player picked (one file for now, still in a list), text files
  with their `content`. Closing it rejects with `cancelled`.
- `save` shows the save chooser with `suggestedName` (the part before the extension starts selected), writes `content`
  there and resolves with a handle.
- `write` overwrites a file this window opened or saved without asking again; `read` reads it again. A handle is valid
  for this window until it closes, the account changes or the stick it is on leaves its port; after that the calls
  reject with `gone` or `notFound`, and the page asks again with `save`.
- `types` limits the chooser: `[{ label: "Note", extensions: ["note"] }]`.
- A `FileHandle` has `id`, `name`, `path` (for showing only), `kind` (`"text"`, `"image"`, `"audio"`, `"video"`,
  `"archive"`, `"key"` or `"binary"`), `size`, `modified`, `location` (`"home"`, `"persistent"` or `"stick"`) and
  `readOnly`. An `OpenedFile` adds `content` for text or `src` for an image.
- Files are text, 64 KiB at most by default.

An app that registers `documents` owns those file types: opening one in Files opens the app with it in
`context.files`, or the `filesOpened` event when it is open already. See [`zyke_laptop_notes`](../zyke_laptop_notes).

## Laptop.account()

```ts
account(): Promise<Account>
```

The account the laptop is signed in to: `kind` (`"nimbus"`, `"local"`, `"guest"` or `"live"` on Veil and other USB
boots), `name`, `address` (the Nimbus address or `null`), `os`, and `appUserId`, an id stable for this account and app
(random for each guest and live session). `job` is added when the app declared the `"job"` permission and the server
shares jobs. When the app declared the `"account"` permission the OS asks the player first, and a no rejects with
`denied`. The `account` event fires when the OS signs in, out or switches account; read it again then.

`appUserId` proves nothing on its own: your server reads the same account with `GetLaptopAccount`.

## Laptop.badge(count)

```ts
badge(count: number): Promise<true>
```

Apps only. Puts a count on the app's icon in the dock, taskbar or desktop; `0` hides it. Lua does the same with the
client export `SetAppBadge`.

## Laptop.clipboard

```ts
clipboard.writeText(text: string): Promise<true>
clipboard.readText(): Promise<string>
```

`writeText` copies up to 16384 characters to the OS's clipboard. `readText` reads what was last copied in this OS
session and needs the `"clipboard"` permission, which the OS asks the player for.

## Laptop.sound

```ts
sound.play(name: "click" | "send" | "receive" | "success" | "error"): Promise<true>
```

Plays one of the running OS's own sounds. Only the player at the laptop hears it, with their volume, UI-sounds switch
and Do Not Disturb. One sound per 60 ms: a faster call rejects with `rateLimited`, so it is safe to call on every key.
In a normal browser it resolves silently.

For sounds people nearby should hear, such as a keypad, use the server export
[`PlayAppSound`](lua-api.md#playappsound).

## Laptop.pay(paymentId)

```ts
pay(paymentId: string): Promise<{ paymentId: string; status: "settled"; method: "bank" | "crypto"; amount: number; coin?: string }>
```

Shows the OS's pay sheet for a payment your server made with `CreatePayment`. The page never passes an amount, only
the payment id. Resolves once the money moved; rejects with `cancelled`, `noFunds`, `expired`, `offline` or
`notRegistered`.

```js
const { paymentId } = await Laptop.post("Checkout", { cart });

try {
    await Laptop.pay(paymentId);
} catch (error) {
    if (error.code !== "cancelled") showError(error.code);
}
```

Deliver what was bought on the server, in the `zyke_laptop:PaymentSettled` event, never because the page's promise
resolved. See [lua-api.md](lua-api.md#payment-exports), [`zyke_laptop_bank`](../zyke_laptop_bank) and
[`zyke_laptop_shop`](../zyke_laptop_shop).

## Laptop.storage

```ts
storage.get<T>(key: string): Promise<T | null>
storage.getAll(): Promise<Record<string, unknown>>
storage.set(key: string, value: unknown): Promise<true>
storage.remove(key: string): Promise<true>
storage.keys(): Promise<string[]>
storage.usage(): Promise<{ bytes: number; maxBytes: number }>
```

Data kept by the server per account and app (or site), the same on every laptop the account signs in to. Needs a
`storage` field in the registration. Values are JSON, 8 KiB per key and 32 KiB per app unless the registration asks for
more; `set(key, null)` removes the key. Another laptop of the account that changes a key sends the `storage` event
`{ key, value }`, and the newest write of a key wins. Guest accounts and Veil keep it only until the laptop powers off.

Keep data other players share, or that money depends on, in your own tables: the page writes storage, so it is client
input.

```js
const settings = (await Laptop.storage.get("settings")) ?? { units: "metric" };
await Laptop.storage.set("settings", { ...settings, units: "imperial" });
```

## Laptop.rooms

```ts
rooms.join(name: string, data?: unknown): Promise<Room>
```

Realtime messages between pages of the same app or site on different laptops, through the server. Needs a `rooms`
field in the registration, and by default an internet connection. `name` is letters, digits, `_` and `-`, up to 48.
`data` reaches the registration's `join` function, which decides whether the player may join and what the others see
of them.

| Member of `Room` | Meaning |
| --- | --- |
| `id`, `name` | The room. |
| `self` | This page's member id: random per room, never a server id. |
| `members` | `{ id, data? }[]`, kept current. |
| `send(data, to?)` | To everyone else, or one member id. Over the size limit rejects with `tooLarge`. |
| `leave()` | Leaves the room. |
| `on("message" \| "join" \| "leave" \| "close", handler)` | `message` gives `{ from, data }` (`from` is a member id or `"server"`), `join` and `leave` the member, `close` `{ reason }`: `"left"`, `"kicked"`, `"closed"`, `"offline"` or `"laptopOff"`. Returns a function that stops listening. |

A refused join rejects with `quota` (the room or the player's rooms are full), `offline`, `noAccess` or `denied`. The
player leaves when the window closes, the laptop powers off or goes offline, or the player drops. See
[`zyke_laptop_tictactoe`](../zyke_laptop_tictactoe).

```js
const room = await Laptop.rooms.join("table-12");

room.on("message", ({ from, data }) => applyMove(from, data));
await room.send({ type: "move", cell: 4 });
```

`send` rejects with `rateLimited` when the page sends faster than the room's `rate` allows.

## Laptop.cast

```ts
cast.screens(): Promise<{ id, label, via: "hdmi" | "wireless", distance, busy }[]>
cast.start(snapshot: unknown): Promise<{ screen: string; via: "hdmi" | "wireless" }>
cast.snapshot(content: unknown): Promise<true>
cast.delta(delta: unknown): Promise<true>
cast.signal(signal: unknown): Promise<true>
cast.stop(): Promise<true>
```

Apps only, with a `cast` field in the registration. Shows the app's own viewer page on a TV, monitor or projector in
the world. `start` opens the OS's Cast menu and sends the first snapshot; the window's title bar also gets a Cast
button. `snapshot` replaces what the screen shows, `delta` changes it in order, and
`signal` passes something short, such as a pointer. Each one goes through the registration's check on the server first,
which decides what viewers see. Over the cast's size limit rejects with `tooLarge`.

The `cast` event `{ state, screen? }` says when the cast `started`, `stopped`, or the screen wants a fresh snapshot
(`wantSnapshot`), for example when someone new looks at it: send the whole picture again then.

## Laptop.share(options)

```ts
share(options: { title?: string; text?: string; url?: string; file?: FileHandle | string }): Promise<{ target: "mail" | "messenger" | "chat" | "files" | "clipboard" }>
```

Shows the OS's Share sheet: Mail, Natter, Shroud, Files or the clipboard. The picked app only gets a prefilled draft. A share with a `file` (a handle from `Laptop.files`) offers
only Mail, which attaches it. Closing the sheet rejects with `cancelled`.

## Laptop.permissions

```ts
permissions.get(): Promise<{ account: boolean; clipboard: boolean; job: boolean; notifications: boolean }>
```

What the player decided for this app; `false` for undecided. Asks nothing. Permissions are declared in the
registration (`permissions = {"account", "clipboard"}`) and asked for the first time the page uses them.

## Laptop.racks

Reads and runs the player's laptop racks. For resources that register their own rack workloads (see zyke_laptop's
README, "Laptop racks").

| Method | Resolves with |
| --- | --- |
| `racks.list()` | `{ racks, unit, profiles }`: the racks the player owns or is a member of, the compute unit (such as `"MH/s"`) and the power profiles. |
| `racks.get(rackId)` | One rack with its laptops, workloads, members' names and history. |
| `racks.workloads()` | Every registered workload with the resource that owns it. |
| `racks.setShare(rackId, workloadId, share)` | `true`. Sets the percent (0 to 100) of the rack's compute for a workload. Only for workloads your page's own resource registered. |
| `racks.setPower(rackId, on)` | `true`. |
| `racks.setProfile(rackId, profile)` | `true`. `"eco"`, `"balanced"`, `"max"` or a profile the server added. |

The page's app or site must be registered by its resource, the player must be at a powered laptop, and the
registration's `access` and licence apply. A refusal rejects
with `error.code`: `noAccess`, `notFound`, `notAllowed`, `notYourWorkload`, `overAllocated`, `unknownWorkload`,
`rateLimited`, `invalid` or `notReady` (the racks are still loading). Changes made elsewhere are not pushed to the
page: read again with `get`, or send what you need from your resource with `SendAppMessage` on the server's
`zyke_laptop:racks:Tick` event.

## Laptop.terminal

```ts
terminal.active: boolean
terminal.command: string; terminal.args: string[]; terminal.cwd: string; terminal.size: { cols: number; rows: number }
terminal.print(text: TerminalText, tone?: TerminalTone): void
terminal.status(text: TerminalText | null): void
terminal.clear(): void
terminal.ask(prompt: TerminalText, options?: { secret?: boolean; initial?: string }): Promise<string | null>
terminal.choose(prompt: TerminalText, options: TerminalOption[], opts?: { initial?: number }): Promise<number | null>
terminal.confirm(question: TerminalText, initial?: boolean): Promise<boolean | null>
terminal.screen.open(options?: { captureCtrlC?: boolean }): Promise<{ cols: number; rows: number }>
terminal.screen.draw(rows: TerminalText[]): void
terminal.screen.close(): void
terminal.onKey(handler), terminal.onResize(handler), terminal.onCancel(handler): () => void
terminal.exit(): void
```

For a page the Terminal runs as a program command, registered with `program` in the app's `terminal` field. `active`
is `false` in any other page, and then every call rejects with `unsupported`. `choose` resolves with a 0-based index,
and the questions resolve with `null` for Ctrl+C. The page runs in a hidden frame, so animate with timers. See
[terminal.md](terminal.md) for the whole API and [`zyke_laptop_terminal_template`](../zyke_laptop_terminal_template).

## Events

| Event | Data | When |
| --- | --- | --- |
| `ready` | `Context` | Once, when the laptop first answered, or with the standalone context. A handler added later never sees it; use `Laptop.ready()` instead. |
| `context` | `Context` | After the first context and after every other event below except `message`, with the updated context. |
| `message` | anything | Your resource sent it with `SendAppMessage` or `SendSiteMessage`. |
| `theme` | `ThemeData` | The theme, accent or OS look changed. The SDK has already updated the CSS variables. |
| `connection` | `Connection` | The Onion network connection changed. |
| `visibility` | `{ visible: boolean }` | The laptop's screen opened or closed. |
| `params` | `Record<string, unknown>` | The app was opened again with new params, from `openApp`, the `OpenApp` export or a notification. |
| `devices` | `Device[]` | Something was plugged into or pulled out of the laptop's ports. |
| `settings` | `Settings` | One of the OS settings changed, such as volume or UI sounds. |
| `location` | `Location` | Sites only: the tab moved to another of the site's addresses through `pushUrl`, back or forward, without loading the page. |
| `capabilities` | `Capability[]` | What `Laptop.can` answers changed. |
| `account` | none | The OS signed in, out or switched account. File handles from before are gone; read `account()` again. |
| `notificationAction` | `{ notificationId, action, data? }` | The player clicked one of your notification's buttons (`action` is its id) or the notification itself (`action` null). |
| `filesOpened` | `OpenedFile[]` | The player opened one of your document types in Files while the app was open. |
| `storage` | `{ key, value }` | Another laptop of the account changed this app's storage; `value` is `null` when it was removed. |
| `cast` | `{ state, screen? }` | The app's cast `started`, `stopped` or the screen asks for a fresh snapshot (`wantSnapshot`). |

Every event first updates `Laptop.context`, so inside a handler the context is already current.

## The context

`Laptop.context`, and what `ready()` resolves with:

| Field | Type | Meaning |
| --- | --- | --- |
| `protocol` | `number` | Protocol version, `2`. |
| `standalone` | `true`, optional | Only set when the page runs outside the laptop. |
| `kind` | `"app" \| "site" \| null` | What the page is shown as. `null` standalone. |
| `id` | `string \| null` | Your app id or site id. |
| `windowId` | `string \| null` | The window the page is in. |
| `resource` | `string \| null` | The resource that registered the app or site. |
| `params` | `object` | What the app was opened with, `{}` when nothing. |
| `os` | `"facade" \| "lumen" \| "solace" \| "veil"` | The OS. Facade is like Windows 11, Lumen like Ubuntu, Solace like macOS, Veil like Tails. |
| `theme` | `"light" \| "dark"` | |
| `accent` | `"blue" \| "teal" \| "green" \| "yellow" \| "orange" \| "red" \| "pink" \| "purple" \| "slate"` | |
| `palette` | `Palette` | The OS's resolved colours, see [styling.md](styling.md). |
| `shape` | `{ radius, radiusControl, controlHeight }` | CSS lengths of cards, controls and control height. |
| `toolkit` | `boolean` | The recovery toolkit's live session, where `os` is `"lumen"`. Registered apps do not show there. |
| `connection` | `{ status, connected, exitIp }` | Onion network: `status` is `"disconnected"`, `"connecting"`, `"connected"` or `"failed"`. |
| `settings` | `Settings` | `language` (such as `"en"`), `clock24h`, `securityLevel` (`"standard"`, `"safer"`, `"safest"`), `uiSounds`, `volume`, `doNotDisturb`. |
| `visible` | `boolean` | The laptop's screen is open. |
| `devices` | `Device[]` | What is plugged into the ports; empty ports are left out. Each has `port` (such as `"usbc1"`), `kind` (`"usbc"`, `"usba"`, `"hdmi"`, `"audio"`), `side` (`"left"`, `"right"`, `"rear"`), `type`, `item` and `label`. |
| `capabilities` | `Capability[]` | What this page may use here and now, see [`can`](#cancapability). Empty standalone. |
| `files` | `OpenedFile[]`, optional | Files the app was opened with, such as a document double-clicked in Files. |
| `launch` | `{ notificationAction? }`, optional | Why the app was opened, when the OS opened it for a notification's button. |
| `display` | `"dui"`, optional | `"dui"` in game, where the OS runs on the laptop's own screen and the SDK fills in what that screen lacks: typing, modifier clicks, double clicks and `<select>` lists. Unset standalone and in the laptop's browser preview. |
| `state` | anything, optional | What the page last saved with `saveState`. |
| `url`, `host`, `path`, `search` | `string`, optional | Sites only: the address the tab shows. |
| `chat` | `{ messageId }`, optional | Set for a page shown inside a Shroud conversation. |

Standalone, `settings` is `{ language: "en", clock24h: true, securityLevel: "standard", uiSounds: true, volume: 60,
doNotDisturb: false }` and `connection` is `{ status: "connected", connected: true, exitIp: null }`.

## The cast viewer page

The page a screen in the world shows while your app casts, named by `cast.ui` in the registration. It loads its own
small SDK instead of `laptop.js`:

```html
<script src="https://cfx-nui-zyke_laptop/nui/sdk/laptop-cast.js"></script>
```

```js
LaptopCast.on("snapshot", (content) => render(content));
LaptopCast.on("delta", (delta) => apply(delta));
LaptopCast.on("signal", (signal) => showPointer(signal));
LaptopCast.on("setup", ({ locale, width, height }) => setLanguage(locale));
```

`LaptopCast.context` holds `{ locale, width, height }` once the screen sent it. Messages that arrive before the page
listens are kept for its first listener. The page gets only what your server's cast functions returned, so put any
text it shows into the snapshot on the server. Styling: [styling.md](styling.md#cast-viewer-pages). See
[`zyke_laptop_tictactoe`](../zyke_laptop_tictactoe).

## TypeScript

`sdk/laptop.d.ts` in this repo is a copy of zyke_laptop's `nui/sdk/laptop.d.ts`. It is a global declaration file: copy
it into your project and add it to `include` in `tsconfig.json`, or reference it:

```ts
/// <reference path="./laptop.d.ts" />
```

It declares `window.Laptop`, a global `Laptop` and `LaptopCast`, with every type in the `ZykeLaptop` and
`ZykeLaptopCast` namespaces:

```ts
const onTheme = (theme: ZykeLaptop.ThemeData) => console.log(theme.os);

const account = await Laptop.post<{ balance: number }>("GetAccount");

try {
    await Laptop.pay(paymentId);
} catch (error) {
    if ((error as ZykeLaptop.SdkError).code === "cancelled") return;
}
```

The `.d.ts` adds no code: the SDK still has to be loaded with the script tag. Copy the new file when the laptop
updates.

## React hooks

`sdk/laptop-react.ts` is a copy of zyke_laptop's `nui/sdk/laptop-react.ts`. Copy it and `laptop.d.ts` into a Vite +
React project, keep `laptop.d.ts` in your `tsconfig` `include`, and load the SDK as a classic script in `index.html`
before your bundle, so `window.Laptop` exists when your code runs. `zyke_laptop_react_template` is set up this way.

| Export | Returns | Notes |
| --- | --- | --- |
| `useLaptopEvent(event, handler)` | nothing | Listens for an SDK event. Always calls the newest `handler`, without listening again on every render. |
| `useLaptopContext()` | `Context \| null` | `null` until the laptop answered. Re-renders on every `context` event. |
| `useLaptopDevices()` | `Device[]` | Empty until the laptop answered, and outside it. |
| `useLaptopSettings()` | `Settings \| null` | `null` until the laptop answered. |
| `useLaptopMessage<T>(handler)` | nothing | Calls `handler` with what your resource sent with `SendAppMessage` or `SendSiteMessage`. |
| `laptopPost<T>(endpoint, data?)` | `Promise<T>` | `Laptop.post` with a typed reply. |
| `useLaptopState<T>(key, initial)` | `[value, setValue]` | Like `useState`, but saved with `saveState`, so the value comes back after the laptop slept. |
| `useLaptopCapabilities()` | `Capability[]` | Kept current by the `capabilities` event. |
| `useLaptopAccount()` | `{ account, error }` | The account, read again when the OS switches account. `error` is the code of a refusal, such as `denied`. |
| `useLaptopStorage<T>(key, initial)` | `[value, set]` | One key of `Laptop.storage`: `initial` until the server answers, kept current when another laptop changes it. `set` shows the value at once and rolls back when the server refuses. |
| `useLaptopRoom(name, data?)` | `{ room, members, error }` | Joins the room while mounted and leaves on unmount or another name. |

`useLaptopState` keeps every key of the page in one object passed to `saveState`, so all keys together share the
16 KiB limit. It starts from `initial` until the laptop answered, then takes the saved value, unless the page already
set one. Save errors are ignored.

```tsx
import { laptopPost, useLaptopContext, useLaptopMessage, useLaptopState, useLaptopStorage } from "./laptop-react";

const App = () => {
    const context = useLaptopContext();
    const [tab, setTab] = useLaptopState("tab", "home");
    const [units, setUnits] = useLaptopStorage("units", "metric");

    useLaptopMessage<{ refresh?: boolean }>((data) => {
        if (data.refresh) void laptopPost("GetAccount");
    });

    if (!context) return null;

    return <Tabs value={tab} onChange={setTab} units={units} onUnits={(next) => void setUnits(next)} />;
};
```
