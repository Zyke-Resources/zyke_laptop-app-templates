-- Answers the app's page in web/, which posts to the NUI callbacks below with Laptop.post. Callbacks that need the
-- server pass the request on to server.lua, which also registers the app

-- Every string of the locale file, the page picks the keys it shows
---@return table<string, string> strings
local function getStrings()
    local strings = {}

    for key, value in pairs(Translations) do
        if (type(value) == "string") then strings[key] = value end
    end

    return strings
end

---@param _ table
---@param cb fun(setup: {strings: table<string, string>})
RegisterNUICallback("Setup", function(_, cb)
    cb({strings = getStrings()})
end)

-- Passes the server's answer straight back to the page
---@param _ table
---@param cb fun(result: {ok: boolean, name?: string, error?: string})
RegisterNUICallback("GetGreeting", function(_, cb)
    cb(Z.callback.request("zyke_laptop_app_template:GetGreeting", nil) or {ok = false, error = "error:unavailable"})
end)

-- The OS notification is the only feedback, the page shows no toast of its own. appId opens the app when it is clicked
---@param _ table
---@param cb fun(result: {ok: boolean})
RegisterNUICallback("Notify", function(_, cb)
    local delivered = exports.zyke_laptop:Notify({title = T("notify:sentTitle"), text = T("notify:text"), icon = Config.app.icon, appId = Config.app.id})

    cb({ok = delivered})
end)

-- SendAppMessage only reaches a window that is open, the page gets it as a message event
---@param text string
RegisterNetEvent("zyke_laptop_app_template:Message", function(text)
    if (GetResourceState("zyke_laptop") ~= "started") then return end

    exports.zyke_laptop:SendAppMessage(Config.app.id, {text = text})
end)