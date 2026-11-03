-- Registers the app. Apps are registered on the server, which sends them to every client. The laptop drops every
-- registration when it restarts and fires the server event zyke_laptop:Ready once it is back
local function registerApp()
    exports.zyke_laptop:RegisterApp({
        id = Config.app.id,
        label = T("app:name"),
        icon = Config.app.icon,
        category = "accessories",
        description = T("app:description"),
        ui = "web/dist/index.html",
        window = {width = 640, height = 480, minWidth = 420, minHeight = 360, resizable = true},
        -- Installed for every account straight away; leave it out to offer the app in the store instead
        preinstalled = true,
    })
end

AddEventHandler("zyke_laptop:Ready", registerApp)

-- This resource started after the laptop, so Ready has already fired
if (GetResourceState("zyke_laptop") == "started") then registerApp() end