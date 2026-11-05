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
    const now = () => Math.floor(Date.now() / 1000);
    const day = 86400;

    // The people the lookups find. Sam is online with server ID 2, Jamie is away, so money to Jamie is held
    const people = [
        { name: "Sam Reed", phone: "5550142", serverId: 2, online: true },
        { name: "Jamie Cole", phone: "5550199", serverId: null, online: false },
    ];

    const account = {
        name: "Alex Morgan",
        balance: 48250,
        payees: [{ id: 1, name: "Jamie Cole" }],
        bills: [
            { id: "utilities", label: "Water and power", amount: 180, paid: false },
            { id: "phone", label: "Phone plan", amount: 60, paid: true },
        ],
        requests: {
            incoming: [{ id: 7, requester_name: "Sam Reed", payer_name: "Alex Morgan", amount: 45, note: "Pizza", status: "open", createdAt: now() - 1800 }],
            outgoing: [{ id: 6, requester_name: "Alex Morgan", payer_name: "Jamie Cole", amount: 300, note: "Concert tickets", status: "declined", createdAt: now() - 2 * day }],
        },
        standing: [{ id: 1, name: "Jamie Cole", amount: 1200, note: "Rent", intervalDays: 7, nextRunAt: now() + 3 * day, status: "active" }],
    };

    // Newest first, a few months back so the summary has something to show
    const transactions = [];
    let nextId = 1;

    const record = (direction, name, amount, note, kind, createdAt = now()) => transactions.unshift({ id: nextId++, direction, name, amount, note, kind, createdAt });

    for (let i = 40; i > 0; i--) {
        const person = people[i % 2].name;

        if (i % 3 === 0) record("in", person, 200 + i * 15, i % 6 === 0 ? "Car repair" : "", "transfer", now() - i * 4 * day);
        else if (i % 7 === 0) record("out", person, 1200, "Rent", "standing", now() - i * 4 * day);
        else record("out", person, 20 + i * 3, i % 4 === 0 ? "Dinner" : "", i % 5 === 0 ? "request" : "transfer", now() - i * 4 * day);
    }

    record("out", "Jamie Cole", 1200, "Rent", "standingFailed", now() - 3 * day);

    const summary = () => {
        const months = [];
        const today = new Date();

        for (let i = 5; i >= 0; i--) {
            const start = new Date(today.getFullYear(), today.getMonth() - i, 1);
            const end = new Date(today.getFullYear(), today.getMonth() - i + 1, 1);
            const inMonth = transactions.filter((entry) => entry.kind !== "standingFailed" && entry.createdAt * 1000 >= start && entry.createdAt * 1000 < end);
            const sum = (direction) => inMonth.filter((entry) => entry.direction === direction).reduce((total, entry) => total + entry.amount, 0);

            months.push({ month: `${start.getFullYear()}-${String(start.getMonth() + 1).padStart(2, "0")}`, moneyIn: sum("in"), moneyOut: sum("out") });
        }

        return months;
    };

    const fullAccount = () => ({ ok: true, ...account, recent: transactions.slice(0, 5), summary: summary() });

    // The same lookups as server/recipients.lua, enough to see every answer
    const find = (data) => {
        if (data.payeeId) {
            const payee = account.payees.find((entry) => entry.id === data.payeeId);

            return payee ? people.find((person) => person.name === payee.name) : "error:unknownPayee";
        }

        if (data.by === "phone") return people.find((person) => person.phone === String(data.value).replace(/\D/g, "")) ?? "error:noNumber";
        if (data.by === "name") return people.find((person) => person.name.toLowerCase() === data.value.trim().toLowerCase()) ?? "error:nameNotFound";

        return people.find((person) => person.serverId === Number(data.value)) ?? "error:targetOffline";
    };

    const confirmed = (data) => {
        const person = find(data);

        if (typeof person === "string") return { error: person };
        if (person.name !== data.confirmedName) return { error: "error:recipientChanged" };

        return { person };
    };

    const savePayee = (name) => {
        if (!account.payees.some((payee) => payee.name === name)) account.payees.push({ id: nextId++, name });
    };

    Laptop.mock("Setup", async () => {
        const [locale, config] = await Promise.all([readLua("../locales/en.lua"), readLua("../config.lua")]);

        return {
            strings: parseLocale(locale),
            minAmount: readNumber(config, "minAmount"),
            maxAmount: readNumber(config, "maxAmount"),
            maxNoteLength: readNumber(config, "maxNoteLength"),
            minIntervalDays: readNumber(config, "minIntervalDays"),
            maxIntervalDays: readNumber(config, "maxIntervalDays"),
            historyPageSize: readNumber(config, "historyPageSize"),
        };
    });

    Laptop.mock("GetAccount", fullAccount);

    Laptop.mock("GetHistory", ({ direction, kind, search, offset }) => {
        const text = search.toLowerCase();
        const matches = transactions.filter(
            (entry) => (direction === "all" || entry.direction === direction) && (!kind || entry.kind === kind) && (!text || entry.note.toLowerCase().includes(text) || entry.name.toLowerCase().includes(text)),
        );

        return { ok: true, transactions: matches.slice(offset, offset + 25), more: matches.length > offset + 25 };
    });

    Laptop.mock("FindRecipient", (data) => {
        const person = find(data);
        if (typeof person === "string") return { ok: false, error: person };

        return { ok: true, name: person.name, online: person.online, saved: account.payees.some((payee) => payee.name === person.name) };
    });

    Laptop.mock("Transfer", (data) => {
        const { person, error } = confirmed(data);
        if (error) return { ok: false, error };
        if (data.amount > account.balance) return { ok: false, error: "error:funds" };

        account.balance -= data.amount;
        record("out", person.name, data.amount, data.note.trim(), "transfer");
        if (data.save) savePayee(person.name);

        // In game client/app.lua shows this as the OS notification
        console.info(`Notification: You sent $${data.amount} to ${person.name}.`);

        return { ...fullAccount(), sent: { name: person.name, amount: data.amount, held: !person.online } };
    });

    Laptop.mock("CreateRequest", (data) => {
        const { person, error } = confirmed(data);
        if (error) return { ok: false, error };

        account.requests.outgoing.unshift({ id: nextId++, requester_name: account.name, payer_name: person.name, amount: data.amount, note: data.note.trim(), status: "open", createdAt: now() });
        if (data.save) savePayee(person.name);

        return { ok: true, requests: account.requests, payees: account.payees, sent: { name: person.name, amount: data.amount } };
    });

    Laptop.mock("PayRequest", (id) => {
        const request = account.requests.incoming.find((entry) => entry.id === id);
        if (!request) return { ok: false, error: "error:requestGone" };
        if (request.amount > account.balance) return { ok: false, error: "error:funds" };

        account.balance -= request.amount;
        account.requests.incoming = account.requests.incoming.filter((entry) => entry !== request);
        record("out", request.requester_name, request.amount, request.note, "request");

        return { ok: true, paid: { name: request.requester_name, amount: request.amount } };
    });

    Laptop.mock("DeclineRequest", (id) => {
        account.requests.incoming = account.requests.incoming.filter((entry) => entry.id !== id);

        return { ok: true, requests: account.requests };
    });

    Laptop.mock("CancelRequest", (id) => {
        const request = account.requests.outgoing.find((entry) => entry.id === id && entry.status === "open");
        if (!request) return { ok: false, error: "error:requestGone" };

        request.status = "cancelled";

        return { ok: true, requests: account.requests };
    });

    Laptop.mock("CreateStanding", (data) => {
        const { person, error } = confirmed(data);
        if (error) return { ok: false, error };
        if (data.amount > account.balance) return { ok: false, error: "error:funds" };

        // The first payment goes out at once, as on the server
        account.balance -= data.amount;
        record("out", person.name, data.amount, data.note.trim(), "standing");
        account.standing.unshift({ id: nextId++, name: person.name, amount: data.amount, note: data.note.trim(), intervalDays: data.intervalDays, nextRunAt: now() + data.intervalDays * day, status: "active" });
        if (data.save) savePayee(person.name);

        return { ok: true };
    });

    Laptop.mock("CancelStanding", (id) => {
        account.standing = account.standing.filter((entry) => entry.id !== id);

        return { ok: true, standing: account.standing };
    });

    Laptop.mock("SavePayee", (data) => {
        const { person, error } = confirmed(data);
        if (error) return { ok: false, error };

        savePayee(person.name);

        return { ok: true, payees: account.payees };
    });

    Laptop.mock("RemovePayee", (id) => {
        account.payees = account.payees.filter((payee) => payee.id !== id);

        return { ok: true, payees: account.payees };
    });

    // In game the server makes the payment with CreatePayment and answers its id
    Laptop.mock("PayBill", ({ billId }) => ({ ok: true, paymentId: `mock-${billId}` }));

    // Stands in for the OS's pay sheet, which only exists in game. Here the player always confirms
    Laptop.mock("sdk:pay.show", ({ paymentId }) => {
        const bill = account.bills.find((entry) => `mock-${entry.id}` === paymentId);

        bill.paid = true;
        account.balance -= bill.amount;
        record("out", bill.label, bill.amount, "", "bill");

        return { paymentId, status: "settled", method: "bank", amount: bill.amount };
    });
}