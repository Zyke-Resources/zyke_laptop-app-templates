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

const read = async (path) => (await fetch(new URL(path, resourceRoot))).text();

// The text from locales/en.lua and the products from config.lua, with the item name standing in for the inventory's
const loadSetup = async () => {
    const [locale, config] = await Promise.all([read("locales/en.lua"), read("config.lua")]);
    const strings = {};

    for (const [, key, value] of locale.matchAll(/\["([^"]+)"\]\s*=\s*"((?:[^"\\]|\\.)*)"/g)) strings[key] = JSON.parse(`"${value}"`);

    const products = [...config.matchAll(/\{id = "([^"]+)", item = "([^"]+)", price = (\d+), maxQuantity = (\d+)\}/g)].map(([, id, item, price, maxQuantity]) => ({
        id,
        label: item[0].toUpperCase() + item.slice(1),
        description: strings[`product:${id}`] ?? "",
        price: Number(price),
        maxQuantity: Number(maxQuantity),
    }));

    return { strings, products };
};

if (!window.Laptop) await loadSdk(["../zyke_laptop/nui/sdk/laptop.js", "../../zyke_laptop/nui/sdk/laptop.js"]);

const Laptop = window.Laptop;

if (!Laptop.inGame) {
    Laptop.mock("Setup", loadSetup);

    // In game the server makes the payment with CreatePayment and answers its id
    Laptop.mock("Checkout", ({ product, quantity }) => ({ ok: true, paymentId: `mock-${product}-${quantity}` }));

    // Stands in for the OS's pay sheet, which only exists in game. Here the player always confirms
    Laptop.mock("sdk:pay.show", ({ paymentId }) => ({ paymentId, status: "settled", method: "bank", amount: 0 }));
}
