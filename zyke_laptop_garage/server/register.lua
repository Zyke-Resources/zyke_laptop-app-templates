-- Registers the My Vehicles app. Apps are registered on the server, which sends them to every client. The laptop
-- drops every registration when it restarts and fires the server event zyke_laptop:Ready once it is back
local function registerApp()
    exports.zyke_laptop:RegisterApp({
        id = Config.app.id,
        label = T("app:name"),
        icon = Config.app.icon,
        category = "utilities",
        description = T("app:description"),
        ui = "web/index.html",
        window = Config.app.window,
        -- Installed for every account right away instead of waiting in the app store
        preinstalled = true,
    })
end

AddEventHandler("zyke_laptop:Ready", registerApp)

-- This resource started after the laptop, so Ready has already fired
if (GetResourceState("zyke_laptop") == "started") then registerApp() end