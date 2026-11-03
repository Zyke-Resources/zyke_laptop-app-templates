// My Site's page. Its text and content come from client.lua through Setup. Every page of the site is this one
// document: the browser's address picks the section, so mysite.com/contact opens the contact page
import "./mock.js";

const Laptop = window.Laptop;
const pageTitles = { "/": "nav:home", "/about": "nav:about", "/contact": "nav:contact" };
let site = { url: "", strings: {}, contact: {} };
let currentPath = null;

// Locale keys with %s placeholders, filled in order
const t = (key, ...values) => values.reduce((text, value) => text.replace("%s", value), site.strings[key] ?? key);

// "/contact/" and "/contact" are the same page
const normalise = (path) => (path || "/").replace(/\/+$/, "") || "/";

const show = (path) => {
    currentPath = normalise(path);

    const page = pageTitles[currentPath] ? currentPath : "notFound";

    document.querySelectorAll("[data-page]").forEach((section) => (section.hidden = section.dataset.page !== page));
    document.querySelectorAll(".nav [data-path]").forEach((button) => {
        if (button.dataset.path === page) button.setAttribute("aria-current", "page");
        else button.removeAttribute("aria-current");
    });
    window.scrollTo(0, 0);

    // The tab's title. Requests to the OS reject when the page is opened on its own, outside the laptop
    Laptop.setTitle(t("page:title", t(pageTitles[page] ?? "notFound:title"), t("site:title"))).catch(() => {});
};

// pushUrl adds a history entry without loading the page again, then the location event below shows the page. Outside
// the laptop there is no tab to move, so the page is shown directly
const navigate = (path) => {
    if (normalise(path) === currentPath) return;

    Laptop.pushUrl(path).catch(() => show(path));
};

const render = () => {
    document.querySelectorAll("[data-text]").forEach((el) => (el.textContent = t(el.dataset.text)));
    document.getElementById("phone").textContent = site.contact.phone;
    document.getElementById("address").textContent = site.contact.address;
    document.getElementById("not-found-text").textContent = t("notFound:text", site.url);
};

document.addEventListener("click", (e) => {
    const link = e.target.closest("[data-path]");
    if (!link) return;

    // A clicked button keeps no focus ring, only keyboard focus shows one
    link.blur();
    navigate(link.dataset.path);
});

// A link to another site. Without { newTab: true } it opens in this tab, and back returns here
document.getElementById("directory").addEventListener("click", () => {
    Laptop.openUrl("lspages.com/?category=business").catch(() => {});
});

// pushUrl, back and forward all end here
Laptop.on("location", (location) => show(location.path));

Laptop.ready().then(async (context) => {
    site = await Laptop.post("Setup");

    render();
    // context.path is the address the tab was opened at, such as /about from a bookmark or the address bar
    show(context.path);
    document.body.classList.remove("is-loading");
});
