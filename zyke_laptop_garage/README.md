# zyke_laptop_garage

Part of the [zyke_laptop app templates](../README.md) for [zyke_laptop](https://zykeresources.com/package/laptop), an
in-game laptop for FiveM servers.

An example app: **My Vehicles**. The character's owned vehicles with plate, name and state (stored, out or impounded),
a search, and **Locate**, which sets a GPS waypoint to a vehicle that is out.

## Install

Needs `oxmysql`, `zyke_laptop` and `zyke_lib` **newer than 2.12.2** (older versions don't return each vehicle's state
from `Z.getOwnedVehicles`), with ESX, QBCore or Qbox.

```cfg
ensure zyke_laptop
ensure zyke_laptop_garage
```

The app is preinstalled.

## Files to read first

| File | What it does |
| --- | --- |
| `server/main.lua` | The two server callbacks: each checks `IsAtLaptop` and returns only the caller's own vehicles (`Z.getOwnedVehicles`, `Z.getOwnedVehicle`); Locate checks the caller owns the plate first. |
| `client.lua` | Answers `Setup`, `GetVehicles` and `Locate`, names the models (`GetDisplayNameFromVehicleModel`, `GetLabelText`), sets the waypoint and sends the notification. |
| `server/register.lua` | Registers the app, again on `zyke_laptop:Ready`. |
| `web/app.js` | The page: loading, search, refresh and the Locate button. |
| `web/mock.js` | Sample vehicles for a normal browser. |
| `config.lua` | App id, icon, window size and the most vehicles listed. |

## Another garage resource

zyke_lib reads the framework's own table: `owned_vehicles` on ESX, `player_vehicles` on QBCore and Qbox. A garage
resource with its own table needs support in zyke_lib's `getOwnedVehicles` and `getOwnedVehicle`, not in this app.
Locate finds the vehicle in the world (`Z.getVehicleByPlate`), so it works with any garage resource.

## Making it your own

1. Rename the folder.
2. Change `id` in `config.lua`. Replace `zyke_laptop_garage:` in the callback names in `client.lua` and
   `server/main.lua` with your resource name.
3. Change the text in `locales/en.lua`. An element with `data-text="key"` shows that key.

## In a browser

See [Developing in a normal browser](../docs/getting-started.md#developing-in-a-normal-browser). `mock.js` loads
zyke_laptop's SDK from two folders up (next to `zyke_laptop`) or three (inside a category folder beside it); add a path
to `sdkPaths` if yours sits elsewhere.
