-- The account overview and transfers. The page only asks, this file decides: the amount, the recipient and the balance
-- are read again here, since anything the page sends can be made up

-- Transactions the overview lists
local recentLength = 5

-- A transaction as the page shows it, without anyone's identifier
---@param row BankTransactionRow
---@param identifier string @ The viewer's
---@return table transaction
function FormatTransaction(row, identifier)
    local isOut = row.sender_identifier == identifier

    return {
        id = row.id,
        direction = isOut and "out" or "in",
        name = isOut and row.receiver_name or row.sender_name,
        amount = row.amount,
        note = row.note,
        kind = row.kind,
        createdAt = row.createdAt,
    }
end

---@param plyId integer
---@param party BankParty
---@return table account
local function buildAccount(plyId, party)
    local rows = TransactionDb.listFor(party.identifier, {direction = "all", search = "", offset = 0}, recentLength)
    local recent = {}

    for i = 1, #rows do
        recent[i] = FormatTransaction(rows[i], party.identifier)
    end

    return {
        ok = true,
        name = party.name,
        balance = Z.money.get(plyId, Config.account) or 0,
        recent = recent,
        summary = TransactionDb.summary(party.identifier, Config.summaryMonths),
        bills = GetBills(party.identifier),
        payees = PayeeDb.list(party.identifier),
        requests = GetRequests(party.identifier),
        standing = GetStandingPayments(party.identifier),
    }
end

---@param plyId integer
---@return table account
Z.callback.register("zyke_laptop_bank:GetAccount", function(plyId)
    local sender, err = GetSender(plyId)
    if (not sender) then return {ok = false, error = err} end

    return buildAccount(plyId, sender)
end)

---@param plyId integer
---@param data table @ {by, value} or {payeeId}, with confirmedName, amount, note? and save?
---@return table result
Z.callback.register("zyke_laptop_bank:Transfer", function(plyId, data)
    local sender, err = GetSender(plyId)
    if (not sender) then return {ok = false, error = err} end
    if (type(data) ~= "table") then return {ok = false, error = "error:invalidTarget"} end

    local amount, amountErr, args = ReadAmount(data.amount)
    if (not amount) then return {ok = false, error = amountErr, args = args} end

    local note = ReadNote(data.note)
    if (not note) then return {ok = false, error = "error:noteLength", args = {Config.maxNoteLength}} end
    if (IsOnCooldown(plyId, "send", Config.cooldown)) then return {ok = false, error = "error:cooldown"} end

    local receiver, receiverErr = ResolveConfirmedRecipient(sender, data)
    if (not receiver) then return {ok = false, error = receiverErr} end

    local moveErr = Ledger.move(plyId, receiver.identifier, amount, "Fleeca Banking transfer")
    if (moveErr) then return {ok = false, error = moveErr} end

    TransactionDb.insert(sender, receiver, amount, note, "transfer")

    if (data.save == true) then PayeeDb.add(sender.identifier, receiver) end

    -- A world sound everyone near the sender hears, as they confirm the transfer. Pages can't play world sounds
    exports.zyke_laptop:PlayAppSound(plyId, "keypad")

    local money = FormatMoney(amount)

    NotifyCharacter(receiver.identifier, note ~= "" and "notify:receivedNote" or "notify:received", {sender.name, money, note}, "receive")

    local account = buildAccount(plyId, sender)

    account.sent = {name = receiver.name, amount = amount, held = not receiver.online}

    return account
end)

-- Answers the payment the page shows with Laptop.pay, see server/bills.lua
---@param plyId integer
---@param billId string
---@return {ok: boolean, paymentId?: string, error?: string} result
Z.callback.register("zyke_laptop_bank:PayBill", function(plyId, billId)
    local sender, err = GetSender(plyId)
    if (not sender) then return {ok = false, error = err} end

    local paymentId, payErr = CreateBillPayment(plyId, sender, billId)
    if (not paymentId) then return {ok = false, error = payErr} end

    return {ok = true, paymentId = paymentId}
end)