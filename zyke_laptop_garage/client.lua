-- Passes the My Vehicles page's posts on to the server, which checks each of them. The client only adds what needs the
-- game: the vehicles' names and the GPS waypoint. server/register.lua registers the app

-- GTA's own name for the model in the game's language, such as "Sultan RS"
---@param model? string @ Model hash or spawn name
---@return string label
local function getVehicleLabel(model)
    if (not model) then return T("vehicle:unknown") end

    local hash = tonumber(model) or joaat(model)
    local label = GetLabelText(GetDisplayNameFromVehicleModel(hash))
    if (label ~= "NULL") then return label end

    -- Add-on vehicles often have no text entry, their spawn name is the next best thing
    local spawnName = Z.translateVehicleModelHash(hash) or (not tonumber(model) and model)

    return spawnName or T("vehicle:unknown")
end

-- Every locale string goes to the page, which picks the keys it shows
---@param _ table
---@param cb fun(setup: {strings: table<string, string>})
RegisterNUICallback("Setup", function(_, cb)
    cb({strings = Translations})
end)

---@param _ table
---@param cb fun(result: table)
RegisterNUICallback("GetVehicles", function(_, cb)
    local result = Z.callback.request("zyke_laptop_garage:GetVehicles", nil) or {ok = false, error = "error:unavailable"}

    if (result.ok) then
        for i = 1, #result.vehicles do
            result.vehicles[i].label = getVehicleLabel(result.vehicles[i].model)
        end
    end

    cb(result)
end)

-- The OS notification is the only feedback, so the page shows nothing of its own for a Locate
---@param data {plate?: string}
---@param cb fun(result: {ok: boolean})
RegisterNUICallback("Locate", function(data, cb)
    local plate = type(data) == "table" and type(data.plate) == "string" and data.plate or ""
    local result = Z.callback.request("zyke_laptop_garage:Locate", nil, plate) or {ok = false, error = "error:unavailable"}

    if (not result.ok) then
        exports.zyke_laptop:Notify({title = T("locate:failed"), text = T(result.error, plate), icon = Config.app.icon, appId = Config.app.id})

        return cb({ok = false})
    end

    SetNewWaypoint(result.coords.x, result.coords.y)

    exports.zyke_laptop:Notify({title = T("locate:title"), text = T("locate:set", result.plate), icon = Config.app.icon, appId = Config.app.id})

    cb({ok = true})
end)