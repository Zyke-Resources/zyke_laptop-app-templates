// Helpers every view uses: text, money and dates from the locale file, and the round trip to the server

// Loads the SDK and the made-up data outside the game before window.Laptop is read below
import "../mock.js";

export const Laptop = window.Laptop;

// What the Setup callback answered: the strings and the limits the forms check before posting
export const setup = { strings: {} };

// Locale keys with %s placeholders, filled in order
export const t = (key, ...values) => values.reduce((text, value) => text.replace(/%[sd]/, value), setup.strings[key] ?? key);

export const money = (amount) => new Intl.NumberFormat(t("web:dateLocale"), { style: "currency", currency: t("web:currency"), maximumFractionDigits: 0 }).format(amount);

// Seconds since the epoch, on the laptop's 12 or 24 hour clock
export const date = (seconds, withTime = true) => {
    const clock24h = Laptop.context?.settings?.clock24h;
    const options = withTime ? { dateStyle: "medium", timeStyle: "short", hourCycle: clock24h === false ? "h12" : "h23" } : { dateStyle: "medium" };

    return new Intl.DateTimeFormat(t("web:dateLocale"), options).format(new Date(seconds * 1000));
};

// "2026-11" as the month's name
export const monthName = (month) => {
    const [year, number] = month.split("-").map(Number);

    return new Intl.DateTimeFormat(t("web:dateLocale"), { month: "short", year: "numeric" }).format(new Date(year, number - 1, 1));
};

export const translate = (root) => {
    root.querySelectorAll("[data-text]").forEach((node) => (node.textContent = t(node.dataset.text)));
    root.querySelectorAll("[data-placeholder]").forEach((node) => (node.placeholder = t(node.dataset.placeholder)));
};

// Every reply is {ok, error?, args?}; a failed post becomes the same shape
export const call = async (endpoint, data) => {
    try {
        const result = await Laptop.post(endpoint, data);

        return result && typeof result === "object" ? result : { ok: false, error: "error:unavailable" };
    } catch (error) {
        console.error(error);

        return { ok: false, error: "error:unavailable" };
    }
};

// A refusal plays one of the OS's own sounds, heard only by this player. It rejects when called faster than every 60 ms
export const errorSound = () => Laptop.sound.play("error").catch(() => {});

// An element with a class and text, the building block of every list row
export const el = (tag, className, text) => {
    const node = document.createElement(tag);

    if (className) node.className = className;
    if (text !== undefined) node.textContent = text;

    return node;
};

export const button = (labelKey, onClick, className = "button small") => {
    const node = el("button", className, t(labelKey));

    node.type = "button";
    node.addEventListener("click", onClick);

    return node;
};

// A button that asks again on the first click instead of a confirm dialog, and runs `action` on the second. `label` is
// the translated text
export const askAgainButton = (label, action, className = "button small secondary") => {
    const node = el("button", className, label);
    let timer;

    node.type = "button";
    node.addEventListener("click", async () => {
        if (!node.classList.contains("is-asking")) {
            node.classList.add("is-asking");
            node.textContent = t("page:sure");
            timer = setTimeout(() => {
                node.classList.remove("is-asking");
                node.textContent = label;
            }, 3000);

            return;
        }

        clearTimeout(timer);
        node.disabled = true;
        await action();
        node.disabled = false;
        node.classList.remove("is-asking");
        node.textContent = label;
    });

    return node;
};

// Shows a locale key with its placeholders in an error line, or hides it
export const showError = (node, key, args = []) => {
    node.hidden = !key;
    node.textContent = key ? t(key, ...args) : "";
};

export const emptyRow = (key) => el("li", "empty", t(key));