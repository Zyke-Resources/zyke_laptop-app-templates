-- Registers Notes, which owns the .note file type: Files shows .note files with its emblem and opens them in the
-- app. The laptop drops every registration when it restarts and fires the server event zyke_laptop:Ready once it is back
local function registerApp()
    exports.zyke_laptop:RegisterApp({
        id = "example_notes",
        label = T("app:name"),
        icon = "notebook-pen",
        category = "office",
        description = T("app:description"),
        ui = "web/index.html",
        window = {width = 620, height = 480, minWidth = 380, minHeight = 300, resizable = true},
        preinstalled = true,
        documents = {
            {extension = "note", label = T("file:type"), icon = "notebook-pen", color = "#c9a227"},
        },
    })
end

AddEventHandler("zyke_laptop:Ready", registerApp)

-- This resource started after the laptop, so Ready has already fired
if (GetResourceState("zyke_laptop") == "started") then registerApp() end