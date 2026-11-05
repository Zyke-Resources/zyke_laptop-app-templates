// How the player names a recipient: a phone number, a full name, a server ID or one of their saved payees. The server
// does the lookup, the checks here only spare a round trip
import { t, el, translate } from "./util.js";
import { store, subscribe } from "./store.js";

const placeholders = { phone: "page:phonePlaceholder", name: "page:namePlaceholder", id: "page:idPlaceholder" };

export const createPicker = (slot, { allowPayees = true } = {}) => {
    const root = document.getElementById("picker-template").content.firstElementChild.cloneNode(true);
    const input = root.querySelector(".picker-input");
    const chips = root.querySelector(".picker-payees");
    const modes = [...root.querySelectorAll("[data-by]")];
    const payeeMode = root.querySelector('[data-by="payee"]');
    let mode = "phone";
    let payeeId = null;

    translate(root);
    slot.replaceChildren(root);

    const renderChips = () => {
        const payees = store.account?.payees ?? [];

        // A payee removed meanwhile is no longer selected
        if (!payees.some((payee) => payee.id === payeeId)) payeeId = null;

        chips.replaceChildren(
            ...payees.map((payee) => {
                const chip = el("button", payee.id === payeeId ? "chip is-selected" : "chip", payee.name);

                chip.type = "button";
                chip.addEventListener("click", () => {
                    payeeId = payee.id;
                    renderChips();
                });

                return chip;
            }),
        );
    };

    const setMode = (next) => {
        mode = next;
        modes.forEach((node) => node.classList.toggle("is-active", node.dataset.by === mode));
        input.hidden = mode === "payee";
        chips.hidden = mode !== "payee";
        input.inputMode = mode === "id" ? "numeric" : mode === "phone" ? "tel" : "text";
        if (placeholders[mode]) input.placeholder = t(placeholders[mode]);
        if (mode === "payee") renderChips();
    };

    const syncPayeeMode = () => {
        const hasPayees = allowPayees && (store.account?.payees?.length ?? 0) > 0;

        payeeMode.hidden = !hasPayees;
        if (!hasPayees && mode === "payee") setMode("phone");
        if (mode === "payee") renderChips();
    };

    modes.forEach((node) => node.addEventListener("click", () => setMode(node.dataset.by)));
    subscribe(syncPayeeMode);
    setMode("phone");
    syncPayeeMode();

    return {
        // {target} for FindRecipient, or {error} with a locale key
        read() {
            const value = input.value.trim();

            if (mode === "payee") return payeeId ? { target: { payeeId } } : { error: "error:pickPayee" };
            if (mode === "phone") return /[0-9a-z]/i.test(value) ? { target: { by: "phone", value } } : { error: "error:invalidPhone" };
            if (mode === "name") return /\S\s+\S/.test(value) ? { target: { by: "name", value } } : { error: "error:invalidName" };

            const id = Number(value);

            return Number.isInteger(id) && id > 0 ? { target: { by: "id", value: id } } : { error: "error:invalidTarget" };
        },

        selectPayee(id) {
            payeeId = id;
            syncPayeeMode();
            setMode("payee");
        },

        reset() {
            input.value = "";
            payeeId = null;
            setMode("phone");
            syncPayeeMode();
        },
    };
};