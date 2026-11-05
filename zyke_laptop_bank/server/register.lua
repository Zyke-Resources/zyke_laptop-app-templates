-- Registers Fleeca Banking. Apps are registered on the server, which sends them to every client. The laptop drops
-- every registration when it restarts and fires the server event zyke_laptop:Ready once it is back
local function registerApp()
    exports.zyke_laptop:RegisterApp({
        id = Config.appId,
        label = T("app:name"),
        icon = "landmark",
        category = "office",
        description = T("app:description"),
        ui = "web/index.html",
        preinstalled = true,
        window = {width = 860, height = 600, minWidth = 560, minHeight = 460, resizable = true},
        -- The payees server/bills.lua may make payments to, see Config.bills
        payments = {payees = {"server", "society"}},
    })
end

AddEventHandler("zyke_laptop:Ready", registerApp)

-- This resource started after the laptop, so Ready has already fired
if (GetResourceState("zyke_laptop") == "started") then registerApp() end