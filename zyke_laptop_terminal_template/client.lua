-- The stopwatch page asks for its text through the Setup callback, server.lua registers the app

---@param _ table
---@param cb fun(setup: {strings: table<string, string>})
RegisterNUICallback("Setup", function(_, cb)
    cb({strings = Translations})
end)