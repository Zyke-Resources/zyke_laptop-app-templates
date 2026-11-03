# zyke_laptop_site_template

Part of the [zyke_laptop app templates](../README.md) for [zyke_laptop](https://zykeresources.com/package/laptop), an
in-game laptop for FiveM servers.

A minimal website to copy and rename: "My Site" at `mysite.com`, id `template_site`, listed under Business on LS Pages.
Three pages in one document (`/`, `/about`, `/contact`) with working back and forward, deep links such as
`mysite.com/contact`, and a not found page.

## Install

Needs `zyke_lib` and `zyke_laptop`. Add `ensure zyke_laptop_site_template` after both, then type `mysite.com` into the
laptop's browser.

## Files to read first

| File | What it does |
| --- | --- |
| `config.lua` | The site's id, address and icon, and the contact details |
| `server.lua` | Registers the site, again on `zyke_laptop:Ready` |
| `client.lua` | Answers `Setup` with the site's text, address and contact details |
| `web/app.js` | Setup, `Laptop.pushUrl` and the `location` event between pages, `context.path` for deep links, `Laptop.openUrl` for the link out |
| `web/index.html` | One `<section data-page="...">` per page |
| `web/style.css` | Styles built only from `--laptop-*` variables |
| `web/mock.js` | Answers `Setup` in a normal browser, ignored in game |
| `locales/en.lua` | Every piece of text, for Lua (`T`) and for the page |

## Making it your own

1. Rename the folder, for example to `my_site`. The folder name is the resource name.
2. Change `id` (`template_site`) and `url` (`mysite.com`) in `config.lua`; both must be unique across every resource.
   For a dark web site, use an address ending in `.onion` and set `network = "onion"`.
3. Change `site:title` and `site:description` in `locales/en.lua`, the `icon` (a [Lucide](https://lucide.dev/icons)
   name) and `contact` in `config.lua`, and the `category` in `server.lua`.
4. If you add callbacks, name server callbacks and events after your resource, such as `my_site:GetMenu`, and check
   `IsAtLaptop` on the server, as `zyke_laptop_app_template` does.
5. If you move the page, update `ui = "web/index.html"` in `server.lua` and `files` in `fxmanifest.lua`.
6. Add a page: a `<section data-page="/menu">` in `index.html`, its entry in `pageTitles` in `app.js`, and a
   `data-path="/menu"` button to link to it.

## In a browser

See [Developing in a normal browser](../docs/getting-started.md#developing-in-a-normal-browser). `web/mock.js` loads
zyke_laptop's `nui/sdk/laptop.js` from next to this resource or next to its category folder. The nav buttons switch
pages there, but the address, back and forward, and the link out only work in the laptop's browser.
