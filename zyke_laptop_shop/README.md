# zyke_laptop_shop

Part of the [zyke_laptop app templates](../README.md) for [zyke_laptop](https://zykeresources.com/package/laptop), an
in-game laptop for FiveM servers.

An example website: **Corner Supply** at `cornersupply.com`, a web shop that sells inventory items through the
payment flow, with refunds for orders that can't be given.

## Install

Needs `oxmysql`, `zyke_laptop` and `zyke_lib` **newer than 2.12.2**: older versions report a QBCore item the inventory
refused as given, so a full inventory would cost the buyer their money.

```cfg
ensure zyke_laptop
ensure zyke_laptop_shop
```

Then type `cornersupply.com` into the laptop's browser. The items in `config.lua` (`water`, `sandwich`, `bandage`,
`radio`) must exist in your inventory; change them to items your server has.

## Files to read first

| File | What it does |
| --- | --- |
| `server/orders.lua` | Checkout, delivery, refunds and the sweeps that pick up waiting orders. Start here. |
| `server/database.lua` | The `zyke_laptop_shop_orders` table, made on start, and the one-step status changes that keep delivery safe. |
| `config.lua` | The site's id, address and icon, the payee, and the products with their item, price and most per order. |
| `server/register.lua` | Registers the site, with the payees its payments may name. |
| `shared/products.lua` | Looks up a product and its name from the inventory. |
| `client.lua` | Answers `Setup` with the products, passes `Checkout` on, and shows the notification once an order is handled. |
| `web/app.js` | The page: the product cards, the quantity, and checkout with `Laptop.pay`. |
| `web/mock.js` | Answers the posts, reads the products from `config.lua`, and confirms every payment in a normal browser. |
| `locales/en.lua` | Every piece of text, for Lua (`T`) and for the page. |

## How an order travels

```
page:   Laptop.post("Checkout", {product, quantity})
server: checks the laptop, the product, the quantity and Z.canCarryItem, then CreatePayment -> paymentId,
        and saves the order as open
page:   Laptop.pay(paymentId)          the OS's pay sheet, the player confirms
laptop: takes the money                -> zyke_laptop:PaymentSettled
server: moves the order from open to giving, checks the payment and the character again, Z.addItem, then delivered
        or, when it can't be given, to refunding, RefundPayment, then refunded (or refundFailed, tried again later)
        then MarkPaymentFulfilled
client: an OS notification that the order arrived or was refunded
```

The OS notification is the confirmation; the page shows no message of its own, since the notification only comes once
the items were given.

Each step moves the order in one UPDATE that only works from the status it expects, so the settle event and a sweep
can never both give the same order. Orders are swept from the shop's own table when the shop starts, when the laptop
restarts and when the buyer's character loads.

### Review and manual refunds

An order still `giving` when the shop starts was cut off between claiming it and finishing, so whether its items
arrived is unknown. It is set to `review` and never given again: check it in `zyke_laptop_shop_orders` and refund it
with `RefundPayment` if the items are missing. A refund cut off the same way goes back to `refundFailed` and is tried
again; the payment itself says whether the money already went back. Its payment stays unfulfilled, so
`laptop_sdk_health` lists it too.

Refund by hand only while an order is in `review` or `refundFailed`. A refund while the shop is giving the order can
land between its last check and the items, and the buyer then gets both.

On ESX, `Z.addItem` can't tell whether the item arrived (ESX's `addInventoryItem` gives no answer), so a refused item
goes unnoticed there. The `Z.canCarryItem` check just before giving keeps that rare.

## Making it your own

1. Rename the folder.
2. Give the site its own `id` and `url` in `config.lua`. For a dark web shop, use an address ending in `.onion` and set
   `network = "onion"` in `server/register.lua`.
3. Replace `zyke_laptop_shop:` in the callback and event names in `client.lua` and `server/orders.lua`, and rename the
   `zyke_laptop_shop_orders` table in `server/database.lua`. Two shops sharing one table would each mark the other's
   orders in progress as cut off when they start.
4. Set `payee` to `"society:<job>"` to pay a business instead of the server.
5. Edit the products in `config.lua` and their descriptions (`product:<id>`) in `locales/en.lua`.
