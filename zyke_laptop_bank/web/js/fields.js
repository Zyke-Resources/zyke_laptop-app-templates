// The checks the forms run before posting, the same limits the server checks again
import { setup, money } from "./util.js";

// {fields} with the whole amount and the note, or {error, args}
export const readAmountAndNote = (values) => {
    const amount = Number(values.amount);

    if (!Number.isInteger(amount) || amount < setup.minAmount || amount > setup.maxAmount) return { error: "error:amount", args: [money(setup.minAmount), money(setup.maxAmount)] };
    if ([...(values.note ?? "").trim()].length > setup.maxNoteLength) return { error: "error:noteLength", args: [setup.maxNoteLength] };

    return { fields: { amount, note: values.note ?? "" } };
};

export const readStanding = (values) => {
    const read = readAmountAndNote(values);
    if (read.error) return read;

    const intervalDays = Number(values.intervalDays);

    if (!Number.isInteger(intervalDays) || intervalDays < setup.minIntervalDays || intervalDays > setup.maxIntervalDays) return { error: "error:interval", args: [setup.minIntervalDays, setup.maxIntervalDays] };

    return { fields: { ...read.fields, intervalDays } };
};