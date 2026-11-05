-- Saved payees. The page gets each payee's row id and name, and sends the id back; the identifier stays on the server

PayeeDb = {}

---@param ownerIdentifier string
---@return {id: integer, name: string}[] payees @ By name
function PayeeDb.list(ownerIdentifier)
    return MySQL.query.await("SELECT id, name FROM `zyke_laptop_bank_payees` WHERE owner_identifier = ? ORDER BY name", {ownerIdentifier})
end

---@param ownerIdentifier string
---@param payeeId any
---@return string? identifier
function PayeeDb.getIdentifier(ownerIdentifier, payeeId)
    local id = math.tointeger(tonumber(payeeId))
    if (not id) then return nil end

    return MySQL.scalar.await("SELECT payee_identifier FROM `zyke_laptop_bank_payees` WHERE id = ? AND owner_identifier = ?", {id, ownerIdentifier})
end

---@param ownerIdentifier string
---@param payeeIdentifier string
---@return boolean saved
function PayeeDb.isSaved(ownerIdentifier, payeeIdentifier)
    return MySQL.scalar.await("SELECT 1 FROM `zyke_laptop_bank_payees` WHERE owner_identifier = ? AND payee_identifier = ?", {ownerIdentifier, payeeIdentifier}) ~= nil
end

-- Saves the recipient, or refreshes the name of one already saved. Nil once saved, otherwise the locale key of why not
---@param ownerIdentifier string
---@param payee BankParty
---@return string? err
function PayeeDb.add(ownerIdentifier, payee)
    if (not PayeeDb.isSaved(ownerIdentifier, payee.identifier)) then
        local count = MySQL.scalar.await("SELECT COUNT(*) FROM `zyke_laptop_bank_payees` WHERE owner_identifier = ?", {ownerIdentifier})
        if (count >= Config.maxPayees) then return "error:payeeLimit" end
    end

    MySQL.insert.await("INSERT INTO `zyke_laptop_bank_payees` (owner_identifier, payee_identifier, name) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE name = VALUES(name)", {
        ownerIdentifier, payee.identifier, payee.name,
    })
end

-- Saves a recipient the page looked up, by the same {by, value} it confirmed
---@param plyId integer
---@param data table @ {by, value, confirmedName}
---@return table result
Z.callback.register("zyke_laptop_bank:SavePayee", function(plyId, data)
    local sender, err = GetSender(plyId)
    if (not sender) then return {ok = false, error = err} end
    if (IsOnCooldown(plyId, "lookup", Config.lookupCooldown)) then return {ok = false, error = "error:lookupCooldown"} end

    local payee, payeeErr = ResolveConfirmedRecipient(sender, data)
    if (not payee) then return {ok = false, error = payeeErr} end

    local addErr = PayeeDb.add(sender.identifier, payee)
    if (addErr) then return {ok = false, error = addErr, args = {Config.maxPayees}} end

    return {ok = true, payees = PayeeDb.list(sender.identifier)}
end)

---@param plyId integer
---@param payeeId integer
---@return table result
Z.callback.register("zyke_laptop_bank:RemovePayee", function(plyId, payeeId)
    local sender, err = GetSender(plyId)
    if (not sender) then return {ok = false, error = err} end

    local id = math.tointeger(tonumber(payeeId))
    if (not id) then return {ok = false, error = "error:unknownPayee"} end

    MySQL.update.await("DELETE FROM `zyke_laptop_bank_payees` WHERE id = ? AND owner_identifier = ?", {id, sender.identifier})

    return {ok = true, payees = PayeeDb.list(sender.identifier)}
end)