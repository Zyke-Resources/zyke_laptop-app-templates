-- Registers Corner Supply. Sites are registered on the server, which sends them to every client. The laptop drops every
-- registration when it restarts and fires the server event zyke_laptop:Ready once it is back
local function registerSite()
    exports.zyke_laptop:RegisterSite({
        id = Config.site.id,
        url = Config.site.url,
        title = T("site:title"),
        description = T("site:description"),
        icon = Config.site.icon,
        ui = "web/index.html",
        listed = true,
        category = "shopping",
        network = "clearnet",
        -- The payees server/orders.lua may make payments to, see Config.payee
        payments = {payees = {"server", "society"}},
    })
end

AddEventHandler("zyke_laptop:Ready", registerSite)

-- This resource started after the laptop, so Ready has already fired
if (GetResourceState("zyke_laptop") == "started") then registerSite() end