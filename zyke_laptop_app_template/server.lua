-- Registers the app. Apps are registered on the server, which sends them to every client. The laptop drops every
-- registration when it restarts and fires the server event zyke_laptop:Ready once it is back
local function registerApp()
    exports.zyke_laptop:RegisterApp({
        id = Config.app.id,
        label = T("app:name"),
        icon = Config.app.icon,
        category = "utilities",
        description = T("app:description"),
        ui = "web/index.html",
        window = {width = 560, height = 520, minWidth = 420, minHeight = 400, resizable = true},
        -- Installed for every account straight away; leave it out to offer the app in the store instead
        preinstalled = true,

        -- Optional fields, see docs/lua-api.md. Uncomment what your app needs

        -- Who sees the app at all. The laptop checks it on every SDK call; canUseApp below checks it for your own callbacks
        -- access = {jobs = {police = 0, sheriff = 2}, onDuty = true},

        -- Sells the app in the store; remove preinstalled so players get it there
        -- price = {amount = 500, currency = "either", payee = "server"},

        -- What the page may ask the player for: Laptop.account() and Laptop.clipboard.readText()
        -- permissions = {"account", "clipboard"},

        -- Turns on Laptop.storage, data kept per account on the server: true for the default 32 KiB, or a size of your own
        -- storage = {maxBytes = 65536},
    })
end

AddEventHandler("zyke_laptop:Ready", registerApp)

-- This resource started after the laptop, so Ready has already fired
if (GetResourceState("zyke_laptop") == "started") then registerApp() end

-- Any client can trigger a server callback, with or without the app open. So each one checks that the player is at a
-- laptop and may use the app (its access rule, and a licence for a paid app), and reads what it needs on the server
---@param plyId integer
---@return boolean allowed
---@return string? err @ Locale key
local function canUseApp(plyId)
    if (GetResourceState("zyke_laptop") ~= "started" or not exports.zyke_laptop:IsAtLaptop(plyId)) then return false, "error:notAtLaptop" end
    if (not exports.zyke_laptop:CanUseApp(plyId, Config.app.id)) then return false, "error:noAccess" end

    return true
end

---@param plyId integer
---@return {ok: boolean, name?: string, error?: string} result @ error is a locale key
Z.callback.register("zyke_laptop_app_template:GetGreeting", function(plyId)
    local allowed, err = canUseApp(plyId)
    if (not allowed) then return {ok = false, error = err} end

    local identifier = Z.getIdentifier(plyId)
    local character = identifier and Z.getCharacter(identifier)
    if (not character) then return {ok = false, error = "error:noCharacter"} end

    return {ok = true, name = ("%s %s"):format(character.firstname, character.lastname)}
end)

-- Pushes a line to the player's open app window from the server console: template_app_message <playerId> <text>
---@param source integer
---@param args string[]
RegisterCommand("template_app_message", function(source, args)
    if (source ~= 0) then return end

    local plyId = tonumber(args[1])
    local text = table.concat(args, " ", 2)
    if (not plyId or not GetPlayerName(plyId) or text == "") then return print("Usage: template_app_message <playerId> <text>") end

    TriggerClientEvent("zyke_laptop_app_template:Message", plyId, text)
end, true)