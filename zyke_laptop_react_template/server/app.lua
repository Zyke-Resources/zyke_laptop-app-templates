-- The page can post anything to the client, so every callback checks again here and works out its answer itself

-- Milliseconds before the server pings back
local pongDelay = 2000

-- Pongs per player, and the players with one on its way
---@type table<integer, integer>
local pongCounts = {}
---@type table<integer, true>
local pinging = {}

-- A player can only use the app while their laptop is open, so a call from anywhere else did not come from the page
---@param plyId integer
---@return boolean atLaptop
local function isAtLaptop(plyId)
    return GetResourceState("zyke_laptop") == "started" and exports.zyke_laptop:IsAtLaptop(plyId)
end

---@param plyId integer
---@return table result
Z.callback.register(ResName .. ":GetServerInfo", function(plyId)
    if (not isAtLaptop(plyId)) then return {ok = false, error = "error:notAtLaptop"} end

    return {ok = true, players = #GetPlayers(), time = os.date("%H:%M:%S")}
end)

---@param plyId integer
---@return table result
Z.callback.register(ResName .. ":Ping", function(plyId)
    if (not isAtLaptop(plyId)) then return {ok = false, error = "error:notAtLaptop"} end
    if (pinging[plyId]) then return {ok = false, error = "error:busy"} end

    pinging[plyId] = true

    SetTimeout(pongDelay, function()
        if (not pinging[plyId]) then return end

        pinging[plyId] = nil
        pongCounts[plyId] = (pongCounts[plyId] or 0) + 1

        TriggerClientEvent(ResName .. ":Pong", plyId, {count = pongCounts[plyId], time = os.date("%H:%M:%S")})
    end)

    return {ok = true}
end)

AddEventHandler("playerDropped", function()
    pinging[source] = nil
    pongCounts[source] = nil
end)