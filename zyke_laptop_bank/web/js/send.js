// Sending money. The OS notification from client/app.lua confirms a transfer, the page only shows the new balance
import { t, money } from "./util.js";
import { update } from "./store.js";
import { createFlow } from "./flow.js";
import { readAmountAndNote } from "./fields.js";

export const sendFlow = createFlow(document.getElementById("send-form"), {
    readFields: readAmountAndNote,
    summary: (fields) => [["page:amount", money(fields.amount)], ["page:note", fields.note.trim()]],
    confirmLabel: (fields) => t("page:sendAmount", money(fields.amount)),
    endpoint: "Transfer",
    offerSave: true,
    onDone: (account) => update(account),
});