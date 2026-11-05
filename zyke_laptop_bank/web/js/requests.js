// Payment requests: asking someone for money, and paying or declining what others asked of the player
import { Laptop, t, money, date, el, askAgainButton, call, errorSound, showError, emptyRow } from "./util.js";
import { subscribe, update, reload } from "./store.js";
import { createFlow } from "./flow.js";
import { readAmountAndNote } from "./fields.js";

const requestError = document.getElementById("request-error");

const meta = (request) => [date(request.createdAt), request.note].filter(Boolean).join(" · ");

// The answer of Pay, Decline or Cancel. A paid request changes the balance too, so the whole account loads again
const answer = async (endpoint, request, errorNode) => {
    showError(errorNode, null);

    const result = await call(endpoint, request.id);

    if (!result.ok) {
        errorSound();

        return showError(errorNode, result.error, result.args);
    }

    if (result.requests) update({ requests: result.requests });
    else await reload();
};

// A request someone sent the player, with Pay and Decline. Used on the overview too
export const incomingRow = (request) => {
    const row = el("li", "row wrap");
    const text = el("div", "text grow");
    const actions = el("div", "row-actions");
    const error = el("p", "form-error full", "");
    const pay = askAgainButton(t("page:payAmount", money(request.amount)), () => answer("PayRequest", request, error), "button small");

    error.hidden = true;
    text.append(el("p", "title", t("page:requestFrom", request.requester_name)), el("p", "meta", meta(request)));
    actions.append(askAgainButton(t("page:decline"), () => answer("DeclineRequest", request, error)), pay);
    row.append(text, actions, error);

    return row;
};

const outgoingRow = (request) => {
    const row = el("li", "row");
    const text = el("div", "text grow");

    text.append(el("p", "title", t("page:requestTo", request.payer_name)), el("p", "meta", meta(request)));
    row.append(text, el("p", "amount", money(request.amount)));

    if (request.status === "open") {
        row.append(askAgainButton(t("page:cancel"), () => answer("CancelRequest", request, requestError)));
    } else {
        row.append(el("p", `status is-${request.status}`, t(`status:${request.status}`)));
    }

    return row;
};

export const requestFlow = createFlow(document.getElementById("request-form"), {
    readFields: readAmountAndNote,
    summary: (fields) => [["page:amount", money(fields.amount)], ["page:note", fields.note.trim()]],
    confirmLabel: (fields) => t("page:requestAmount", money(fields.amount)),
    endpoint: "CreateRequest",
    offerSave: true,
    onDone: (result) => update({ requests: result.requests, payees: result.payees }),
});

subscribe((account) => {
    const { incoming, outgoing } = account.requests;
    const count = document.getElementById("request-count");

    document.getElementById("incoming").replaceChildren(...(incoming.length ? incoming.map(incomingRow) : [emptyRow("page:noIncoming")]));
    document.getElementById("outgoing").replaceChildren(...(outgoing.length ? outgoing.map(outgoingRow) : [emptyRow("page:noOutgoing")]));
    count.hidden = incoming.length === 0;
    count.textContent = incoming.length;

    // The app icon's count, the open requests waiting for an answer. Rejects outside the laptop
    Laptop.badge(incoming.length).catch(() => {});
});