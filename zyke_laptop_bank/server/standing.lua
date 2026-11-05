-- Standing payments: the same amount to the same recipient every N days. ProcessStandingPayments pays the ones due, on a
-- timer and when the payer's character is selected, since Z.money only takes money from a payer who is online. A payer
-- who was away while payments fell due pays once when back, not once per missed period. A payment the balance can't
-- cover stops the standing payment and leaves a note in the history

local daySeconds = 86400

---@class BankStandingRow
---@field id integer
---@field payer_identifier string
---@field payer_name string
---@field receiver_identifier string
---@field receiver_name string
---@field amount integer
---@field note string
---@field interval_days integer
---@field next_run_at integer

-- Active ones first, then the stopped ones the page still shows so the player sees why one ended
---@param identifier string
---@return table[] standing
function GetStandingPayments(identifier)
    return MySQL.query.await([[
        SELECT id, receiver_name AS name, amount, note, interval_days AS intervalDays, next_run_at AS nextRunAt, status
        FROM `zyke_laptop_bank_standing`
        WHERE payer_identifier = ? AND status IN ('active', 'stopped')
        ORDER BY status = 'active' DESC, next_run_at
    ]], {identifier})
end

-- The next due time after a payment: one interval on, moved past now when the payer was away for longer
---@param row BankStandingRow
---@param now integer
---@return integer nextRunAt
local function nextRun(row, now)
    local interval = row.interval_days * daySeconds
    local nextRunAt = row.next_run_at + interval

    if (nextRunAt <= now) then nextRunAt += ((now - nextRunAt) // interval + 1) * interval end

    return nextRunAt
end

---@param row BankStandingRow
local function stop(row)
    MySQL.update.await("UPDATE `zyke_laptop_bank_standing` SET status = 'stopped' WHERE id = ?", {row.id})

    local payer = {identifier = row.payer_identifier, name = row.payer_name}
    local receiver = {identifier = row.receiver_identifier, name = row.receiver_name}

    TransactionDb.insert(payer, receiver, row.amount, row.note, "standingFailed")
    NotifyCharacter(row.payer_identifier, "notify:standingStopped", {FormatMoney(row.amount), row.receiver_name})
end

-- Pays one due standing payment of an online payer. The row is claimed by moving next_run_at on first, so a second run
-- at the same time skips it
---@param plyId integer
---@param row BankStandingRow
---@param now integer
local function pay(plyId, row, now)
    local claimed = MySQL.update.await("UPDATE `zyke_laptop_bank_standing` SET next_run_at = ? WHERE id = ? AND next_run_at = ? AND status = 'active'", {
        nextRun(row, now), row.id, row.next_run_at,
    }) == 1
    if (not claimed) then return end

    local err = Ledger.move(plyId, row.receiver_identifier, row.amount, "Fleeca Banking standing payment")

    if (err == "error:funds") then return stop(row) end

    -- Anything else, such as a framework hiccup, tries again next run
    if (err) then
        MySQL.update.await("UPDATE `zyke_laptop_bank_standing` SET next_run_at = ? WHERE id = ?", {row.next_run_at, row.id})

        return
    end

    local payer = {identifier = row.payer_identifier, name = row.payer_name}
    local receiver = {identifier = row.receiver_identifier, name = row.receiver_name}
    local money = FormatMoney(row.amount)

    TransactionDb.insert(payer, receiver, row.amount, row.note, "standing")
    NotifyCharacter(row.payer_identifier, "notify:standingPaid", {money, row.receiver_name}, "send")
    NotifyCharacter(row.receiver_identifier, "notify:standingReceived", {row.payer_name, money}, "receive")
end

-- Pays every due standing payment whose payer is online, or only those of one payer
---@param identifier? string
function ProcessStandingPayments(identifier)
    local now = os.time()
    local rows = identifier
        and MySQL.query.await("SELECT * FROM `zyke_laptop_bank_standing` WHERE status = 'active' AND next_run_at <= ? AND payer_identifier = ?", {now, identifier})
        or MySQL.query.await("SELECT * FROM `zyke_laptop_bank_standing` WHERE status = 'active' AND next_run_at <= ?", {now})

    for i = 1, #rows do
        local plyId = Z.getPlayerId(rows[i].payer_identifier)
        if (plyId) then pay(plyId, rows[i], now) end
    end
end

---@param plyId integer
---@param data table @ {by, value} or {payeeId}, with confirmedName, amount, intervalDays and note?
---@return table result
Z.callback.register("zyke_laptop_bank:CreateStanding", function(plyId, data)
    local sender, err = GetSender(plyId)
    if (not sender) then return {ok = false, error = err} end
    if (type(data) ~= "table") then return {ok = false, error = "error:invalidTarget"} end

    local amount, amountErr, args = ReadAmount(data.amount)
    if (not amount) then return {ok = false, error = amountErr, args = args} end

    local intervalDays = math.tointeger(tonumber(data.intervalDays))
    if (not intervalDays or intervalDays < Config.standing.minIntervalDays or intervalDays > Config.standing.maxIntervalDays) then
        return {ok = false, error = "error:interval", args = {Config.standing.minIntervalDays, Config.standing.maxIntervalDays}}
    end

    local note = ReadNote(data.note)
    if (not note) then return {ok = false, error = "error:noteLength", args = {Config.maxNoteLength}} end
    if (IsOnCooldown(plyId, "send", Config.cooldown)) then return {ok = false, error = "error:cooldown"} end

    local receiver, receiverErr = ResolveConfirmedRecipient(sender, data)
    if (not receiver) then return {ok = false, error = receiverErr} end

    -- The first payment goes out at once, so it has to be covered now
    if ((Z.money.get(plyId, Config.account) or 0) < amount) then return {ok = false, error = "error:funds"} end

    local active = MySQL.scalar.await("SELECT COUNT(*) FROM `zyke_laptop_bank_standing` WHERE payer_identifier = ? AND status = 'active'", {sender.identifier})
    if (active >= Config.standing.maxActive) then return {ok = false, error = "error:standingLimit", args = {Config.standing.maxActive}} end

    MySQL.insert.await("INSERT INTO `zyke_laptop_bank_standing` (payer_identifier, payer_name, receiver_identifier, receiver_name, amount, note, interval_days, next_run_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?)", {
        sender.identifier, sender.name, receiver.identifier, receiver.name, amount, note, intervalDays, os.time(),
    })

    if (data.save == true) then PayeeDb.add(sender.identifier, receiver) end

    ProcessStandingPayments(sender.identifier)

    return {ok = true}
end)

---@param plyId integer
---@param standingId integer
---@return table result
Z.callback.register("zyke_laptop_bank:CancelStanding", function(plyId, standingId)
    local sender, err = GetSender(plyId)
    if (not sender) then return {ok = false, error = err} end

    local id = math.tointeger(tonumber(standingId))
    if (not id) then return {ok = false, error = "error:standingGone"} end

    -- A stopped one is cancelled too, which only takes it off the list
    MySQL.update.await("UPDATE `zyke_laptop_bank_standing` SET status = 'cancelled' WHERE id = ? AND payer_identifier = ? AND status IN ('active', 'stopped')", {id, sender.identifier})

    return {ok = true, standing = GetStandingPayments(sender.identifier)}
end)