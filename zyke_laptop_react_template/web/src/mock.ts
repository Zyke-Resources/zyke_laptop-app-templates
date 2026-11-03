// Development only: answers laptopPost while the page runs in a normal browser, with the text from locales/en.lua.
// main.tsx imports this only in npm run dev, and Laptop.mock is ignored in game anyway
import locale from "../../locales/en.lua?raw";
import type { Pong } from "./types";

const strings: Record<string, string> = {};

// Lines like ["app:name"] = "My React App" in the locale file
for (const [, key, value] of locale.matchAll(/\["([^"]+)"\]\s*=\s*"((?:[^"\\]|\\.)*)"/g)) strings[key] = JSON.parse(`"${value}"`);

let pongs = 0;
let pinging = false;

// Stands in for SendAppMessage: outside the laptop the page is its own parent, so it can post the laptop's message event
const pushMessage = (data: Pong) => window.postMessage({ __zykeLaptop: true, type: "message", data }, "*");

window.Laptop.mock("Setup", () => ({ strings }))
    .mock("GetServerInfo", () => ({ ok: true, players: 1, time: new Date().toTimeString().slice(0, 8) }))
    .mock("Ping", () => {
        if (pinging) return { ok: false, error: "error:busy" };

        pinging = true;
        setTimeout(() => {
            pinging = false;
            pongs += 1;
            pushMessage({ count: pongs, time: new Date().toTimeString().slice(0, 8) });
        }, 2000);

        return { ok: true };
    });
