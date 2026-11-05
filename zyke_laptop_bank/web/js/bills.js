// Bills on the overview. The server makes the payment and the OS's pay sheet shows it; the page never sends an amount.
// The sheet is the player's confirmation, and the paid bill shows up in the history once the server got PaymentSettled
import { Laptop, t, money, el, call, showError } from "./util.js";
import { subscribe, reload } from "./store.js";

const list = document.getElementById("bills");
const error = document.getElementById("bill-error");

const payBill = async (bill, node) => {
    showError(error, null);
    node.disabled = true;
    node.textContent = t("page:paying");

    const result = await call("PayBill", { billId: bill.id });

    try {
        if (!result.ok) return showError(error, result.error);

        await Laptop.pay(result.paymentId);
    } catch (payError) {
        // Closing the sheet is no error
        if (payError.code !== "cancelled") showError(error, payError.code === "noFunds" ? "error:funds" : "error:payFailed");
    } finally {
        node.disabled = false;
        node.textContent = t("page:pay");
    }

    await reload();
};

const billRow = (bill) => {
    const row = el("li", "row");

    row.append(el("p", "title grow", bill.label), el("p", "amount", money(bill.amount)));

    if (bill.paid) {
        row.append(el("p", "status is-done", t("page:paid")));

        return row;
    }

    const node = el("button", "button small", t("page:pay"));

    node.type = "button";
    node.addEventListener("click", () => payBill(bill, node));
    row.append(node);

    return row;
};

subscribe((account) => list.replaceChildren(...account.bills.map(billRow)));