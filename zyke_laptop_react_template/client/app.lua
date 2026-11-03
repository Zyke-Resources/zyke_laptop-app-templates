-- Passes the app's page's posts on to the server and its pongs back to the page. The page is the React build in
-- web/dist, server/register.lua registers the app

-- The page asks for its text once, every key of the active locale file
---@param _ table
---@param cb fun(setup: {strings: table<string, string>})
RegisterNUICallback("Setup", function(_, cb)
    cb({strings = Translations})
end)

-- Server callbacks the page reaches through a NUI callback of the same name
local serverEndpoints = {"GetServerInfo", "Ping"}

for i = 1, #serverEndpoints do
    local endpoint = serverEndpoints[i]

    ---@param data table
    ---@param cb fun(result: table)
    RegisterNUICallback(endpoint, function(data, cb)
        cb(Z.callback.request(ResName .. ":" .. endpoint, nil, data) or {ok = false, error = "error:unavailable"})
    end)
end

-- The OS notification tells the player, and the message reaches the page if the app is open
---@param pong {count: integer, time: string}
RegisterNetEvent(ResName .. ":Pong", function(pong)
    if (GetResourceState("zyke_laptop") ~= "started") then return end

    exports.zyke_laptop:Notify({title = T("notify:pongTitle"), text = T("notify:pong"), icon = Config.app.icon, appId = Config.app.id})
    exports.zyke_laptop:SendAppMessage(Config.app.id, pong)
end)