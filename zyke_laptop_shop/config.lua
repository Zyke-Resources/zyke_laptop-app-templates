Config = {
    site = {
        -- Must be unique across every site on the laptop: letters, digits, _ and -
        id = "corner_supply",
        -- Typed into the address bar, unique across every site
        url = "cornersupply.com",
        -- Lucide icon name, https://lucide.dev/icons
        icon = "shopping-bag",
    },

    -- Who gets the money: "server", or "society:<name>" to pay a job
    payee = "server",

    -- What the shop sells. item is the inventory item, price is in whole dollars for one, maxQuantity the most in one
    -- order. The name the page shows comes from the inventory, the description from locales/en.lua (product:<id>)
    products = {
        {id = "water", item = "water", price = 4, maxQuantity = 10},
        {id = "sandwich", item = "sandwich", price = 8, maxQuantity = 10},
        {id = "bandage", item = "bandage", price = 25, maxQuantity = 5},
        {id = "radio", item = "radio", price = 150, maxQuantity = 1},
    },
}