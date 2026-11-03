-- The page plays through Laptop.rooms and casts through Laptop.cast, so the only thing Lua gives it is its text

---@param _ table
---@param cb fun(setup: {strings: table<string, string>})
RegisterNUICallback("Setup", function(_, cb)
    cb({strings = Translations})
end)