# Styling

The player runs one of four OSes, light or dark, with one of nine accents, and can switch while your page is open. The
SDK sets the OS's look as CSS variables and keeps them current, so a page styled with them matches every combination.

## What the SDK sets

When the laptop answers (and again on every theme change) the SDK sets these on `<html>`:

| Set on `<html>` | Value |
| --- | --- |
| `data-laptop-os` | `facade`, `lumen`, `solace` or `veil` |
| `data-laptop-theme` | `light` or `dark` |
| `data-laptop-accent` | `blue`, `teal`, `green`, `yellow`, `orange`, `red`, `pink`, `purple` or `slate` |
| `color-scheme` (style) | `light` or `dark`, so scrollbars and form controls follow |

And these CSS variables:

| Variable | What it is |
| --- | --- |
| `--laptop-font` | The OS's font stack, see [fonts](#fonts) |
| `--laptop-font-mono` | Monospace stack: Adwaita Mono, then DejaVu Sans Mono |
| `--laptop-window-bg` | Window background |
| `--laptop-window-fg` | Main text colour |
| `--laptop-view-bg` | Background of content views, such as lists and text areas |
| `--laptop-view-fg` | Text on `--laptop-view-bg` |
| `--laptop-headerbar-bg` | Title and toolbar background |
| `--laptop-sidebar-bg` | Sidebar background |
| `--laptop-card-bg` | Cards and panels |
| `--laptop-popover-bg` | Menus, popovers and dropdown lists |
| `--laptop-borders` | Borders and separators |
| `--laptop-dim-fg` | Secondary text |
| `--laptop-hover-bg` | Hover background for rows and flat buttons |
| `--laptop-button-bg` | Normal button background |
| `--laptop-entry-bg` | Text field background |
| `--laptop-accent` | The accent as a text or icon colour |
| `--laptop-accent-bg` | The accent as a fill, such as a primary button |
| `--laptop-accent-fg` | Text on `--laptop-accent-bg` |
| `--laptop-success` | Success colour |
| `--laptop-warning` | Warning colour |
| `--laptop-error` | Error colour |
| `--laptop-destructive-bg` | Fill of a destructive button |
| `--laptop-radius` | Corner radius of cards and panels |
| `--laptop-radius-control` | Corner radius of buttons and fields |
| `--laptop-control-height` | Height of buttons and fields |

The colours are hex or `rgba()`; some, like `--laptop-card-bg` and `--laptop-hover-bg`, are see-through. The same
values are in `Laptop.context.palette` and `Laptop.context.shape`.

The variables do not exist until the laptop answered, so give each a fallback. Veil's dark values, which the SDK uses
standalone, make a good one:

```css
body {
    margin: 0;
    font-family: var(--laptop-font, "Adwaita Sans", sans-serif);
    background: var(--laptop-window-bg, #242424);
    color: var(--laptop-window-fg, #ffffff);
}

.card {
    background: var(--laptop-card-bg, rgba(255, 255, 255, 0.08));
    border: 1px solid var(--laptop-borders, rgba(255, 255, 255, 0.15));
    border-radius: var(--laptop-radius, 12px);
}

.button {
    height: var(--laptop-control-height, 34px);
    padding: 0 14px;
    border: none;
    border-radius: var(--laptop-radius-control, 6px);
    background: var(--laptop-button-bg, rgba(255, 255, 255, 0.1));
    color: inherit;
    font: inherit;
}

.button:hover {
    background: var(--laptop-hover-bg, rgba(255, 255, 255, 0.07));
}

.button.primary {
    background: var(--laptop-accent-bg, #3584e4);
    color: var(--laptop-accent-fg, #ffffff);
}

.muted {
    color: var(--laptop-dim-fg, rgba(255, 255, 255, 0.55));
}
```

Buttons and fields do not inherit the font by themselves; set `font: inherit` on them.

## Fonts

The SDK loads the OS fonts and sets `--laptop-font`, but does not apply it; use `var(--laptop-font)` yourself.

| OS | Like | Font |
| --- | --- | --- |
| Facade | Windows 11 | Selawik (300, 400, 600, 700) |
| Lumen | Ubuntu | Ubuntu Sans (400, 500, 700) |
| Solace | macOS | Inter (400, 500, 600, 700) |
| Veil | Tails | Adwaita Sans (400, 700) |

Each stack falls back to Adwaita Sans, then DejaVu Sans. Stick to the weights in the table; others are synthesised and
look off.

## Matching the four OSes

For what the variables don't cover, branch on the attributes:

```css
/* A detail only one OS needs */
[data-laptop-os="solace"] .card {
    box-shadow: 0 1px 2px rgba(0, 0, 0, 0.12);
}

[data-laptop-theme="light"] .hero {
    background-image: url("hero-light.jpg");
}
```

Tips:

- Check the page on all four OSes in light and dark (switch in the OS's Settings; the page updates live).
- Use `--laptop-accent` for links and icons and `--laptop-accent-bg` for fills; they differ, and yellow or teal accents
  need the matching `--laptop-accent-fg` for readable text.
- Do not hard-code white or black text. Use `--laptop-window-fg`, `--laptop-view-fg` and `--laptop-dim-fg`.
- A website may use its own brand look instead. Still set `color-scheme` and keep readable contrast.
- To react in code, listen for the `theme` event or read `Laptop.context.theme` and `.os`. See [sdk.md](sdk.md#events).

## In-game limits

### Chromium 103

FiveM's in-game browser is CEF on Chromium 103. These work in a desktop browser but not in game:

| Do not use | Use instead |
| --- | --- |
| `color-mix()` | A fixed `rgba()` colour, or a see-through overlay |
| `:has()` | A class set from JavaScript |
| Individual `translate`, `scale`, `rotate` properties | `transform: translate(...) scale(...)` |
| Container queries (`@container`, `cqw` units) | Media queries, or classes set from a `ResizeObserver` |
| CSS `zoom` | Real sizes |

Also avoid relative colour syntax, `@scope`, CSS nesting and the `popover` attribute, which came after 103. When you
build with Vite or another bundler, set its target to `chrome103` so newer JavaScript syntax is compiled down.

### The screen is a DUI

The OS runs in a DUI on the laptop prop's screen, and input reaches it as forwarded events. The SDK fills the gaps:

| What | Without the SDK | With the SDK |
| --- | --- | --- |
| Typing in fields | Forwarded keys type nothing | Text, Backspace, Delete, Enter, arrows, Home, End, Ctrl+A/Z/Y/C/X, Ctrl+Backspace and IME input work, with real input events and undo |
| Paste | Nothing | Ctrl+V raises a real `paste` event with the player's clipboard and types it when the page does not handle it |
| Tab | Nothing | Moves focus through the page in order and wraps round |
| `<select>` | Its list never shows | The SDK draws its own list in the OS colours, with mouse and keyboard |
| Double and triple clicks | No `dblclick`, no word selection | `dblclick` fires; a double click selects the word, a triple click the line or paragraph |
| Shift, Ctrl and Alt with clicks | Mouse events carry no modifiers | Read from the player's keyboard |
| Dragging a range slider, a scrollbar or a text selection | Ends on the first move | Drags from press to release |
| Mouse wheel | Jumps | Glides like the OS's own pages |
| The cursor | The laptop's default cursor everywhere | The CSS `cursor` under the pointer shows on the laptop |
| Escape | Stays in the page | Goes to the laptop (closes its topmost dialog, or the screen) unless your handler calls `preventDefault()` |
| Browser shortcuts (Ctrl+T, Ctrl+W, Ctrl+L, Alt+Left and so on) | Stay in the page | Go to the OS's browser unless your handler calls `preventDefault()` |

Not fixed, so do not use:

- `<input type="date">`, `type="time"`, `type="datetime-local"`, `type="month"`, `type="week"` and `type="color"`:
  their pickers never show. Use text or number fields, or your own picker built from buttons.
- `<datalist>`: its suggestions never show. Build your own list.
- `<select multiple>` and `<select size>` lists are left to the browser.

Use ordinary elements (`button`, `a href`, `input`, `select`, `textarea`) rather than clickable `div`s, so focus, Tab
and Enter work.

### Sharp text

The DUI is scaled onto the prop's screen, so text on a fractional pixel or its own compositor layer turns blurry.

- No `will-change` and no `translate3d` / `translateZ` on anything with text.
- Do not centre with `transform: translate(-50%, -50%)`. Centre with flexbox, grid or `margin: auto`.
- Position with `left` and `top` in whole pixels rather than `transform`. Round values computed in JavaScript with
  `Math.round`.
- After an animation, leave the element with `transform: none` rather than an identity transform.

### Cast viewer pages

A cast viewer page loads `laptop-cast.js`, not `laptop.js`, so it gets no `--laptop-*` variables and no OS font. Give
it its own colours and size it with `vw` and `vh`, since screens differ in size. Every player who looks at the screen
runs the page, so draw only when a message arrives, with no animations, timers or polling.

## UX rules

- When your resource sends `exports.zyke_laptop:Notify` for an action, that OS notification is the only feedback. Do
  not also show a toast in the page saying the same thing. Show inline state instead (a disabled button while waiting,
  an error under a field).
- Use the OS's own sheets: `Laptop.files`, `Laptop.pay`, `Laptop.share`. The pay sheet is the confirmation, so the page
  only shows the result.
- No `alert`, `confirm` or `prompt`. Ask inline, for example a button that asks again on the first click.
- Flat buttons, no coloured glow (`box-shadow` in the accent colour) on buttons or cards.
- Never use `scrollIntoView`. Scroll your own container with `element.scrollTo` or `window.scrollTo`.
- Keep player-facing text in your `locales/` files, and pick the language from `Laptop.context.settings.language` or
  your resource's own locale.
