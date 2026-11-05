// The account as GetAccount last answered. Views render from it and re-render when any part of it changes

const listeners = [];

export const store = { account: null };

export const subscribe = (listener) => listeners.push(listener);

// Merges a fresh part of the account, such as the payees a SavePayee answered, and renders every view again
export const update = (part) => {
    store.account = { ...store.account, ...part };
    listeners.forEach((listener) => listener(store.account));
};

let loader = null;

// app.js sets how the account is loaded, views call reload after an action whose result the server doesn't answer
export const setLoader = (load) => (loader = load);

export const reload = () => loader?.();
