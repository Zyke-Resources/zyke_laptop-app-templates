// Fleeca Banking: loads the strings and the account, then hands the account to the views. Every view module renders
// from the store, and every action posts to the server, which checks everything again
import { Laptop, setup, t, money, call, translate } from "./util.js";
import { update, setLoader, subscribe } from "./store.js";
import { showTab } from "./nav.js";

// Covers the page when the account can't be read at all, such as away from a laptop
const showPageError = (key) => {
    document.getElementById("page-error").hidden = !key;
    document.getElementById("page-error-text").textContent = key ? t(key) : "";
};

const load = async () => {
    const account = await call("GetAccount");

    showPageError(account.ok ? null : account.error);
    if (account.ok) update(account);

    document.body.classList.remove("is-loading");
};

const render = (account) => {
    document.getElementById("holder").textContent = account.name;
    document.getElementById("balance").textContent = money(account.balance);
};

const start = async () => {
    await Laptop.ready();

    const data = await call("Setup");

    if (data.strings) Object.assign(setup, data);
    translate(document);

    // The views translate what they build as they load, so they are imported once the strings are here
    await Promise.all(["overview", "bills", "send", "requests", "standing", "payees", "history"].map((view) => import(`./${view}.js`)));

    subscribe(render);
    setLoader(load);
    document.getElementById("retry").addEventListener("click", load);

    // client/app.lua sends {refresh: true} with SendAppMessage when the account changed while the app is open
    Laptop.on("message", (message) => message?.refresh && load());

    // A notification opens the app on the tab it is about, such as a new request
    Laptop.on("params", (params) => params?.tab && showTab(params.tab));

    await load();
    showTab(Laptop.context?.params?.tab ?? Laptop.context?.state?.tab ?? "overview");
};

start();