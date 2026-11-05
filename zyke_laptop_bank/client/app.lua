-- Passes the page's posts on to the server, which checks and does everything itself, and shows the notifications.
-- server/register.lua registers the app

local unavailable = {ok = false, error = "error:unavailable"}

-- The tab a notification opens, by its locale key. The rest open the overview
local notificationTabs = {
    ["notify:requestReceived"] = "requests",
    ["notify:requestPaid"] = "requests",
    ["notify:requestDeclined"] = "requests",
    ["notify:standingStopped"] = "standing",
}

---@return boolean started
local function isLaptopStarted()
    return GetResourceState("zyke_laptop") == "started"
end

-- An OS notification while the laptop's OS runs, the framework's own one otherwise
---@param text string
---@param sound? "send" | "receive" @ Played instead of the OS's notification chime
---@param tab? string @ The page's tab a click on the notification opens
local function notify(text, sound, tab)
    local notification = {title = T("notify:title"), text = text, icon = "landmark", appId = Config.appId, params = tab and {tab = tab} or nil, sound = sound}

    if (isLaptopStarted() and exports.zyke_laptop:Notify(notification)) then return end

    Z.notify(text, nil, nil, true)
end

-- Reaches the page only while the app is open, which then loads the account again
local function refreshPage()
    if (isLaptopStarted()) then exports.zyke_laptop:SendAppMessage(Config.appId, {refresh = true}) end
end

-- An NUI callback that hands the page's data to a server callback and the answer back
---@param endpoint string
---@param serverCallback string
---@param onResult? fun(result: table)
local function forward(endpoint, serverCallback, onResult)
    RegisterNUICallback(endpoint, function(data, cb)
        local result = Z.callback.request(serverCallback, nil, data) or unavailable

        if (onResult and result.ok) then onResult(result) end

        cb(result)
    end)
end

-- The page gets every string of the locale file and the limits it checks before posting
---@param _ table
---@param cb fun(setup: table)
RegisterNUICallback("Setup", function(_, cb)
    local strings = {}

    for key, value in pairs(Translations) do
        if (type(value) == "string") then strings[key] = value end
    end

    cb({
        strings = strings,
        minAmount = Config.minAmount,
        maxAmount = Config.maxAmount,
        maxNoteLength = Config.maxNoteLength,
        minIntervalDays = Config.standing.minIntervalDays,
        maxIntervalDays = Config.standing.maxIntervalDays,
        historyPageSize = Config.historyPageSize,
    })
end)

forward("GetAccount", "zyke_laptop_bank:GetAccount")
forward("GetHistory", "zyke_laptop_bank:GetHistory")
forward("FindRecipient", "zyke_laptop_bank:FindRecipient")
forward("SavePayee", "zyke_laptop_bank:SavePayee")
forward("RemovePayee", "zyke_laptop_bank:RemovePayee")
forward("DeclineRequest", "zyke_laptop_bank:DeclineRequest")
forward("CancelRequest", "zyke_laptop_bank:CancelRequest")
forward("CancelStanding", "zyke_laptop_bank:CancelStanding")

-- The server makes the payment and answers its id, the page shows it with Laptop.pay
forward("PayBill", "zyke_laptop_bank:PayBill")

-- The OS notification is the sender's only confirmation, the page just shows the new balance
---@param result {sent: {name: string, amount: integer, held: boolean}}
forward("Transfer", "zyke_laptop_bank:Transfer", function(result)
    notify(T(result.sent.held and "notify:sentHeld" or "notify:sent", {FormatMoney(result.sent.amount), result.sent.name}), "send")
end)

---@param result {sent: {name: string, amount: integer}}
forward("CreateRequest", "zyke_laptop_bank:CreateRequest", function(result)
    notify(T("notify:requestSent", {FormatMoney(result.sent.amount), result.sent.name}), "send")
end)

---@param result {paid: {name: string, amount: integer}}
forward("PayRequest", "zyke_laptop_bank:PayRequest", function(result)
    notify(T("notify:sent", {FormatMoney(result.paid.amount), result.paid.name}), "send")
end)

-- The first payment's own notification comes from the server
forward("CreateStanding", "zyke_laptop_bank:CreateStanding")

-- Something happened to this character's account while they were not looking: money arrived, a request was answered or a
-- standing payment ran. args are already formatted by the server
---@param key string
---@param args any[]
---@param sound? "send" | "receive"
RegisterNetEvent("zyke_laptop_bank:Notify", function(key, args, sound)
    notify(T(key, args), sound, notificationTabs[key])
    refreshPage()
end)

-- A bill was paid or a request withdrawn, the open app loads the account again
RegisterNetEvent("zyke_laptop_bank:Refresh", refreshPage)