-- Finds the character a transfer, request or standing payment is for: by phone number, full name, server ID or a saved
-- payee. The page shows the name it gets back before the player confirms, and the confirmed send looks the recipient up
-- again, so the page never holds anyone's identifier

---@class BankRecipient : BankParty
---@field online boolean

-- Locale keys for the reasons Z.getPhoneNumberOwner gives
local phoneErrors = {
    noNumber = "error:noNumber",
    offlineUnsupported = "error:numberOffline",
    noPhoneSystem = "error:phoneUnsupported",
    unsupported = "error:phoneUnsupported",
    failed = "error:phoneUnsupported",
}

---@param identifier string
---@return BankRecipient? recipient
---@return string? err
local function fromIdentifier(identifier)
    local party = GetPartyByIdentifier(identifier)
    if (not party) then return nil, "error:recipientNotFound" end

    local online = Z.getPlayerId(identifier) ~= nil
    if (not online and not Config.offlineRecipients) then return nil, "error:targetOffline" end

    return {identifier = identifier, name = party.name, online = online}
end

---@param value any
---@return BankRecipient? recipient
---@return string? err
local function byPhone(value)
    if (type(value) ~= "string" or #value > 32 or not Z.normalizePhoneNumber(value)) then return nil, "error:invalidPhone" end

    -- Phones store numbers in their own format, so the number is passed on as the player typed it
    local identifier, _, reason = Z.getPhoneNumberOwner(value:match("^%s*(.-)%s*$"))
    if (not identifier) then return nil, phoneErrors[reason] or "error:noNumber" end

    return fromIdentifier(identifier)
end

-- The characters with exactly this full name, two at most since two already make it ambiguous
---@param name string
---@return string[] identifiers
local function findByName(name)
    local wanted = name:lower()
    local found = {}
    local players = Z.getPlayers()

    for i = 1, #players do
        local party = GetParty(players[i])

        if (party and party.name:lower() == wanted) then
            found[#found + 1] = party.identifier

            if (#found == 2) then return found end
        end
    end

    if (not Config.nameLookupOffline) then return found end

    local sql, params = Z.getCharactersQuery()
    if (not sql) then return found end

    params[#params + 1] = wanted

    -- sql is zyke_lib's own fixed SELECT of the framework's characters, the name goes in as a parameter
    local rows = MySQL.query.await(("SELECT `identifier` FROM (%s) AS `c` WHERE LOWER(TRIM(CONCAT(`firstname`, ' ', `lastname`))) = ? LIMIT 2"):format(sql), params)
    local merged = {}

    for i = 1, #found do
        merged[found[i]] = true
    end

    for i = 1, #rows do
        if (not merged[rows[i].identifier]) then
            merged[rows[i].identifier] = true
            found[#found + 1] = rows[i].identifier
        end
    end

    return found
end

---@param value any
---@return BankRecipient? recipient
---@return string? err
local function byName(value)
    if (type(value) ~= "string") then return nil, "error:invalidName" end

    -- Spaces between the names collapse to one, as the database keeps them
    local name = value:gsub("%s+", " "):match("^%s*(.-)%s*$")
    if (not name:find(" ") or utf8.len(name) == nil or utf8.len(name) > 64) then return nil, "error:invalidName" end

    local found = findByName(name)
    if (#found == 0) then return nil, "error:nameNotFound" end
    if (#found > 1) then return nil, "error:nameAmbiguous" end

    return fromIdentifier(found[1])
end

---@param value any
---@return BankRecipient? recipient
---@return string? err
local function byServerId(value)
    local targetId = math.tointeger(tonumber(value))
    if (not targetId or targetId <= 0) then return nil, "error:invalidTarget" end
    if (not GetPlayerName(targetId)) then return nil, "error:targetOffline" end

    local identifier = Z.getIdentifier(targetId)
    if (not identifier) then return nil, "error:targetOffline" end

    return fromIdentifier(identifier)
end

local lookups = {phone = byPhone, name = byName, id = byServerId}

-- data is {by = "phone" | "name" | "id", value} or {payeeId}
---@param sender BankParty
---@param data any
---@return BankRecipient? recipient
---@return string? err
function ResolveRecipient(sender, data)
    if (type(data) ~= "table") then return nil, "error:invalidTarget" end

    local recipient, err

    if (data.payeeId ~= nil) then
        local identifier = PayeeDb.getIdentifier(sender.identifier, data.payeeId)
        if (not identifier) then return nil, "error:unknownPayee" end

        recipient, err = fromIdentifier(identifier)
    else
        local lookup = lookups[data.by]
        if (not lookup) then return nil, "error:invalidTarget" end

        recipient, err = lookup(data.value)
    end

    if (not recipient) then return nil, err end
    if (recipient.identifier == sender.identifier) then return nil, "error:self" end

    return recipient
end

-- For a confirmed send: the same lookup again, refused when it now finds someone else, such as a server ID that
-- changed hands since the player confirmed
---@param sender BankParty
---@param data any
---@return BankRecipient? recipient
---@return string? err
function ResolveConfirmedRecipient(sender, data)
    local recipient, err = ResolveRecipient(sender, data)
    if (not recipient) then return nil, err end
    if (type(data.confirmedName) ~= "string" or data.confirmedName ~= recipient.name) then return nil, "error:recipientChanged" end

    return recipient
end

-- What the page shows before the player confirms
---@param plyId integer
---@param data table @ {by, value} or {payeeId}
---@return table result
Z.callback.register("zyke_laptop_bank:FindRecipient", function(plyId, data)
    local sender, err = GetSender(plyId)
    if (not sender) then return {ok = false, error = err} end
    if (IsOnCooldown(plyId, "lookup", Config.lookupCooldown)) then return {ok = false, error = "error:lookupCooldown"} end

    local recipient, lookupErr = ResolveRecipient(sender, data)
    if (not recipient) then return {ok = false, error = lookupErr} end

    return {ok = true, name = recipient.name, online = recipient.online, saved = PayeeDb.isSaved(sender.identifier, recipient.identifier)}
end)