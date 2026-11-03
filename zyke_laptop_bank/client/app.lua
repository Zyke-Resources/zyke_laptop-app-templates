-- Passes the page's posts on to the server, which checks and does everything itself, and shows the notifications.
-- server/register.lua registers the app

---@return boolean started
local function isLaptopStarted()
    return GetResourceState("zyke_laptop") == "started"
end

-- An OS notification while the laptop's OS runs, the framework's own one otherwise
---@param text string
---@param sound? "send" | "receive" @ Played instead of the OS's notification chime
local function notify(text, sound)
    if (isLaptopStarted() and exports.zyke_laptop:Notify({title = T("notify:title"), text = text, icon = "landmark", appId = Config.appId, sound = sound})) then return end

    Z.notify(text, nil, nil, true)
end

-- The page gets every string of the locale file and the limits it checks before posting
---@param _ table
---@param cb fun(setup: table)
RegisterNUICallback("Setup", function(_, cb)
    local strings = {}

    for key, value in pairs(Translations) do
        if (type(value) == "string") then strings[key] = value end
    end

    cb({strings = strings, minAmount = Config.minAmount, maxAmount = Config.maxAmount, maxNoteLength = Config.maxNoteLength})
end)

---@param _ table
---@param cb fun(account: table)
RegisterNUICallback("GetAccount", function(_, cb)
    cb(Z.callback.request("zyke_laptop_bank:GetAccount") or {ok = false, error = "error:unavailable"})
end)

-- The OS notification is the sender's only confirmation, the page just shows the new balance
---@param data table @ {targetId, amount, note?}
---@param cb fun(result: table)
RegisterNUICallback("Transfer", function(data, cb)
    local result = Z.callback.request("zyke_laptop_bank:Transfer", nil, data) or {ok = false, error = "error:unavailable"}

    if (result.ok) then notify(T("notify:sent", {FormatMoney(result.sent.amount), result.sent.name}), "send") end

    cb(result)
end)

-- The server makes the payment and answers its id, the page shows it with Laptop.pay
---@param data {billId?: string}
---@param cb fun(result: table)
RegisterNUICallback("PayBill", function(data, cb)
    local billId = type(data) == "table" and data.billId or nil

    cb(Z.callback.request("zyke_laptop_bank:PayBill", nil, billId) or {ok = false, error = "error:unavailable"})
end)

---@param senderName string
---@param amount integer
---@param note string
RegisterNetEvent("zyke_laptop_bank:Received", function(senderName, amount, note)
    local money = FormatMoney(amount)

    notify(note ~= "" and T("notify:receivedNote", {senderName, money, note}) or T("notify:received", {senderName, money}), "receive")

    -- Reaches the page only while the app is open, which then loads the account again
    if (isLaptopStarted()) then exports.zyke_laptop:SendAppMessage(Config.appId, {refresh = true}) end
end)

-- A bill was paid, the open app loads the account again
RegisterNetEvent("zyke_laptop_bank:Refresh", function()
    if (isLaptopStarted()) then exports.zyke_laptop:SendAppMessage(Config.appId, {refresh = true}) end
end)