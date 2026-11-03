-- The page can send anything, so every callback checks that the player stands at a laptop and only ever reads the
-- calling character's own vehicles

---@class GarageVehicle
---@field plate string
---@field model? string @ Model hash or spawn name
---@field state "stored" | "out" | "impounded"
---@field label? string @ The vehicle's name, added by the client

---@param plyId integer
---@return string? identifier
---@return string? err @ Locale key
local function getOwner(plyId)
    -- An app window only runs while its player is at a laptop, a request from anywhere else did not come from the page
    if (GetResourceState("zyke_laptop") ~= "started" or not exports.zyke_laptop:IsAtLaptop(plyId)) then return nil, "error:notAtLaptop" end

    local identifier = Z.getIdentifier(plyId)
    if (not identifier) then return nil, "error:noCharacter" end

    return identifier
end

---@param plyId integer
---@return {ok: boolean, error?: string, vehicles?: GarageVehicle[]} result
Z.callback.register("zyke_laptop_garage:GetVehicles", function(plyId)
    local identifier, err = getOwner(plyId)
    if (not identifier) then return {ok = false, error = err} end

    local rows = Z.getOwnedVehicles(identifier, Config.listLimit)
    local vehicles = {}

    for i = 1, #rows do
        local row = rows[i]

        vehicles[i] = {
            plate = row.plate,
            model = row.model and tostring(row.model),
            state = row.state,
        }
    end

    return {ok = true, vehicles = vehicles}
end)

---@param plyId integer
---@param plate any
---@return {ok: boolean, error?: string, plate?: string, coords?: {x: number, y: number}} result
Z.callback.register("zyke_laptop_garage:Locate", function(plyId, plate)
    local identifier, err = getOwner(plyId)
    if (not identifier) then return {ok = false, error = err} end
    if (type(plate) ~= "string" or #plate == 0 or #plate > 16) then return {ok = false, error = "error:notFound"} end

    -- Any plate could be posted, so the list's ownership check runs again
    local owned = Z.getOwnedVehicle(plate)
    if (not owned or owned.identifier ~= identifier) then return {ok = false, error = "error:notOwned"} end

    local vehicle = Z.getVehicleByPlate(plate)
    if (not vehicle) then return {ok = false, error = "error:notFound"} end

    local coords = GetEntityCoords(vehicle)

    return {ok = true, plate = plate, coords = {x = coords.x, y = coords.y}}
end)