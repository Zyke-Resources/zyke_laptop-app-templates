// The tabs. Only the open view is shown, and the open tab is kept with saveState for the next time the app opens
import { Laptop } from "./util.js";

const tabs = [...document.querySelectorAll("#tabs [data-tab]")];
const views = [...document.querySelectorAll("#views [data-view]")];
const listeners = [];

export const onTab = (listener) => listeners.push(listener);

export const showTab = (name) => {
    if (!views.some((view) => view.dataset.view === name)) name = "overview";

    tabs.forEach((tab) => tab.classList.toggle("is-active", tab.dataset.tab === name));
    views.forEach((view) => (view.hidden = view.dataset.view !== name));
    window.scrollTo(0, 0);
    listeners.forEach((listener) => listener(name));
    Laptop.saveState({ tab: name }).catch(() => {});
};

tabs.forEach((tab) => tab.addEventListener("click", () => showTab(tab.dataset.tab)));
document.querySelectorAll("[data-goto]").forEach((node) => node.addEventListener("click", () => showTab(node.dataset.goto)));