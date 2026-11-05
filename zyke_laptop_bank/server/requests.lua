-- Payment requests. The requester asks, the payer pays or declines in their own app. Every answer changes the row's
-- status with a WHERE on the old status first, so two clicks, or a payer and a cancelling requester at once, can't
-- both win

---@class BankRequestRow
---@field id integer
---@field requester_identifier string
---@field requester_name string
---@field payer_identifier string
---@field payer_name string
---@field amount integer
---@field note string
---@field status "open" | "paying" | "paid" | "declined" | "cancelled" | "expired"

function ExpireRequests()
    MySQL.update.await("UPDATE `zyke_laptop_bank_requests` SET status = 'expired', answered_at = NOW() WHERE status = 'open' AND created_at < NOW() - INTERVAL ? DAY", {Config.requests.expiryDays})
end

-- The requests the page lists: the open ones the character was asked to pay, and the ones they sent
---@param identifier string
---@return {incoming: table[], outgoing: table[]} requests
function GetRequests(identifier)
    ExpireRequests()

    local incoming = MySQL.query.await("SELECT id, requester_name, payer_name, amount, note, status, UNIX_TIMESTAMP(created_at) AS createdAt FROM `zyke_laptop_bank_requests` WHERE payer_identifier = ? AND status = 'open' ORDER BY id DESC", {identifier})
    local outgoing = MySQL.query.await("SELECT id, requester_name, payer_name, amount, note, status, UNIX_TIMESTAMP(created_at) AS createdAt FROM `zyke_laptop_bank_requests` WHERE requester_identifier = ? AND status IN ('open', 'paying') ORDER BY id DESC", {identifier})
    local answered = MySQL.query.await("SELECT id, requester_name, payer_name, amount, note, status, UNIX_TIMESTAMP(created_at) AS createdAt FROM `zyke_laptop_bank_requests` WHERE requester_identifier = ? AND status NOT IN ('open', 'paying') ORDER BY id DESC LIMIT ?", {
        identifier, Config.requests.historyLength,
    })

    for i = 1, #answered do
        outgoing[#outgoing + 1] = answered[i]
    end

    return {incoming = incoming, outgoing = outgoing}
end

---@param id any
---@param identifier string
---@param asPayer boolean @ The character was asked to pay it, otherwise they sent it
---@return BankRequestRow? request
local function getOpenRequest(id, identifier, asPayer)
    local requestId = math.tointeger(tonumber(id))
    if (not requestId) then return nil end
    if (asPayer) then return MySQL.single.await("SELECT * FROM `zyke_laptop_bank_requests` WHERE id = ? AND payer_identifier = ? AND status = 'open'", {requestId, identifier}) end

    return MySQL.single.await("SELECT * FROM `zyke_laptop_bank_requests` WHERE id = ? AND requester_identifier = ? AND status = 'open'", {requestId, identifier})
end

-- Moves the request on from one status to the next, false when someone else moved it first
---@param id integer
---@param from string
---@param to string
---@return boolean moved
local function setStatus(id, from, to)
    return MySQL.update.await("UPDATE `zyke_laptop_bank_requests` SET status = ?, answered_at = IF(? IN ('open', 'paying'), NULL, NOW()) WHERE id = ? AND status = ?", {to, to, id, from}) == 1
end

---@param plyId integer
---@param data table @ {by, value} or {payeeId}, with confirmedName, amount and note?
---@return table result
Z.callback.register("zyke_laptop_bank:CreateRequest", function(plyId, data)
    local sender, err = GetSender(plyId)
    if (not sender) then return {ok = false, error = err} end
    if (type(data) ~= "table") then return {ok = false, error = "error:invalidTarget"} end

    local amount, amountErr, args = ReadAmount(data.amount)
    if (not amount) then return {ok = false, error = amountErr, args = args} end

    local note = ReadNote(data.note)
    if (not note) then return {ok = false, error = "error:noteLength", args = {Config.maxNoteLength}} end
    if (IsOnCooldown(plyId, "send", Config.cooldown)) then return {ok = false, error = "error:cooldown"} end

    local payer, payerErr = ResolveConfirmedRecipient(sender, data)
    if (not payer) then return {ok = false, error = payerErr} end

    local open = MySQL.scalar.await("SELECT COUNT(*) FROM `zyke_laptop_bank_requests` WHERE requester_identifier = ? AND status = 'open'", {sender.identifier})
    if (open >= Config.requests.maxOpen) then return {ok = false, error = "error:requestLimit", args = {Config.requests.maxOpen}} end

    MySQL.insert.await("INSERT INTO `zyke_laptop_bank_requests` (requester_identifier, requester_name, payer_identifier, payer_name, amount, note) VALUES (?, ?, ?, ?, ?, ?)", {
        sender.identifier, sender.name, payer.identifier, payer.name, amount, note,
    })

    if (data.save == true) then PayeeDb.add(sender.identifier, payer) end

    NotifyCharacter(payer.identifier, "notify:requestReceived", {sender.name, FormatMoney(amount)}, "receive")

    return {ok = true, requests = GetRequests(sender.identifier), payees = PayeeDb.list(sender.identifier), sent = {name = payer.name, amount = amount}}
end)

---@param plyId integer
---@param requestId integer
---@return table result
Z.callback.register("zyke_laptop_bank:PayRequest", function(plyId, requestId)
    local sender, err = GetSender(plyId)
    if (not sender) then return {ok = false, error = err} end

    ExpireRequests()

    local request = getOpenRequest(requestId, sender.identifier, true)
    if (not request) then return {ok = false, error = "error:requestGone"} end
    if (not setStatus(request.id, "open", "paying")) then return {ok = false, error = "error:requestGone"} end

    local moveErr = Ledger.move(plyId, request.requester_identifier, request.amount, "Fleeca Banking payment request")
    if (moveErr) then
        setStatus(request.id, "paying", "open")

        return {ok = false, error = moveErr}
    end

    setStatus(request.id, "paying", "paid")

    local requester = {identifier = request.requester_identifier, name = request.requester_name}

    TransactionDb.insert(sender, requester, request.amount, request.note, "request")
    exports.zyke_laptop:PlayAppSound(plyId, "keypad")
    NotifyCharacter(request.requester_identifier, "notify:requestPaid", {sender.name, FormatMoney(request.amount)}, "receive")

    return {ok = true, paid = {name = request.requester_name, amount = request.amount}}
end)

---@param plyId integer
---@param requestId integer
---@return table result
Z.callback.register("zyke_laptop_bank:DeclineRequest", function(plyId, requestId)
    local sender, err = GetSender(plyId)
    if (not sender) then return {ok = false, error = err} end

    local request = getOpenRequest(requestId, sender.identifier, true)
    if (not request or not setStatus(request.id, "open", "declined")) then return {ok = false, error = "error:requestGone"} end

    NotifyCharacter(request.requester_identifier, "notify:requestDeclined", {sender.name, FormatMoney(request.amount)})

    return {ok = true, requests = GetRequests(sender.identifier)}
end)

---@param plyId integer
---@param requestId integer
---@return table result
Z.callback.register("zyke_laptop_bank:CancelRequest", function(plyId, requestId)
    local sender, err = GetSender(plyId)
    if (not sender) then return {ok = false, error = err} end

    local request = getOpenRequest(requestId, sender.identifier, false)
    if (not request or not setStatus(request.id, "open", "cancelled")) then return {ok = false, error = "error:requestGone"} end

    -- The payer's open app drops the request
    RefreshCharacter(request.payer_identifier)

    return {ok = true, requests = GetRequests(sender.identifier)}
end)