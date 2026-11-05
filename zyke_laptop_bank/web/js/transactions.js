// One transaction row, shared by the overview and the history
import { t, money, date, el } from "./util.js";

export const transactionRow = (entry) => {
    const row = el("li", "transaction");
    const text = el("div", "text");
    const failed = entry.kind === "standingFailed";
    const meta = [date(entry.createdAt)];

    if (entry.kind !== "transfer") meta.push(t(`type:${entry.kind}`));
    if (entry.note) meta.push(entry.note);

    const title = failed ? t("history:standingStopped", entry.name) : t(entry.direction === "out" ? "page:to" : "page:from", entry.name);

    text.append(el("p", "title", title), el("p", "meta", meta.join(" · ")));

    // A stopped standing payment moved nothing, its amount is shown struck through
    const amount = failed ? money(entry.amount) : `${entry.direction === "out" ? "-" : "+"}${money(entry.amount)}`;

    row.append(text, el("p", `amount is-${failed ? "failed" : entry.direction}`, amount));

    return row;
};