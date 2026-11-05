-- Who is asking and who they mean. Every callback starts with GetSender, which checks that the player stands at a
-- laptop: a callback can be sent without ever opening the app

-- GetGameTimer of each player's last action, by action and server ID
---@type table<string, table<integer, integer>>
local lastActions = {}

-- The character's name as the bank writes it, also for an offline character
---@param character table?
---@return string? name
local function characterName(character)
    if (not character) then return nil end

    local name = ("%s %s"):format(character.firstname or "", character.lastname or ""):match("^%s*(.-)%s*$")

    return name ~= "" and name or T("page:accountHolder")
end

---@param identifier string
---@return BankParty? party
function GetPartyByIdentifier(identifier)
    local name = characterName(Z.getCharacter(identifier))
    if (not name) then return nil end

    return {identifier = identifier, name = name}
end

---@param plyId integer
---@return BankParty? party
function GetParty(plyId)
    local identifier = Z.getIdentifier(plyId)
    if (not identifier) then return nil end

    return GetPartyByIdentifier(identifier)
end

-- The character behind a request from the app, or the locale key of why there is none
---@param plyId integer
---@return BankParty? party
---@return string? err
function GetSender(plyId)
    -- IsAtLaptop is the laptop's own check that this player has a laptop out or stands at a placed one
    if (GetResourceState("zyke_laptop") ~= "started" or not exports.zyke_laptop:IsAtLaptop(plyId)) then return nil, "error:notAtLaptop" end

    local party = GetParty(plyId)
    if (not party) then return nil, "error:noCharacter" end

    return party
end

-- True while the player did the action less than `seconds` ago. Otherwise the action counts as done now
---@param plyId integer
---@param action string
---@param seconds number
---@return boolean waiting
function IsOnCooldown(plyId, action, seconds)
    local timers = lastActions[action]
    if (not timers) then
        timers = {}
        lastActions[action] = timers
    end

    local last = timers[plyId]
    if (last and GetGameTimer() - last < seconds * 1000) then return true end

    timers[plyId] = GetGameTimer()

    return false
end

-- Drops control characters and surrounding spaces, nil when the note is too long or not text
---@param value any
---@return string? note
function ReadNote(value)
    if (value == nil) then return "" end
    if (type(value) ~= "string") then return nil end

    local note = value:gsub("%c", " "):match("^%s*(.-)%s*$")
    local length = utf8.len(note)
    if (not length or length > Config.maxNoteLength) then return nil end

    return note
end

-- A whole amount within the limits. math.tointeger turns 250.0 into 250 and refuses 2.5
---@param value any
---@return integer? amount
---@return string? err
---@return any[]? args @ Values for the error's placeholders
function ReadAmount(value)
    local amount = math.tointeger(tonumber(value))
    if (not amount or amount < Config.minAmount or amount > Config.maxAmount) then return nil, "error:amount", {FormatMoney(Config.minAmount), FormatMoney(Config.maxAmount)} end

    return amount
end

-- Shows a bank notification to a player who is online, with the OS's notification while the laptop runs, and refreshes
-- their open app
---@param identifier string
---@param key string
---@param args any[]
---@param sound? "send" | "receive"
function NotifyCharacter(identifier, key, args, sound)
    local plyId = Z.getPlayerId(identifier)
    if (not plyId) then return end

    TriggerClientEvent("zyke_laptop_bank:Notify", plyId, key, args, sound)
end

AddEventHandler("playerDropped", function()
    for _, timers in pairs(lastActions) do
        timers[source] = nil
    end
end)

-- Loads the account again in the character's open app, when they are online
---@param identifier string
function RefreshCharacter(identifier)
    local plyId = Z.getPlayerId(identifier)
    if (not plyId) then return end

    TriggerClientEvent("zyke_laptop_bank:Refresh", plyId)
end