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
    // Stands in for the OS's file system: "sdk:<feature>.<op>" mocks answer the SDK's own calls outside the laptop
    const files = new Map();
    let nextId = 1;

    const handle = (name, content) => {
        const entry = { id: `file-${nextId++}`, name, path: `~/Documents/${name}`, kind: "text", size: content.length, modified: Date.now(), location: "home", readOnly: false };

        files.set(entry.id, { ...entry, content });

        return entry;
    };

    handle("Shopping.note", "Milk\nBread\nA new laptop battery");

    Laptop.mock("Setup", async () => ({ strings: await loadStrings() }));
    Laptop.mock("sdk:files.open", () => [...files.values()].slice(-1));
    Laptop.mock("sdk:files.save", ({ suggestedName, content }) => handle(suggestedName, content));
    Laptop.mock("sdk:files.write", ({ handle: id, content }) => {
        const entry = files.get(id);

        if (!entry) throw Object.assign(new Error("[Laptop] gone"), { code: "gone" });

        Object.assign(entry, { content, size: content.length, modified: Date.now() });

        return { ...entry, content: undefined };
    });
    Laptop.mock("sdk:badge.set", ({ count }) => console.log(`[mock] badge ${count}`));

    // A page opened on its own gets no capabilities; pretend the OS offers files and the badge
    Laptop.ready().then((context) => context.capabilities.push("files", "badge"));
}
