// Development only, app.js loads it outside the game: answers the page's posts with the text from locales/en.lua and
// a few made-up vehicles. In game client.lua answers them

// zyke_laptop's copy of the SDK, for this repo next to zyke_laptop in the resources folder or inside a category beside it
const sdkPaths = ["../../zyke_laptop/nui/sdk/laptop.js", "../../../zyke_laptop/nui/sdk/laptop.js"];

const loadScript = (src) =>
    new Promise((resolve, reject) => {
        const script = document.createElement("script");

        script.src = src;
        script.onload = resolve;
        script.onerror = reject;
        document.head.append(script);
    });

for (const path of sdkPaths) {
    if (window.Laptop) break;

    await loadScript(new URL(path, import.meta.url)).catch(() => null);
}

if (!window.Laptop) throw new Error("zyke_laptop's SDK was not found, serve the folder that holds zyke_laptop over HTTP");

const Laptop = window.Laptop;

const vehicles = [
    { plate: "46EEK572", model: "sultan", label: "Sultan", state: "out" },
    { plate: "12ABC345", model: "adder", label: "Adder", state: "stored" },
    { plate: "88LSC001", model: "bison", label: "Bison", state: "stored" },
    { plate: "07WQ5X79", model: "dinghy", label: "Dinghy", state: "out" },
    { plate: "POLICE01", model: "faggio", label: "Faggio", state: "impounded" },
];

// ["key"] = "value" lines of a locale file
const loadStrings = async () => {
    const source = await (await fetch("../locales/en.lua")).text();
    const strings = {};

    for (const [, key, value] of source.matchAll(/\["([^"]+)"\]\s*=\s*"((?:[^"\\]|\\.)*)"/g)) strings[key] = JSON.parse(`"${value}"`);

    return strings;
};

// A reply after a short delay, like a round trip to the server
const later = (value) => new Promise((resolve) => setTimeout(() => resolve(value), 300));

const strings = loadStrings();

Laptop.mock("Setup", async () => ({ strings: await strings }));
Laptop.mock("GetVehicles", () => later({ ok: true, vehicles }));
Laptop.mock("Locate", async ({ plate }) => {
    const text = (await strings)["locate:set"].replace("%s", plate);

    // In game client.lua sends this as the OS's notification
    Laptop.notify({ title: (await strings)["locate:title"], text });

    return later({ ok: true });
});
