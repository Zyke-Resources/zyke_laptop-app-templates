// My Vehicles: the character's vehicles from the server, a search over them and a GPS route to one that is out.
// Each post goes to client.lua, which asks the server

// In a normal browser the SDK's cfx-nui address doesn't load, so mock.js loads a local copy and answers the posts
if (!window.Laptop?.inGame) await import("./mock.js");

const Laptop = window.Laptop;
const list = document.getElementById("list");
const search = document.getElementById("search");
const refresh = document.getElementById("refresh");
const summary = document.getElementById("summary");

let strings = {};
let vehicles = [];

// Locale keys with %s placeholders, filled in order
const t = (key, ...values) => values.reduce((text, value) => text.replace("%s", value), strings[key] ?? key);

const translate = (root) => {
    root.querySelectorAll("[data-text]").forEach((el) => (el.textContent = t(el.dataset.text)));
    root.querySelectorAll("[data-placeholder]").forEach((el) => (el.placeholder = t(el.dataset.placeholder)));
};

const message = (text, retry) => {
    const box = document.createElement("div");
    const paragraph = document.createElement("p");

    box.className = "message";
    paragraph.textContent = text;
    box.append(paragraph);

    if (retry) {
        const button = document.createElement("button");

        button.className = "button";
        button.type = "button";
        button.textContent = t("page:retry");
        button.addEventListener("click", load);
        box.append(button);
    }

    list.replaceChildren(box);
};

// The OS notification from client.lua tells the player how it went, so the page only blocks double clicks
const locate = async (button, plate) => {
    button.disabled = true;

    try {
        await Laptop.post("Locate", { plate });
    } finally {
        button.disabled = false;
    }
};

const createRow = (vehicle) => {
    const row = document.getElementById("row-template").content.firstElementChild.cloneNode(true);
    const state = row.querySelector(".state");
    const button = row.querySelector(".locate");

    translate(row);
    row.querySelector(".plate").textContent = vehicle.plate.trim();
    row.querySelector(".name").textContent = vehicle.label;
    state.textContent = t(`state:${vehicle.state}`);
    state.classList.add(vehicle.state);

    // Only a vehicle that is out stands somewhere in the world. The others keep the button's space so the rows line up
    if (vehicle.state === "out") button.addEventListener("click", () => locate(button, vehicle.plate));
    else button.classList.add("is-hidden");

    return row;
};

const render = () => {
    const query = search.value.trim().toLowerCase();
    const shown = vehicles.filter((vehicle) => !query || vehicle.plate.toLowerCase().includes(query) || vehicle.label.toLowerCase().includes(query));
    const out = vehicles.filter((vehicle) => vehicle.state === "out").length;

    summary.textContent = vehicles.length ? t("page:count", vehicles.length, out) : "";

    if (!vehicles.length) return message(t("page:empty"));
    if (!shown.length) return message(t("page:noMatch"));

    list.replaceChildren(...shown.map(createRow));
};

async function load() {
    refresh.disabled = true;
    message(t("page:loading"));

    try {
        const result = await Laptop.post("GetVehicles");

        if (!result?.ok) return message(t(result?.error ?? "error:unavailable"), true);

        vehicles = result.vehicles;
        render();
    } catch (error) {
        console.error("[garage] GetVehicles failed", error);
        message(t("error:unavailable"), true);
    } finally {
        refresh.disabled = false;
    }
}

const setup = await Laptop.post("Setup");

strings = setup.strings;
document.title = t("app:name");
translate(document);
document.body.classList.remove("is-loading");

search.addEventListener("input", render);
refresh.addEventListener("click", load);
load();
