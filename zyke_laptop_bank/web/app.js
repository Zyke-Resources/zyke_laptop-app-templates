// Fleeca Banking: the balance and history come from GetAccount, transfers go through Transfer. The server checks
// every transfer again, the checks here only spare the player a round trip
import "./mock.js";

const Laptop = window.Laptop;
const form = document.getElementById("transfer");
const sendButton = document.getElementById("send");
const formError = document.getElementById("form-error");

let setup = { strings: {} };

// Locale keys with %s placeholders, filled in order
const t = (key, ...values) => values.reduce((text, value) => text.replace(/%[sd]/, value), setup.strings[key] ?? key);

const money = (amount) => new Intl.NumberFormat(t("web:dateLocale"), { style: "currency", currency: t("web:currency"), maximumFractionDigits: 0 }).format(amount);

// Seconds since the epoch, on the laptop's 12 or 24 hour clock
const date = (seconds) => {
    const clock24h = Laptop.context?.settings?.clock24h;
    const options = { dateStyle: "medium", timeStyle: "short", hourCycle: clock24h === false ? "h12" : "h23" };

    return new Intl.DateTimeFormat(t("web:dateLocale"), options).format(new Date(seconds * 1000));
};

const translate = (root) => {
    root.querySelectorAll("[data-text]").forEach((el) => (el.textContent = t(el.dataset.text)));
    root.querySelectorAll("[data-placeholder]").forEach((el) => (el.placeholder = t(el.dataset.placeholder)));
};

// Every reply is {ok, error?, args?}; a failed post becomes the same shape
const call = async (endpoint, data) => {
    try {
        const result = await Laptop.post(endpoint, data);

        return result && typeof result === "object" ? result : { ok: false, error: "error:unavailable" };
    } catch (error) {
        console.error(error);

        return { ok: false, error: "error:unavailable" };
    }
};

const showFormError = (key, args = []) => {
    formError.hidden = !key;
    formError.textContent = key ? t(key, ...args) : "";
};

// Covers the page when the account can't be read at all, such as away from a laptop
const showPageError = (key) => {
    document.getElementById("page-error").hidden = !key;
    document.getElementById("page-error-text").textContent = key ? t(key) : "";
};

const transactionRow = (entry) => {
    const row = document.createElement("li");
    const text = document.createElement("div");
    const title = document.createElement("p");
    const meta = document.createElement("p");
    const amount = document.createElement("p");

    title.className = "title";
    title.textContent = t(entry.direction === "out" ? "page:to" : "page:from", entry.name);
    meta.className = "meta";
    meta.textContent = entry.note ? `${date(entry.createdAt)} · ${entry.note}` : date(entry.createdAt);
    amount.className = `amount is-${entry.direction}`;
    amount.textContent = `${entry.direction === "out" ? "-" : "+"}${money(entry.amount)}`;
    text.append(title, meta);
    row.append(text, amount);

    return row;
};

const billError = document.getElementById("bill-error");

const showBillError = (key) => {
    billError.hidden = !key;
    billError.textContent = key ? t(key) : "";
};

// The server makes the payment and the OS's pay sheet shows it; the page never sends an amount. The sheet is the
// player's confirmation, and the paid bill shows up in the history once the server got PaymentSettled
const payBill = async (bill, button) => {
    showBillError(null);
    button.disabled = true;
    button.textContent = t("page:paying");

    const result = await call("PayBill", { billId: bill.id });

    try {
        if (!result.ok) return showBillError(result.error);

        await Laptop.pay(result.paymentId);
    } catch (error) {
        // Closing the sheet is no error
        if (error.code !== "cancelled") showBillError(error.code === "noFunds" ? "error:funds" : "error:payFailed");
    } finally {
        button.disabled = false;
        button.textContent = t("page:pay");
    }

    await load();
};

const billRow = (bill) => {
    const row = document.createElement("li");
    const title = document.createElement("p");
    const amount = document.createElement("p");

    title.className = "title";
    title.textContent = bill.label;
    amount.className = "amount";
    amount.textContent = money(bill.amount);
    row.append(title, amount);

    if (bill.paid) {
        const paid = document.createElement("p");

        paid.className = "paid";
        paid.textContent = t("page:paid");
        row.append(paid);

        return row;
    }

    const button = document.createElement("button");

    button.className = "button";
    button.type = "button";
    button.textContent = t("page:pay");
    button.addEventListener("click", () => payBill(bill, button));
    row.append(button);

    return row;
};

const render = (account) => {
    const list = document.getElementById("transactions");

    document.getElementById("bills").replaceChildren(...account.bills.map(billRow));

    document.getElementById("holder").textContent = account.name;
    document.getElementById("balance").textContent = money(account.balance);

    if (account.transactions.length === 0) {
        const empty = document.createElement("li");

        empty.className = "empty";
        empty.textContent = t("page:noHistory");
        list.replaceChildren(empty);
    } else {
        list.replaceChildren(...account.transactions.map(transactionRow));
    }
};

const load = async () => {
    const account = await call("GetAccount");

    showPageError(account.ok ? null : account.error);
    if (account.ok) render(account);

    document.body.classList.remove("is-loading");
};

const readForm = () => {
    const values = Object.fromEntries(new FormData(form));
    const targetId = Number(values.targetId);
    const amount = Number(values.amount);

    if (!Number.isInteger(targetId) || targetId <= 0) return { error: ["error:invalidTarget"] };
    if (!Number.isInteger(amount) || amount < setup.minAmount || amount > setup.maxAmount) return { error: ["error:amount", money(setup.minAmount), money(setup.maxAmount)] };
    if ([...values.note.trim()].length > setup.maxNoteLength) return { error: ["error:noteLength", setup.maxNoteLength] };

    return { transfer: { targetId, amount, note: values.note } };
};

// The OS notification from client/app.lua confirms a transfer, the page only shows the new balance and history
const send = async (event) => {
    event.preventDefault();
    if (sendButton.disabled) return;

    const { transfer, error } = readForm();
    if (error) return showFormError(...error);

    showFormError(null);
    sendButton.disabled = true;
    sendButton.textContent = t("page:sending");

    const result = await call("Transfer", transfer);

    sendButton.disabled = false;
    sendButton.textContent = t("page:send");

    if (!result.ok) {
        // One of the OS's own sounds, heard only by this player. It rejects when called faster than every 60 ms
        Laptop.sound.play("error").catch(() => {});

        return showFormError(result.error, result.args);
    }

    form.reset();
    render(result);
};

const start = async () => {
    await Laptop.ready();
    const data = await call("Setup");

    if (data.strings) setup = data;
    translate(document);

    form.addEventListener("submit", send);
    document.getElementById("retry").addEventListener("click", load);

    // client/app.lua sends {refresh: true} with SendAppMessage when money arrives while the app is open
    Laptop.on("message", (data) => data?.refresh && load());

    await load();
};

start();
