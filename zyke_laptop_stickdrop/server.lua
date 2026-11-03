-- Hands out a data stick with a task on it and checks the answer a player writes back. The code is worked out from the
-- stick's serial and Config.secret, so nothing has to be stored and sticks given before a restart still work
local answerPath = "answer.txt"

-- A four digit code that belongs to one stick
---@param serial string
---@return string code
local function getCode(serial)
    return tostring(GetHashKey(serial .. Config.secret) % 9000 + 1000)
end

-- Gives the player a stick with the task and the code on it: stickdrop_give <playerId>
---@param source integer
---@param args string[]
RegisterCommand("stickdrop_give", function(source, args)
    if (source ~= 0) then return end
    if (GetResourceState("zyke_laptop") ~= "started") then return print("zyke_laptop is not started") end

    local plyId = tonumber(args[1])
    if (not plyId or not GetPlayerName(plyId)) then return print("Usage: stickdrop_give <playerId>") end

    -- The serial only exists once the stick does, so the code goes on in a second step
    local serial, err = exports.zyke_laptop:GiveDataStick(plyId, {
        label = Config.label,
        files = {{path = "orders.txt", content = T("stick:orders", answerPath)}},
    })
    if (not serial) then return print(("No stick for %s: %s"):format(plyId, err)) end

    exports.zyke_laptop:WriteDataStickFile(serial, "vault/code.txt", getCode(serial))

    print(("Gave stick %s to %s, its code is %s"):format(serial, plyId, getCode(serial)))
end, true)

-- Fires when a player saved files on any stick, and when a resource wrote one. by is "player" or the resource
---@param serial string
---@param by string
AddEventHandler("zyke_laptop:DataStickChanged", function(serial, by)
    if (by ~= "player") then return end

    local files, label = exports.zyke_laptop:GetDataStickFiles(serial)
    if (not files or label ~= Config.label) then return end

    local answer = exports.zyke_laptop:ReadDataStickFile(serial, answerPath)
    if (not answer) then return end

    -- What players type is untrusted, compare only the digits
    if (answer:gsub("%D", "") ~= getCode(serial)) then return exports.zyke_laptop:WriteDataStickFile(serial, "reply.txt", T("stick:wrong"), {overwrite = true}) end

    -- Open laptops with the stick plugged in reload it, so the player sees the reply and the new label at once
    exports.zyke_laptop:WriteDataStickFile(serial, "reply.txt", T("stick:right"), {overwrite = true})
    exports.zyke_laptop:SetDataStickLabel(serial, Config.doneLabel)

    print(("Stick %s came back with the right code"):format(serial))
end)