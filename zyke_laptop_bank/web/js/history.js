// The history: pages of transactions from GetHistory, filtered on the server, and the monthly in and out table
import { money, monthName, el, call, emptyRow } from "./util.js";
import { subscribe } from "./store.js";
import { onTab } from "./nav.js";
import { transactionRow } from "./transactions.js";

const list = document.getElementById("history");
const more = document.getElementById("history-more");
const search = document.getElementById("filter-search");
const filter = { direction: "all", kind: "", search: "" };
let open = false;
let shown = 0;
let searchTimer;

// Loads the first page again, or the next one with `append`. Answers that arrive after a newer request are dropped
let requestNumber = 0;

const load = async (append = false) => {
    const number = ++requestNumber;
    const offset = append ? shown : 0;
    const result = await call("GetHistory", { ...filter, offset });

    if (number !== requestNumber) return;
    if (!result.ok) return list.replaceChildren(emptyRow(result.error));

    const rows = result.transactions.map(transactionRow);

    shown = offset + rows.length;
    if (append) list.append(...rows);
    else list.replaceChildren(...(rows.length ? rows : [emptyRow("page:noMatches")]));

    more.hidden = !result.more;
};

// A row of buttons that act as one choice
const segmented = (id, key) => {
    const buttons = [...document.querySelectorAll(`#${id} [data-value]`)];
    const select = (value) => buttons.forEach((node) => node.classList.toggle("is-active", node.dataset.value === value));

    buttons.forEach((node) =>
        node.addEventListener("click", () => {
            filter[key] = node.dataset.value;
            select(filter[key]);
            load();
        }),
    );
    select(filter[key]);
};

segmented("filter-direction", "direction");
segmented("filter-kind", "kind");

search.addEventListener("input", () => {
    clearTimeout(searchTimer);
    searchTimer = setTimeout(() => {
        filter.search = search.value.trim();
        load();
    }, 300);
});

more.addEventListener("click", () => load(true));

onTab((name) => {
    open = name === "history";
    if (open) load();
});

const monthRow = (month) => {
    const row = document.createElement("tr");
    const net = month.moneyIn - month.moneyOut;

    row.append(el("td", "", monthName(month.month)), el("td", "is-in", money(month.moneyIn)), el("td", "", money(month.moneyOut)), el("td", net < 0 ? "" : "is-in", money(net)));

    return row;
};

subscribe((account) => {
    document.getElementById("months").replaceChildren(...[...account.summary].reverse().map(monthRow));

    // Money arrived or left while the history is open
    if (open) load();
});