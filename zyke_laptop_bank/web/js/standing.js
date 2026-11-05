// Standing payments: the same amount every N days, paid by the server. The first payment goes out when it is set up
import { t, money, date, el, askAgainButton, call, errorSound, showError, emptyRow } from "./util.js";
import { subscribe, update, reload } from "./store.js";
import { createFlow } from "./flow.js";
import { readStanding } from "./fields.js";

const error = document.getElementById("standing-error");

const every = (days) => t(days === 1 ? "page:everyDay" : "page:everyDays", days);

const cancel = async (standing) => {
    showError(error, null);

    const result = await call("CancelStanding", standing.id);

    if (!result.ok) {
        errorSound();

        return showError(error, result.error, result.args);
    }

    update({ standing: result.standing });
};

const standingRow = (standing) => {
    const row = el("li", "row");
    const text = el("div", "text grow");
    const stopped = standing.status === "stopped";
    const when = stopped ? t("page:standingStopped") : t("page:nextPayment", date(standing.nextRunAt, false));

    text.append(el("p", "title", t("page:to", standing.name)), el("p", "meta", [every(standing.intervalDays), when, standing.note].filter(Boolean).join(" · ")));
    row.append(text, el("p", `amount${stopped ? " is-failed" : ""}`, money(standing.amount)));
    row.append(askAgainButton(t(stopped ? "page:remove" : "page:cancel"), () => cancel(standing)));

    return row;
};

createFlow(document.getElementById("standing-form"), {
    readFields: readStanding,
    summary: (fields) => [["page:amount", money(fields.amount)], ["page:interval", every(fields.intervalDays)], ["page:firstPayment", t("page:today")], ["page:note", fields.note.trim()]],
    confirmLabel: () => t("page:startStanding"),
    endpoint: "CreateStanding",
    offerSave: true,
    // The first payment changed the balance and the history too
    onDone: () => reload(),
});

subscribe((account) => {
    document.getElementById("standing").replaceChildren(...(account.standing.length ? account.standing.map(standingRow) : [emptyRow("page:noStanding")]));
});