-- The shop's own record of every order, written at checkout. It is what makes delivery safe: an order is claimed in
-- one UPDATE before its items are given, so it can never be given twice, and the recovery sweeps read this table
-- instead of the laptop's payment list
--
-- status: open (waiting for payment or for the buyer), giving (items being given), delivered, refunding, refunded,
-- refundFailed (retried by the sweeps), closed (never paid) and review (stopped while giving, for staff to check).
-- A copied shop needs its own table name, or its startup check would take this shop's orders for cut-off ones

---@alias ShopOrderStatus "open" | "giving" | "delivered" | "refunding" | "refunded" | "refundFailed" | "closed" | "review"

---@class ShopOrder
---@field payment_id string
---@field identifier string
---@field product string
---@field quantity integer
---@field status ShopOrderStatus
---@field marked integer @ 1 once MarkPaymentFulfilled went through

OrderDb = {}

local ready = promise.new()

MySQL.ready(function()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `zyke_laptop_shop_orders` (
            `payment_id` VARCHAR(64) NOT NULL,
            `identifier` VARCHAR(64) NOT NULL,
            `product` VARCHAR(64) NOT NULL,
            `quantity` INT UNSIGNED NOT NULL,
            `status` ENUM('open', 'giving', 'delivered', 'refunding', 'refunded', 'refundFailed', 'closed', 'review') NOT NULL DEFAULT 'open',
            `marked` TINYINT(1) NOT NULL DEFAULT 0,
            `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`payment_id`),
            KEY `work` (`status`, `marked`),
            KEY `identifier` (`identifier`)
        )
    ]])

    -- Nothing gives items before this resource started, so an order still giving was cut off by a stop or a crash.
    -- Whether its items arrived is unknown, so staff decide instead of the shop giving them again
    MySQL.update.await("UPDATE `zyke_laptop_shop_orders` SET `status` = 'review' WHERE `status` = 'giving'")

    -- A refund cut off the same way is safe to try again: the payment itself says whether the money went back
    MySQL.update.await("UPDATE `zyke_laptop_shop_orders` SET `status` = 'refundFailed' WHERE `status` = 'refunding'")

    ready:resolve(true)
end)

-- Waits for the table, the sweeps can run before MySQL is ready
function OrderDb.await()
    Citizen.Await(ready)
end

---@param paymentId string
---@param identifier string
---@param product string
---@param quantity integer
function OrderDb.insert(paymentId, identifier, product, quantity)
    MySQL.insert.await("INSERT INTO `zyke_laptop_shop_orders` (payment_id, identifier, product, quantity) VALUES (?, ?, ?, ?)", {paymentId, identifier, product, quantity})
end

---@param paymentId string
---@return ShopOrder? order
function OrderDb.get(paymentId)
    return MySQL.single.await("SELECT payment_id, identifier, product, quantity, status, marked FROM `zyke_laptop_shop_orders` WHERE payment_id = ?", {paymentId})
end

-- Moves an order on only from the status it is expected to have, so two callers can't both win
---@param paymentId string
---@param from ShopOrderStatus
---@param to ShopOrderStatus
---@return boolean moved
function OrderDb.move(paymentId, from, to)
    return MySQL.update.await("UPDATE `zyke_laptop_shop_orders` SET `status` = ? WHERE payment_id = ? AND `status` = ?", {to, paymentId, from}) == 1
end

---@param paymentId string
function OrderDb.setMarked(paymentId)
    MySQL.update.await("UPDATE `zyke_laptop_shop_orders` SET `marked` = 1 WHERE payment_id = ?", {paymentId})
end

-- Payment ids of the orders a sweep still has work on, oldest first: open ones, failed refunds, and finished ones the
-- laptop has not heard about yet
---@param identifier? string @ Only this character's orders
---@return string[] paymentIds
function OrderDb.listWork(identifier)
    local rows = MySQL.query.await([[
        SELECT payment_id FROM `zyke_laptop_shop_orders`
        WHERE (`status` IN ('open', 'refundFailed') OR (`status` IN ('delivered', 'refunded') AND `marked` = 0))
            AND (? IS NULL OR identifier = ?)
        ORDER BY created_at
    ]], {identifier, identifier}) or {}
    local paymentIds = {}

    for i = 1, #rows do
        paymentIds[i] = rows[i].payment_id
    end

    return paymentIds
end