import { createContext, useCallback, useContext } from "react";

// The locale strings the Setup callback sent, from the server's language file in locales/
export const StringsContext = createContext<Record<string, string>>({});

// t("key", ...values) fills each %s in order, like the Lua side's T
export const useT = () => {
    const strings = useContext(StringsContext);

    return useCallback(
        (key: string, ...values: Array<string | number>) => {
            let next = 0;

            return (strings[key] ?? key).replace(/%s/g, () => String(values[next++] ?? ""));
        },
        [strings]
    );
};
