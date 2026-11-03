// Corner Supply's page. It never decides a price: it asks the server for a payment, shows it with Laptop.pay, and the
// server gives the items once the payment settled. The OS notification is the buyer's confirmation
import "./mock.js";

const Laptop = window.Laptop;
const payErrors = { noFunds: "error:noFunds", expired: "error:expired", offline: "error:offline" };
let strings = {};
let busy = false;
// Each card's redraw, so a checkout can disable and enable every button
const redraws = [];

// Locale keys with %s placeholders, filled in order
const t = (key, ...values) => values.reduce((text, value) => text.replace("%s", value), strings[key] ?? key);

const showError = (key) => {
    const error = document.getElementById("error");

    error.hidden = !key;
    error.textContent = key ? t(key) : "";
};

const setBusy = (value) => {
    busy = value;
    redraws.forEach((redraw) => redraw());
};

const checkout = async (product, quantity, buyButton) => {
    if (busy) return;

    showError(null);
    setBusy(true);
    buyButton.textContent = t("shop:paying");

    try {
        const result = await Laptop.post("Checkout", { product: product.id, quantity });
        if (!result.ok) return showError(result.error);

        await Laptop.pay(result.paymentId);
    } catch (error) {
        // Closing the pay sheet is the player's choice, not an error
        if (error.code !== "cancelled") showError(payErrors[error.code] ?? "error:payment");
    } finally {
        setBusy(false);
    }
};

const renderProduct = (product) => {
    const card = document.getElementById("product-card").content.firstElementChild.cloneNode(true);
    const quantityText = card.querySelector(".quantity");
    const buyButton = card.querySelector(".buy");
    let quantity = 1;

    const update = () => {
        quantityText.textContent = quantity;
        buyButton.textContent = t("shop:buy", product.price * quantity);
        buyButton.disabled = busy;
        card.querySelector('[data-step="-1"]').disabled = busy || quantity <= 1;
        card.querySelector('[data-step="1"]').disabled = busy || quantity >= product.maxQuantity;
    };

    card.querySelector(".card-name").textContent = product.label;
    card.querySelector(".card-description").textContent = product.description;
    card.querySelector(".card-price").textContent = t("shop:each", product.price);
    card.querySelector('[data-step="-1"]').setAttribute("aria-label", t("shop:decrease"));
    card.querySelector('[data-step="1"]').setAttribute("aria-label", t("shop:increase"));

    card.querySelectorAll(".step").forEach((button) =>
        button.addEventListener("click", () => {
            quantity = Math.min(product.maxQuantity, Math.max(1, quantity + Number(button.dataset.step)));
            update();
        }),
    );
    buyButton.addEventListener("click", () => checkout(product, quantity, buyButton));

    redraws.push(update);
    update();

    return card;
};

Laptop.ready().then(async () => {
    const setup = await Laptop.post("Setup");

    strings = setup.strings;
    document.querySelectorAll("[data-text]").forEach((el) => (el.textContent = t(el.dataset.text)));
    document.getElementById("products").replaceChildren(...setup.products.map(renderProduct));
    Laptop.setTitle(t("site:title")).catch(() => {});
    document.body.classList.remove("is-loading");
});
