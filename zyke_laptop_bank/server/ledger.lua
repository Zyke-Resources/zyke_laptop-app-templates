-- Every money move of the app goes through Ledger.move. Z.money only reaches characters who are online, so money for an
-- offline recipient waits in zyke_laptop_bank_held and is paid out when they are next in

Ledger = {}

---@param identifier string
---@param amount integer
local function hold(identifier, amount)
    MySQL.insert.await("INSERT INTO `zyke_laptop_bank_held` (identifier, amount) VALUES (?, ?)", {identifier, amount})
end

-- Pays an online character, true once the balance shows it. The frameworks' add doesn't say whether it worked
---@param plyId integer
---@param amount integer
---@param reason string
---@return boolean added
local function addTo(plyId, amount, reason)
    local balance = Z.money.get(plyId, Config.account)
    if (not balance) then return false end

    Z.money.add(plyId, Config.account, amount, reason)

    return Z.money.get(plyId, Config.account) == balance + amount
end

-- Takes the money from an online payer and pays the recipient, or holds it for them while they are offline. Nil once it
-- is done, otherwise the locale key of why nothing moved
---@param payerId integer
---@param receiverIdentifier string
---@param amount integer
---@param reason string @ The framework's transaction text
---@return string? err
function Ledger.move(payerId, receiverIdentifier, amount, reason)
    local balance = Z.money.get(payerId, Config.account)
    if (not balance or balance < amount) then return "error:funds" end
    if (not Z.money.remove(payerId, Config.account, amount, reason)) then return "error:funds" end

    local receiverId = Z.getPlayerId(receiverIdentifier)
    if (not receiverId) then
        if (not Config.offlineRecipients) then
            Z.money.add(payerId, Config.account, amount, reason)

            return "error:targetOffline"
        end

        hold(receiverIdentifier, amount)

        return
    end

    if (addTo(receiverId, amount, reason)) then return end

    Z.money.add(payerId, Config.account, amount, reason)

    return "error:failed"
end

-- Pays out the money held for a character who is now online. Each row is deleted before it is paid, so two runs at
-- once can't pay it twice, and put back if the payment didn't arrive
---@param plyId integer
---@param identifier string
function Ledger.payHeld(plyId, identifier)
    local rows = MySQL.query.await("SELECT id, amount FROM `zyke_laptop_bank_held` WHERE identifier = ?", {identifier})
    local total = 0

    for i = 1, #rows do
        local row = rows[i]

        if (MySQL.update.await("DELETE FROM `zyke_laptop_bank_held` WHERE id = ?", {row.id}) == 1) then
            if (addTo(plyId, row.amount, "Fleeca Banking")) then
                total += row.amount
            else
                hold(identifier, row.amount)
            end
        end
    end

    if (total > 0) then NotifyCharacter(identifier, "notify:heldPaid", {FormatMoney(total)}, "receive") end
end

-- Held money of everyone in the city, for money held while they were already online but not yet loaded
function Ledger.payAllHeld()
    local rows = MySQL.query.await("SELECT DISTINCT identifier FROM `zyke_laptop_bank_held`")

    for i = 1, #rows do
        local plyId = Z.getPlayerId(rows[i].identifier)
        if (plyId) then Ledger.payHeld(plyId, rows[i].identifier) end
    end
end