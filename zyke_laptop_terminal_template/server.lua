-- Registers "My Tools", an app with no window that adds two commands to the Terminal: greet runs here on the server
-- and talks to the player through the session it gets, stopwatch is web/stopwatch.html, which the Terminal runs
local maxName = 24
local countdown = 3

-- Trimmed and cut to maxName characters, nil when the question was cancelled
---@param value? string
---@return string? name
local function cleanName(value)
    if (value == nil) then return nil end

    value = value:gsub("%c", ""):gsub("^%s+", ""):gsub("%s+$", "")
    if (not utf8.len(value)) then return "" end

    local cut = utf8.offset(value, maxName + 1)

    return cut and value:sub(1, cut - 1) or value
end

-- greet [name]: asks for what the arguments leave out. What the player types is client input, check it like any other
---@param term SdkTerminalSession
---@param args string[]
local function greet(term, args)
    local name = cleanName(args[1] or term.ask(T("greet:askName"), {initial = term.account.name}))
    if (not name) then return end
    if (name == "") then return term.print(T("greet:noName"), "error") end

    -- 1-based, nil for Escape or Ctrl+C. A disabled option is shown but can't be picked
    local styles = {"friendly", "formal"}
    local style = term.choose(T("greet:askStyle"), {
        {label = T("greet:style:friendly")},
        {label = T("greet:style:formal"), hint = T("greet:style:formalHint")},
        {label = T("greet:style:secret"), hint = T("greet:style:secretHint"), disabled = true},
    })
    if (not style) then return end

    for left = countdown, 1, -1 do
        term.status({{text = T("greet:preparing") .. " ", tone = "dim"}, {text = tostring(left), tone = "accent"}})

        -- False when the player pressed Ctrl+C or the window closed
        if (not term.sleep(1000)) then return end
    end

    term.status(nil)

    local greeting = T("greet:" .. styles[style], name)

    term.print(greeting, "bold")
    term.print(T("greet:people", #GetPlayers()), "dim")

    -- true, false, or nil when cancelled
    if (term.confirm(T("greet:shout"), false)) then term.print(greeting:upper(), "accent") end
end

-- The laptop drops every registration when it restarts and fires the server event zyke_laptop:Ready once it is back
local function registerApp()
    exports.zyke_laptop:RegisterApp({
        id = "template_terminal",
        label = T("app:name"),
        icon = "square-terminal",
        category = "utilities",
        description = T("app:description"),
        preinstalled = true,
        -- No ui: the app is a terminal app, and opening it runs launch in the Terminal
        terminal = {
            launch = "stopwatch",
            commands = {
                {name = "greet", usage = T("greet:usage"), description = T("greet:description"), run = greet},
                {name = "stopwatch", description = T("stopwatch:description"), program = "web/stopwatch.html"},
            },
        },
    })
end

AddEventHandler("zyke_laptop:Ready", registerApp)

-- This resource started after the laptop, so Ready has already fired
if (GetResourceState("zyke_laptop") == "started") then registerApp() end