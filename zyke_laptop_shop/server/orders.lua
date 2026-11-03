-- Orders. The page only says what and how many, the price comes from config.lua. The items are given in
-- zyke_laptop:PaymentSettled, never when the page's Laptop.pay resolves: the page can close, the event always comes.
-- server/database.lua keeps every order, so the sweeps below pick up whatever an event missed

-- The fields of zyke_laptop's payment this file reads, the full shape is SdkPayment in sdk/zyke_laptop.lua
---@class ShopPayment
---@field id string
---@field resource string
---@field status string
---@field amount integer
---@field refunded integer

local failedPayments = {cancelled = true, expired = true, failed = true}

---@param data any @ {product, quantity} from the page
---@return ShopProduct? product
---@return integer? quantity
local function readOrder(data)
    if (type(data) ~= "table") then return nil end

    local product = GetProduct(data.product)
    local quantity = math.tointeger(tonumber(data.quantity))
    if (not product or not quantity or quantity < 1 or quantity > product.maxQuantity) then return nil end

    return product, quantity
end

-- Tells the laptop the order is handled, so its health check stops listing it
---@param paymentId string
local function markHandled(paymentId)
    if (exports.zyke_laptop:MarkPaymentFulfilled(paymentId)) then OrderDb.setMarked(paymentId) end
end

---@param plyId integer
---@param outcome "delivered" | "refunded" | "refundFailed"
---@param order ShopOrder
local function tellBuyer(plyId, outcome, order)
    local product = GetProduct(order.product)

    TriggerClientEvent("zyke_laptop_shop:OrderHandled", plyId, outcome, product and GetProductLabel(product) or order.product, order.quantity)
end

-- Gives the items, claimed as giving first so they can never be given twice. "refund" when they can't be given, nil
-- when another caller has the order or it went back to open
---@param plyId integer
---@param order ShopOrder
---@return "given" | "refund" | nil result
local function give(plyId, order)
    local product = GetProduct(order.product)
    if (not product or not Z.canCarryItem(plyId, product.item, order.quantity)) then return "refund" end
    if (not OrderDb.move(order.payment_id, "open", "giving")) then return nil end

    order.status = "giving"

    -- Read again after the claim, which waits on the database: staff may have refunded the payment meanwhile, and the
    -- player may have switched to another character, who must not get this one's order
    local payment = exports.zyke_laptop:GetPayment(order.payment_id)
    if (not payment or payment.refunded > 0) then return "refund" end

    if (Z.getIdentifier(plyId) ~= order.identifier) then
        OrderDb.move(order.payment_id, "giving", "open")

        return nil
    end

    if (Z.addItem(plyId, product.item, order.quantity) ~= true) then return "refund" end

    OrderDb.move(order.payment_id, "giving", "delivered")

    return "given"
end

-- Gives the money back, claimed as refunding first so two callers can't both try. The laptop's refund is atomic and a
-- fully refunded payment counts as done, so a retry never pays twice. A failed refund becomes refundFailed and the
-- next sweep tries again
---@param plyId integer
---@param order ShopOrder
local function refund(plyId, order)
    local previous = order.status
    if (not OrderDb.move(order.payment_id, previous, "refunding")) then return end

    local payment = exports.zyke_laptop:GetPayment(order.payment_id)
    local refunded = false

    if (payment) then
        refunded = payment.refunded >= payment.amount or exports.zyke_laptop:RefundPayment(payment.id, {reason = T("refund:reason")}) == true
    end

    OrderDb.move(order.payment_id, "refunding", refunded and "refunded" or "refundFailed")

    if (refunded) then markHandled(order.payment_id) end

    -- Told once, not again on every retry
    if (refunded or previous ~= "refundFailed") then tellBuyer(plyId, refunded and "refunded" or "refundFailed", order) end
end

-- Moves one order as far as it can go now: closed when it was never paid, delivered or refunded once the buyer is on.
-- Every step is a claim in the database, so the settle event and a sweep can work on the same order at once
---@param paymentId string
local function deliver(paymentId)
    -- Before the startup check in server/database.lua ran, a claim made now would be taken for a cut-off one
    OrderDb.await()

    local order = OrderDb.get(paymentId)
    if (not order) then return end

    -- Finished, but the laptop wasn't told before a stop
    if (order.status == "delivered" or order.status == "refunded") then return markHandled(paymentId) end
    if (order.status ~= "open" and order.status ~= "refundFailed") then return end

    ---@type ShopPayment?
    local payment = exports.zyke_laptop:GetPayment(paymentId)
    if (not payment) then return end
    if (failedPayments[payment.status]) then return OrderDb.move(paymentId, order.status, "closed") end
    if (payment.status ~= "settled") then return end

    -- Offline: worked on again when the character loads
    local plyId = Z.getPlayerId(order.identifier)
    if (not plyId) then return end
    if (order.status == "refundFailed" or payment.refunded > 0) then return refund(plyId, order) end

    local result = give(plyId, order)

    if (result == "given") then
        markHandled(paymentId)
        tellBuyer(plyId, "delivered", order)
    elseif (result == "refund") then
        refund(plyId, order)
    end
end

-- Every order with work left, all of them or one character's
---@param identifier? string
local function deliverWaiting(identifier)
    if (GetResourceState("zyke_laptop") ~= "started") then return end

    OrderDb.await()

    local paymentIds = OrderDb.listWork(identifier)

    for i = 1, #paymentIds do
        deliver(paymentIds[i])
    end
end

---@param plyId integer
---@param data any @ {product, quantity}
---@return {ok: boolean, paymentId?: string, error?: string} result
Z.callback.register("zyke_laptop_shop:Checkout", function(plyId, data)
    -- IsAtLaptop is the laptop's own check that this player has a laptop out or stands at a placed one
    if (GetResourceState("zyke_laptop") ~= "started" or not exports.zyke_laptop:IsAtLaptop(plyId)) then return {ok = false, error = "error:notAtLaptop"} end

    local identifier = Z.getIdentifier(plyId)
    if (not identifier) then return {ok = false, error = "error:unavailable"} end

    local product, quantity = readOrder(data)
    if (not product or not quantity) then return {ok = false, error = "error:invalid"} end

    -- Checked again on delivery, this only spares the player a payment that would be refunded
    if (not Z.canCarryItem(plyId, product.item, quantity)) then return {ok = false, error = "error:cantCarry"} end

    -- Before the payment exists, so a payment is never made for an order that can't be saved
    OrderDb.await()

    local label = GetProductLabel(product)
    local amount = product.price * quantity
    local paymentId = exports.zyke_laptop:CreatePayment(plyId, {
        app = Config.site.id,
        kind = "site",
        amount = amount,
        label = T("order:label", {quantity, label}),
        -- A line's amount is the line's total, and the lines add up to the payment's amount
        lines = {{label = label, qty = quantity, amount = amount}},
        payee = Config.payee,
    })
    if (not paymentId) then return {ok = false, error = "error:payFailed"} end

    -- Written before the page can show the payment, so the order exists by the time it settles
    OrderDb.insert(paymentId, identifier, product.id, quantity)

    return {ok = true, paymentId = paymentId}
end)

---@param payment ShopPayment
AddEventHandler("zyke_laptop:PaymentSettled", function(payment)
    if (payment.resource ~= ResName) then return end

    deliver(payment.id)
end)

---@param plyId integer
AddEventHandler("zyke_lib:OnCharacterSelect", function(plyId)
    local identifier = Z.getIdentifier(plyId)
    if (not identifier) then return end

    deliverWaiting(identifier)
end)

-- The laptop started after this resource, or restarted
AddEventHandler("zyke_laptop:Ready", function()
    deliverWaiting()
end)

-- Orders paid while this resource was stopped
CreateThread(function()
    deliverWaiting()
end)