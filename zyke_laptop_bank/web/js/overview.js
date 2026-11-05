// The overview: this month's money in and out with a bar per month, requests waiting for the player and the latest
// transactions
import { t, money, monthName, el, emptyRow } from "./util.js";
import { subscribe } from "./store.js";
import { transactionRow } from "./transactions.js";
import { incomingRow } from "./requests.js";

const totals = document.getElementById("month-totals");
const bars = document.getElementById("month-bars");

const total = (labelKey, amount, className) => {
    const box = el("div", "total");

    box.append(el("dt", "label", t(labelKey)), el("dd", className, money(amount)));

    return box;
};

// Two bars per month, in and out, scaled to the largest amount of the period
const renderBars = (summary) => {
    const largest = Math.max(1, ...summary.flatMap((month) => [month.moneyIn, month.moneyOut]));

    bars.replaceChildren(
        ...summary.map((month) => {
            const column = el("div", "bar-month");
            const pair = el("div", "bar-pair");
            const barIn = el("span", "bar is-in");
            const barOut = el("span", "bar is-out");

            barIn.style.height = `${Math.round((month.moneyIn / largest) * 100)}%`;
            barOut.style.height = `${Math.round((month.moneyOut / largest) * 100)}%`;
            column.title = `${monthName(month.month)}: +${money(month.moneyIn)} / -${money(month.moneyOut)}`;
            pair.append(barIn, barOut);
            column.append(pair, el("span", "bar-label", monthName(month.month).split(" ")[0]));

            return column;
        }),
    );
};

subscribe((account) => {
    const current = account.summary[account.summary.length - 1] ?? { moneyIn: 0, moneyOut: 0 };
    const net = current.moneyIn - current.moneyOut;

    totals.replaceChildren(total("filter:in", current.moneyIn, "is-in"), total("filter:out", current.moneyOut, ""), total("page:net", net, net < 0 ? "" : "is-in"));
    renderBars(account.summary);

    const incoming = account.requests.incoming;

    document.getElementById("overview-requests").hidden = incoming.length === 0;
    document.getElementById("overview-incoming").replaceChildren(...incoming.map(incomingRow));

    const recent = document.getElementById("recent");

    recent.replaceChildren(...(account.recent.length ? account.recent.map(transactionRow) : [emptyRow("page:noHistory")]));
});