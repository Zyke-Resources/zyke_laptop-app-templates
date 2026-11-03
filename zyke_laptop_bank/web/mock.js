// Development only: lets the page run in a normal browser with made-up data. Serve the resources folder over HTTP,
// for example with python3 -m http.server, and open this page. In game none of this runs
const loadScript = (src) =>
    new Promise((resolve, reject) => {
        const script = document.createElement("script");

        script.src = src;
        script.onload = resolve;
        script.onerror = reject;
        document.head.appendChild(script);
    });

// The cfx-nui-zyke_laptop address only resolves in game, so use zyke_laptop's own copy of the SDK. Fix this path if
// your zyke_laptop sits somewhere else
if (!window.Laptop) await loadScript("../../../zyke_laptop/nui/sdk/laptop.js");

const Laptop = window.Laptop;

const readLua = async (path) => (await fetch(path)).text();

// ["key"] = "value" lines of a locale file
const parseLocale = (source) => {
    const strings = {};

    for (const [, key, value] of source.matchAll(/\["([^"]+)"\]\s*=\s*"((?:[^"\\]|\\.)*)"/g)) strings[key] = JSON.parse(`"${value}"`);

    return strings;
};

const readNumber = (config, key) => Number(new RegExp(`${key}\\s*=\\s*(\\d+)`).exec(config)[1]);

if (!Laptop.inGame) {
    const now = Math.floor(Date.now() / 1000);
    const account = {
        name: "Alex Morgan",
        balance: 48250,
        transactions: [
            { id: 3, direction: "in", name: "Jamie Cole", amount: 1200, note: "Rent", createdAt: now - 3600 },
            { id: 2, direction: "out", name: "Sam Reed", amount: 85, note: "", createdAt: now - 86400 },
            { id: 1, direction: "in", name: "Jamie Cole", amount: 400, note: "Car repair", createdAt: now - 3 * 86400 },
        ],
    };
    let nextId = 4;
    const bills = [
        { id: "utilities", label: "Water and power", amount: 180, paid: false },
        { id: "phone", label: "Phone plan", amount: 60, paid: true },
    ];

    Laptop.mock("Setup", async () => {
        const [locale, config] = await Promise.all([readLua("../locales/en.lua"), readLua("../config.lua")]);

        return { strings: parseLocale(locale), minAmount: readNumber(config, "minAmount"), maxAmount: readNumber(config, "maxAmount"), maxNoteLength: readNumber(config, "maxNoteLength") };
    });

    Laptop.mock("GetAccount", () => ({ ok: true, ...account, bills }));

    // In game the server makes the payment with CreatePayment and answers its id
    Laptop.mock("PayBill", ({ billId }) => ({ ok: true, paymentId: `mock-${billId}` }));

    // Stands in for the OS's pay sheet, which only exists in game. Here the player always confirms
    Laptop.mock("sdk:pay.show", ({ paymentId }) => {
        const bill = bills.find((entry) => `mock-${entry.id}` === paymentId);

        bill.paid = true;
        account.balance -= bill.amount;
        account.transactions.unshift({ id: nextId++, direction: "out", name: bill.label, amount: bill.amount, note: "", createdAt: Math.floor(Date.now() / 1000) });

        return { paymentId, status: "settled", method: "bank", amount: bill.amount };
    });

    // A few of the server's checks, enough to see the error text. Server ID 2 is "online"
    Laptop.mock("Transfer", ({ targetId, amount, note }) => {
        if (Number(targetId) !== 2) return { ok: false, error: "error:targetOffline" };
        if (Number(amount) > account.balance) return { ok: false, error: "error:funds" };

        account.balance -= Number(amount);
        account.transactions.unshift({ id: nextId++, direction: "out", name: "Sam Reed", amount: Number(amount), note: note.trim(), createdAt: Math.floor(Date.now() / 1000) });

        // In game client/app.lua shows this as the OS notification
        console.info(`Notification: You sent $${amount} to Sam Reed.`);

        return { ok: true, ...account, bills, sent: { name: "Sam Reed", amount: Number(amount) } };
    });
}
