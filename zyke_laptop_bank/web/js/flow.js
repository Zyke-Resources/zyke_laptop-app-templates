// The two steps every send shares: fill in the form, then confirm with the recipient's name the server found. The
// confirmed post sends the same lookup again with that name, and the server refuses it when the lookup now finds
// someone else
import { t, el, call, errorSound, showError } from "./util.js";
import { createPicker } from "./picker.js";

// options:
//   readFields(values)       {fields} or {error, args}, from the form's own inputs
//   summary(fields)          [labelKey, text] lines shown under the recipient on the confirm step
//   confirmLabel(fields, r)  text of the confirm button
//   endpoint                 the post that does it
//   offerSave                show "Save as payee" when the recipient isn't saved yet
//   onDone(result)           after the server said yes
export const createFlow = (form, options) => {
    const edit = form.querySelector(".step-edit");
    const confirm = form.querySelector(".step-confirm");
    const actions = form.querySelector(".actions");
    const error = form.querySelector(".form-error");
    const slot = form.querySelector(".picker-slot");
    const picker = createPicker(slot, { allowPayees: !("noPayees" in slot.dataset) });
    let pending = null;
    let busy = false;

    const actionButton = (labelText, className, onClick) => {
        const node = el("button", className, labelText);

        node.type = onClick ? "button" : "submit";
        if (onClick) node.addEventListener("click", onClick);

        return node;
    };

    const showEdit = () => {
        pending = null;
        edit.hidden = false;
        confirm.hidden = true;
        actions.replaceChildren(actionButton(t("page:continue"), "button"));
    };

    const line = (labelKey, text) => {
        const row = el("div", "confirm-line");

        row.append(el("span", "label", t(labelKey)), el("span", "value", text));

        return row;
    };

    const showConfirm = () => {
        const { recipient, fields } = pending;
        const lines = [line("page:recipient", recipient.name)];

        if (!recipient.online) lines.push(el("p", "hint", t("page:recipientAway")));

        for (const [labelKey, text] of options.summary?.(fields) ?? []) {
            if (text) lines.push(line(labelKey, text));
        }

        if (options.offerSave && !recipient.saved) {
            const label = el("label", "check");
            const box = document.createElement("input");

            box.type = "checkbox";
            box.name = "save";
            label.append(box, el("span", "", t("page:savePayee")));
            lines.push(label);
        }

        confirm.replaceChildren(...lines);
        edit.hidden = true;
        confirm.hidden = false;
        const back = actionButton(t("page:back"), "button secondary", () => {
            showError(error, null);
            showEdit();
        });

        actions.replaceChildren(back, actionButton(options.confirmLabel(fields, recipient), "button"));
    };

    const setBusy = (state) => {
        busy = state;
        actions.querySelectorAll("button").forEach((node) => (node.disabled = state));
    };

    const lookUp = async () => {
        const { target, error: pickError } = picker.read();
        if (pickError) return showError(error, pickError);

        const values = Object.fromEntries(new FormData(form));
        const { fields = {}, error: fieldError, args } = options.readFields?.(values) ?? {};
        if (fieldError) return showError(error, fieldError, args);

        const result = await call("FindRecipient", target);
        if (!result.ok) {
            errorSound();

            return showError(error, result.error, result.args);
        }

        pending = { target, fields, recipient: result };
        showConfirm();
    };

    const submit = async () => {
        const save = confirm.querySelector('[name="save"]')?.checked === true;
        const { target, fields, recipient } = pending;
        const result = await call(options.endpoint, { ...target, ...fields, confirmedName: recipient.name, save });

        if (!result.ok) {
            errorSound();
            showError(error, result.error, result.args);

            // The lookup found someone else since, so the player picks again
            if (result.error === "error:recipientChanged") showEdit();

            return;
        }

        form.reset();
        picker.reset();
        showEdit();
        options.onDone(result);
    };

    form.addEventListener("submit", async (event) => {
        event.preventDefault();
        if (busy) return;

        showError(error, null);
        setBusy(true);
        await (pending ? submit() : lookUp());
        setBusy(false);
    });

    showEdit();

    return { picker, showEdit };
};