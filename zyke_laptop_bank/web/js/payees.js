// Saved payees: added here or from the confirm step of a send, and picked in every recipient picker
import { t, el, button, askAgainButton, call, errorSound, showError, emptyRow } from "./util.js";
import { subscribe, update } from "./store.js";
import { createFlow } from "./flow.js";
import { showTab } from "./nav.js";
import { sendFlow } from "./send.js";
import { requestFlow } from "./requests.js";

const error = document.getElementById("payee-error");

const remove = async (payee) => {
    showError(error, null);

    const result = await call("RemovePayee", payee.id);

    if (!result.ok) {
        errorSound();

        return showError(error, result.error, result.args);
    }

    update({ payees: result.payees });
};

// Opens a form with the payee already picked
const startWith = (tab, flow, payee) => {
    flow.showEdit();
    flow.picker.selectPayee(payee.id);
    showTab(tab);
};

const payeeRow = (payee) => {
    const row = el("li", "row");
    const actions = el("div", "row-actions");

    actions.append(
        askAgainButton(t("page:remove"), () => remove(payee)),
        button("page:request", () => startWith("requests", requestFlow, payee), "button small secondary"),
        button("page:send", () => startWith("send", sendFlow, payee)),
    );
    row.append(el("p", "title grow", payee.name), actions);

    return row;
};

createFlow(document.getElementById("payee-form"), {
    confirmLabel: () => t("page:savePayeeButton"),
    endpoint: "SavePayee",
    onDone: (result) => update({ payees: result.payees }),
});

subscribe((account) => {
    document.getElementById("payees").replaceChildren(...(account.payees.length ? account.payees.map(payeeRow) : [emptyRow("page:noPayees")]));
});