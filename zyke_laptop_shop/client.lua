-- Answers the shop's page in web/ and passes its checkout on to the server, which decides the price and gives the
-- items. server/register.lua registers the site

-- Every string of the locale file, the page picks the keys it shows
---@return table<string, string> strings
local function getStrings()
    local strings = {}

    for key, value in pairs(Translations) do
        if (type(value) == "string") then strings[key] = value end
    end

    return strings
end

---@param _ table
---@param cb fun(setup: table)
RegisterNUICallback("Setup", function(_, cb)
    local products = {}

    for i = 1, #Config.products do
        local product = Config.products[i]

        products[i] = {
            id = product.id,
            label = GetProductLabel(product),
            description = T("product:" .. product.id),
            price = product.price,
            maxQuantity = product.maxQuantity,
        }
    end

    cb({strings = getStrings(), products = products})
end)

-- The server answers a payment id, the page shows it with Laptop.pay
---@param data {product?: string, quantity?: integer}
---@param cb fun(result: table)
RegisterNUICallback("Checkout", function(data, cb)
    cb(Z.callback.request("zyke_laptop_shop:Checkout", nil, data) or {ok = false, error = "error:unavailable"})
end)

-- The OS notification is the buyer's confirmation, the page shows no message of its own for it
---@param outcome "delivered" | "refunded" | "refundFailed"
---@param label string
---@param quantity integer
RegisterNetEvent("zyke_laptop_shop:OrderHandled", function(outcome, label, quantity)
    local text = T("notify:" .. outcome, {quantity, label})

    if (GetResourceState("zyke_laptop") == "started" and exports.zyke_laptop:Notify({title = T("site:title"), text = text, icon = Config.site.icon, url = Config.site.url})) then return end

    Z.notify(text, nil, nil, true)
end)