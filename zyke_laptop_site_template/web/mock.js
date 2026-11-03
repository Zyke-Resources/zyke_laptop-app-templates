// Development only: lets the page run in a normal browser. Serve the resources folder over HTTP, for example with
// `python3 -m http.server` in it, and open this resource's web/index.html. In game the SDK is already loaded and
// Laptop.mock is ignored, so nothing here runs

const resourceRoot = new URL("../", import.meta.url);

// The cfx-nui-zyke_laptop address only resolves in game, so use zyke_laptop's own copy next to this resource or its
// category folder
const loadSdk = (candidates) =>
    new Promise((resolve, reject) => {
        if (candidates.length === 0) return reject(new Error("zyke_laptop's SDK was not found, serve the resources folder over HTTP"));

        const script = document.createElement("script");

        script.src = new URL(candidates[0], resourceRoot).href;
        script.onload = resolve;
        script.onerror = () => loadSdk(candidates.slice(1)).then(resolve, reject);
        document.head.appendChild(script);
    });

// The site's text from locales/en.lua and the address and contact details from config.lua
const loadSite = async () => {
    const read = async (path) => (await fetch(new URL(path, resourceRoot))).text();
    const [locale, config] = await Promise.all([read("locales/en.lua"), read("config.lua")]);
    const strings = {};

    for (const [, key, value] of locale.matchAll(/\["([^"]+)"\]\s*=\s*"((?:[^"\\]|\\.)*)"/g)) strings[key] = JSON.parse(`"${value}"`);

    const field = (name) => new RegExp(`${name}\\s*=\\s*"([^"]+)"`).exec(config)?.[1] ?? "";

    return { url: field("url"), strings, contact: { phone: field("phone"), address: field("address") } };
};

if (!window.Laptop) await loadSdk(["../zyke_laptop/nui/sdk/laptop.js", "../../zyke_laptop/nui/sdk/laptop.js"]);

const Laptop = window.Laptop;

if (!Laptop.inGame) Laptop.mock("Setup", loadSite);
