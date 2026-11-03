-- Product lookups shared by the page's Setup on the client and the orders on the server

---@class ShopProduct
---@field id string
---@field item string
---@field price integer
---@field maxQuantity integer

---@param productId any
---@return ShopProduct? product
function GetProduct(productId)
    for i = 1, #Config.products do
        if (Config.products[i].id == productId) then return Config.products[i] end
    end
end

-- The inventory's name for the item, the item name itself when the inventory has no such item
---@param product ShopProduct
---@return string label
function GetProductLabel(product)
    local item = Z.getItem(product.item)

    return item and item.label or product.item
end