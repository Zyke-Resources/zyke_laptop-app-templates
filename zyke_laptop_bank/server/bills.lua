-- Bills paid through the laptop's pay sheet. The server makes each payment with CreatePayment, so the amount never
-- comes from the page, which only shows it with Laptop.pay. A bill counts as paid once zyke_laptop:PaymentSettled
-- arrives, also for payments settled while this resource was stopped
local periodSeconds = Config.billPeriodDays * 86400

-- The fields of zyke_laptop's payment this file reads, the full shape is SdkPayment in sdk/zyke_laptop.lua
---@class BankBillPayment
---@field id string
---@field resource string
---@field identifier string
---@field amount integer
---@field label string
---@field metadata? {bill?: string, name?: string}

---@param billId any
---@return table? bill
local function getBill(billId)
    for i = 1, #Config.bills do
        if (Config.bills[i].id == billId) then return Config.bills[i] end
    end
end

-- Ids of the bills the character paid in the current period
---@param identifier string
---@return table<string, true> paid
local function getPaidBills(identifier)
    local since = os.time() // periodSeconds * periodSeconds
    local payments = exports.zyke_laptop:GetPayments({status = "settled", identifier = identifier, since = since})
    local paid = {}

    for i = 1, #payments do
        local billId = payments[i].metadata and payments[i].metadata.bill
        if (billId) then paid[billId] = true end
    end

    return paid
end

-- The bills as the page shows them
---@param identifier string
---@return {id: string, label: string, amount: integer, paid: boolean}[] bills
function GetBills(identifier)
    local paid = GetResourceState("zyke_laptop") == "started" and getPaidBills(identifier) or {}
    local bills = {}

    for i = 1, #Config.bills do
        local bill = Config.bills[i]

        bills[i] = {id = bill.id, label = T(bill.label), amount = bill.amount, paid = paid[bill.id] == true}
    end

    return bills
end

-- A payment the page can show with Laptop.pay, or the locale key of why there is none
---@param plyId integer
---@param party BankParty
---@param billId any
---@return string? paymentId
---@return string? err
function CreateBillPayment(plyId, party, billId)
    local bill = getBill(billId)
    if (not bill) then return nil, "error:unknownBill" end
    if (getPaidBills(party.identifier)[bill.id]) then return nil, "error:billPaid" end

    local period = os.time() // periodSeconds
    local paymentId = exports.zyke_laptop:CreatePayment(plyId, {
        app = Config.appId,
        amount = bill.amount,
        currency = "either",
        label = T(bill.label),
        lines = {{label = T(bill.label), qty = 1, amount = bill.amount}},
        payee = bill.payee,
        -- A second click in the same period gets the same payment instead of a new one
        idempotencyKey = ("%s:%d:%x"):format(bill.id, period, GetHashKey(party.identifier) & 0xffffffff),
        metadata = {bill = bill.id, name = party.name},
    })
    if (not paymentId) then return nil, "error:payFailed" end

    return paymentId
end

-- Writes the paid bill into the history and tells the laptop it was handled
---@param payment BankBillPayment
local function fulfil(payment)
    TransactionDb.await()

    -- Read from the payment, not the config, so a bill removed from Config.bills since is still recorded
    local billId = payment.metadata and payment.metadata.bill

    if (billId) then
        local payer = {identifier = payment.identifier, name = payment.metadata.name or ""}

        TransactionDb.insertBill(payer, {identifier = "bill:" .. billId, name = payment.label}, payment.amount, payment.id)
    end

    exports.zyke_laptop:MarkPaymentFulfilled(payment.id)

    local plyId = Z.getPlayerId(payment.identifier)
    if (plyId) then TriggerClientEvent("zyke_laptop_bank:Refresh", plyId) end
end

---@param payment BankBillPayment
AddEventHandler("zyke_laptop:PaymentSettled", function(payment)
    if (payment.resource ~= ResName) then return end

    fulfil(payment)
end)

-- Payments settled while this resource was stopped. GetPayments returns 100 at most, and each fulfilled payment drops
-- out of the next call, so it asks again until a call brings nothing new
local function fulfilWaiting()
    if (GetResourceState("zyke_laptop") ~= "started") then return end

    local seen = {}

    while (true) do
        local payments = exports.zyke_laptop:GetPayments({status = "settled", fulfilled = false})
        local fresh = 0

        for i = 1, #payments do
            if (not seen[payments[i].id]) then
                seen[payments[i].id] = true
                fresh += 1

                fulfil(payments[i])
            end
        end

        if (fresh == 0) then return end
    end
end

CreateThread(fulfilWaiting)

-- The laptop started after this resource, or restarted
AddEventHandler("zyke_laptop:Ready", fulfilWaiting)