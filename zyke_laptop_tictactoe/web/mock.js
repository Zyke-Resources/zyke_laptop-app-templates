// Development only: lets the page run in a normal browser. Serve the resources folder over HTTP, for example with
// `python3 -m http.server` in it, and open this resource's web/index.html. In game the SDK is already loaded and
// Laptop.mock is ignored, so nothing here runs. A real game needs two laptops: in a browser you see the lobby and
// the table waiting for a second player

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

// ["key"] = "value" lines of a locale file
const loadStrings = async () => {
    const source = await (await fetch(new URL("locales/en.lua", resourceRoot))).text();
    const strings = {};

    for (const [, key, value] of source.matchAll(/\["([^"]+)"\]\s*=\s*"((?:[^"\\]|\\.)*)"/g)) strings[key] = JSON.parse(`"${value}"`);

    return strings;
};

if (!window.Laptop) await loadSdk(["../zyke_laptop/nui/sdk/laptop.js", "../../zyke_laptop/nui/sdk/laptop.js"]);

const Laptop = window.Laptop;

if (!Laptop.inGame) {
    Laptop.mock("Setup", async () => ({ strings: await loadStrings() }));

    // "sdk:<feature>.<op>" mocks answer the SDK's own calls outside the laptop. Joining works; sending needs the laptop
    Laptop.mock("sdk:rooms.join", ({ name }) => ({ id: `mock:${name}`, name, self: "m_self", members: [{ id: "m_self", data: { name: "Alex" } }] }));
    Laptop.mock("sdk:rooms.leave", () => true);
}
