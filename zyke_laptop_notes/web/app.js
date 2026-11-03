// Notes: plain text in .note files. The OS's file chooser picks where they go (Laptop.files), Files opens .note files
// in this app because server.lua registers the type with documents, and the badge on the app's icon shows unsaved work
import "./mock.js";

const Laptop = window.Laptop;
const editor = document.getElementById("editor");
const statusLine = document.getElementById("status");
const newButton = document.getElementById("new");
const saveButton = document.getElementById("save");
let strings = {};
// The file being edited, a handle from Laptop.files, null for a note not saved yet
let file = null;
let dirty = false;
let confirmTimer = null;
let stateTimer = null;

const t = (key, ...values) => values.reduce((text, value) => text.replace("%s", value), strings[key] ?? key);

const translate = () => {
    document.querySelectorAll("[data-text]").forEach((el) => (el.textContent = t(el.dataset.text)));
    document.querySelectorAll("[data-placeholder]").forEach((el) => (el.placeholder = t(el.dataset.placeholder)));
};

// Only types the chooser offers, and the extension a new file gets
const types = () => [{ label: t("file:type"), extensions: ["note"] }];

const showStatus = (key, isError = false) => {
    statusLine.textContent = t(key);
    statusLine.classList.toggle("is-error", isError);
};

const fileName = () => file?.name ?? `${t("file:untitled")}.note`;

// Kept by the OS for this window, so the draft comes back after the laptop slept
const keepState = () => {
    clearTimeout(stateTimer);
    stateTimer = setTimeout(() => Laptop.saveState({ text: editor.value, dirty, file }).catch(() => {}), 400);
};

const setDirty = (value) => {
    const changed = dirty !== value;

    dirty = value;
    document.getElementById("name").textContent = fileName();
    showStatus(dirty ? "status:unsaved" : file ? "status:saved" : "status:new");
    Laptop.setTitle(t("title:file", fileName())).catch(() => {});

    // The count on the app's icon in the dock or taskbar, 0 hides it
    if (changed) Laptop.badge(dirty ? 1 : 0).catch(() => {});
};

// A file from the chooser or Files, or { content: "" } for a new note
const load = (opened) => {
    file = opened.id ? opened : null;
    editor.value = opened.content ?? "";
    setDirty(false);
    keepState();
};

// A refusal rejects with error.code. Closing the chooser is "cancelled", which needs no message
const showError = (error) => {
    if (error.code === "cancelled") return;

    showStatus(error.code === "tooLarge" ? "error:tooLarge" : "error:failed", true);
};

const saveAs = async () => {
    try {
        file = await Laptop.files.save({ suggestedName: fileName(), content: editor.value, types: types() });
        setDirty(false);
        keepState();
    } catch (error) {
        showError(error);
    }
};

// Writes to the file this window opened or saved without asking again. A handle the OS no longer knows, such as one
// from before the account changed, asks where to save instead
const save = async () => {
    if (!file) return saveAs();
    if (file.readOnly) return showStatus("error:readOnly", true);

    try {
        file = await Laptop.files.write(file, editor.value);
        setDirty(false);
        keepState();
    } catch (error) {
        if (["notFound", "gone", "invalid"].includes(error.code)) return saveAs();

        showError(error);
    }
};

const open = async () => {
    try {
        const [picked] = await Laptop.files.open({ types: types() });

        load(picked);
    } catch (error) {
        showError(error);
    }
};

// Unsaved work needs a second click within a few seconds instead of a browser confirm dialog
const startNew = () => {
    if (dirty && !confirmTimer) {
        newButton.textContent = t("toolbar:discard");
        confirmTimer = setTimeout(() => {
            confirmTimer = null;
            newButton.textContent = t("toolbar:new");
        }, 3000);

        return;
    }

    clearTimeout(confirmTimer);
    confirmTimer = null;
    newButton.textContent = t("toolbar:new");
    load({ content: "" });
};

newButton.addEventListener("click", startNew);
document.getElementById("open").addEventListener("click", open);
saveButton.addEventListener("click", save);
document.getElementById("save-as").addEventListener("click", saveAs);

editor.addEventListener("input", () => {
    setDirty(true);
    keepState();
});

document.addEventListener("keydown", (event) => {
    if (!(event.ctrlKey || event.metaKey) || event.key.toLowerCase() !== "s") return;

    event.preventDefault();
    if (event.shiftKey) saveAs();
    else save();
});

// A .note double-clicked in Files while the app is open
Laptop.on("filesOpened", (files) => files.length > 0 && load(files[files.length - 1]));

Laptop.ready().then(async (context) => {
    strings = (await Laptop.post("Setup")).strings;
    translate();

    // In a normal browser mock.js stands in for the file chooser, so the buttons stay on there
    if (Laptop.inGame && !Laptop.can("files")) {
        document.querySelectorAll(".toolbar .button").forEach((button) => (button.disabled = true));
        newButton.disabled = false;
    }

    // Opened from Files with a .note, woken up with a draft, or a new note
    if (context.files?.length > 0) {
        load(context.files[context.files.length - 1]);
    } else {
        file = context.state?.file ?? null;
        editor.value = context.state?.text ?? "";
        setDirty(context.state?.dirty === true);
    }

    if (!Laptop.can("files")) showStatus("status:noFiles");

    document.body.classList.remove("is-loading");
    editor.focus();
});
