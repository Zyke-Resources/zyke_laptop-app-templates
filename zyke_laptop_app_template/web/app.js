// My App's page. Each Laptop.post("Name") is answered by RegisterNUICallback("Name") in client.lua
import "./mock.js";

const Laptop = window.Laptop;
const greeting = document.getElementById("greeting");
const message = document.getElementById("message");
const note = document.getElementById("note");
const notifyButton = document.getElementById("notify");
let strings = {};
let saveTimer = null;

// Locale keys with %s placeholders, filled in order
const t = (key, ...values) => values.reduce((text, value) => text.replace("%s", value), strings[key] ?? key);

const translate = () => {
    document.querySelectorAll("[data-text]").forEach((el) => (el.textContent = t(el.dataset.text)));
    document.querySelectorAll("[data-placeholder]").forEach((el) => (el.placeholder = t(el.dataset.placeholder)));
};

// The --laptop-* variables already follow a theme change, this is for what CSS can't do
const showTheme = (theme) => {
    document.getElementById("theme").textContent = t("theme:line", t(`os:${theme.os}`), t(`theme:${theme.theme}`));
};

const loadGreeting = async () => {
    const result = await Laptop.post("GetGreeting").catch(() => null);

    if (!result?.ok) {
        greeting.textContent = t(result?.error ?? "error:unavailable");

        return;
    }

    greeting.textContent = t("greeting:hello", result.name);

    // Requests to the OS reject when the page is opened on its own, outside the laptop
    Laptop.setTitle(t("title:withName", result.name)).catch(() => {});
};

const sendNotification = async () => {
    notifyButton.disabled = true;

    try {
        await Laptop.post("Notify");
    } finally {
        notifyButton.disabled = false;
    }
};

// Kept by the OS for this window and handed back in context.state after the laptop slept. Debounced, since every
// save is a request to the OS
const saveNote = () => {
    clearTimeout(saveTimer);
    saveTimer = setTimeout(() => Laptop.saveState({ note: note.value }).catch(() => {}), 400);
};

notifyButton.addEventListener("click", sendNotification);
note.addEventListener("input", saveNote);

Laptop.on("theme", showTheme);

// What the server sent with TriggerClientEvent, passed on by client.lua through SendAppMessage
Laptop.on("message", (data) => {
    if (typeof data?.text === "string") message.textContent = t("message:received", data.text);
});

Laptop.ready().then(async (context) => {
    const setup = await Laptop.post("Setup");

    strings = setup.strings;
    translate();
    showTheme(context);
    note.value = typeof context.state?.note === "string" ? context.state.note : "";
    document.body.classList.remove("is-loading");

    await loadGreeting();
});
