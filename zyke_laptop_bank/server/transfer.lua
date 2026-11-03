-- The page only asks, this file decides. Every callback checks that the player stands at a laptop, and a transfer
-- reads the amount, the recipient and the balance again here, since anything the page sends can be made up

-- GetGameTimer of each player's last transfer, for Config.cooldown
---@type table<integer, integer>
local lastTransfers = {}

---@param plyId integer
---@return BankParty? party
local function getParty(plyId)
    local identifier = Z.getIdentifier(plyId)
    if (not identifier) then return nil end

    local character = Z.getCharacter(identifier)
    if (not character) then return nil end

    local name = ("%s %s"):format(character.firstname or "", character.lastname or ""):match("^%s*(.-)%s*$")

    return {identifier = identifier, name = name ~= "" and name or T("page:accountHolder")}
end

-- The character behind a request from the app, or the locale key of why there is none
---@param plyId integer
---@return BankParty? party
---@return string? err
local function getSender(plyId)
    -- IsAtLaptop is the laptop's own check that this player has a laptop out or stands at a placed one
    if (GetResourceState("zyke_laptop") ~= "started" or not exports.zyke_laptop:IsAtLaptop(plyId)) then return nil, "error:notAtLaptop" end

    local party = getParty(plyId)
    if (not party) then return nil, "error:noCharacter" end

    return party
end

-- What the page shows: the name, the balance and the latest transactions, without anyone's identifier
---@param plyId integer
---@param party BankParty
---@return table account
local function buildAccount(plyId, party)
    local rows = TransactionDb.listFor(party.identifier, Config.historyLength)
    local transactions = {}

    for i = 1, #rows do
        local row = rows[i]
        local isOut = row.sender_identifier == party.identifier

        transactions[i] = {
            id = row.id,
            direction = isOut and "out" or "in",
            name = isOut and row.receiver_name or row.sender_name,
            amount = row.amount,
            note = row.note,
            createdAt = row.createdAt,
        }
    end

    return {ok = true, name = party.name, balance = Z.money.get(plyId, Config.account) or 0, transactions = transactions, bills = GetBills(party.identifier)}
end

-- Drops control characters and surrounding spaces, nil when the note is too long or not text
---@param value any
---@return string? note
local function readNote(value)
    if (value == nil) then return "" end
    if (type(value) ~= "string") then return nil end

    local note = value:gsub("%c", " "):match("^%s*(.-)%s*$")
    local length = utf8.len(note)
    if (not length or length > Config.maxNoteLength) then return nil end

    return note
end

---@param data any
---@return {targetId: integer, amount: integer, note: string}? transfer
---@return string? err
---@return any[]? args @ Values for the error's placeholders
local function readTransfer(data)
    if (type(data) ~= "table") then return nil, "error:invalidTarget" end

    -- math.tointeger turns 250.0 into 250 and refuses 2.5
    local targetId = math.tointeger(tonumber(data.targetId))
    if (not targetId or targetId <= 0) then return nil, "error:invalidTarget" end

    local amount = math.tointeger(tonumber(data.amount))
    if (not amount or amount < Config.minAmount or amount > Config.maxAmount) then return nil, "error:amount", {FormatMoney(Config.minAmount), FormatMoney(Config.maxAmount)} end

    local note = readNote(data.note)
    if (not note) then return nil, "error:noteLength", {Config.maxNoteLength} end

    return {targetId = targetId, amount = amount, note = note}
end

-- Moves the money, nil once it is done. The balances are read back because the frameworks' remove and add don't
-- say whether they worked
---@param plyId integer
---@param targetId integer
---@param amount integer
---@return string? err
local function moveMoney(plyId, targetId, amount)
    local balance = Z.money.get(plyId, Config.account)
    if (not balance or balance < amount) then return "error:funds" end

    local targetBalance = Z.money.get(targetId, Config.account)
    if (not targetBalance) then return "error:targetOffline" end

    Z.money.remove(plyId, Config.account, amount, "Fleeca Banking transfer")

    if (Z.money.get(plyId, Config.account) ~= balance - amount) then return "error:failed" end

    Z.money.add(targetId, Config.account, amount, "Fleeca Banking transfer")

    if (Z.money.get(targetId, Config.account) ~= targetBalance + amount) then
        Z.money.add(plyId, Config.account, amount, "Fleeca Banking transfer refund")

        return "error:failed"
    end
end

---@param plyId integer
---@return table account
Z.callback.register("zyke_laptop_bank:GetAccount", function(plyId)
    local sender, err = getSender(plyId)
    if (not sender) then return {ok = false, error = err} end

    return buildAccount(plyId, sender)
end)

---@param plyId integer
---@param data table @ {targetId, amount, note?}
---@return table result
Z.callback.register("zyke_laptop_bank:Transfer", function(plyId, data)
    local sender, err = getSender(plyId)
    if (not sender) then return {ok = false, error = err} end

    local lastTransfer = lastTransfers[plyId]
    if (lastTransfer and GetGameTimer() - lastTransfer < Config.cooldown * 1000) then return {ok = false, error = "error:cooldown"} end

    local transfer, transferErr, args = readTransfer(data)
    if (not transfer) then return {ok = false, error = transferErr, args = args} end
    if (transfer.targetId == plyId) then return {ok = false, error = "error:self"} end

    local receiver = GetPlayerName(transfer.targetId) and getParty(transfer.targetId)
    if (not receiver) then return {ok = false, error = "error:targetOffline"} end

    local moveErr = moveMoney(plyId, transfer.targetId, transfer.amount)
    if (moveErr) then return {ok = false, error = moveErr} end

    -- Set before the database call below yields, so a second click waiting behind it is turned away
    lastTransfers[plyId] = GetGameTimer()

    TransactionDb.insert(sender, receiver, transfer.amount, transfer.note)

    -- A world sound everyone near the sender hears, as they confirm the transfer. Pages can't play world sounds
    exports.zyke_laptop:PlayAppSound(plyId, "keypad")

    TriggerClientEvent("zyke_laptop_bank:Received", transfer.targetId, sender.name, transfer.amount, transfer.note)

    local account = buildAccount(plyId, sender)

    account.sent = {name = receiver.name, amount = transfer.amount}

    return account
end)

-- Answers the payment the page shows with Laptop.pay, see server/bills.lua
---@param plyId integer
---@param billId string
---@return {ok: boolean, paymentId?: string, error?: string} result
Z.callback.register("zyke_laptop_bank:PayBill", function(plyId, billId)
    local sender, err = getSender(plyId)
    if (not sender) then return {ok = false, error = err} end

    local paymentId, payErr = CreateBillPayment(plyId, sender, billId)
    if (not paymentId) then return {ok = false, error = payErr} end

    return {ok = true, paymentId = paymentId}
end)

AddEventHandler("playerDropped", function()
    lastTransfers[source] = nil
end)