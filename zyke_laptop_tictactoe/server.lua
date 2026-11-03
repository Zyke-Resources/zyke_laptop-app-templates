-- Registers the game with a room per table and a cast scoreboard. The server only relays the moves between the two
-- laptops, so the game is decided by the players' pages: fine for a game, never for anything that pays out
local boardPattern = "^[XO%.]+$"
local maxNameLength = 24
local maxCount = 999

-- What the other player sees of someone who joins a table: the character's first name
---@param plyId integer
---@return boolean allowed
---@return {name: string} member
local function allowJoin(plyId)
    local identifier = Z.getIdentifier(plyId)
    local character = identifier and Z.getCharacter(identifier)

    return true, {name = character and character.firstname or GetPlayerName(plyId)}
end

---@param value any
---@return string name
local function toName(value)
    return exports.zyke_laptop:ToCastText(value, maxNameLength) or "?"
end

---@param value any
---@return integer count
local function toCount(value)
    return math.max(0, math.min(math.tointeger(value) or 0, maxCount))
end

-- Every screen that shows the cast draws what this returns, so it keeps only known fields with checked values and adds
-- the text itself. nil drops the snapshot
---@param content any
---@return table? snapshot
local function checkSnapshot(content)
    if (type(content) ~= "table" or type(content.players) ~= "table" or type(content.wins) ~= "table") then return nil end

    local board = content.board
    if (type(board) ~= "string" or #board ~= 9 or not board:find(boardPattern)) then return nil end

    return {
        players = {toName(content.players[1]), toName(content.players[2])},
        wins = {toCount(content.wins[1]), toCount(content.wins[2])},
        draws = toCount(content.draws),
        board = board,
        turn = (content.turn == "X" or content.turn == "O") and content.turn or nil,
        labels = {title = T("app:name"), wins = T("cast:wins"), draws = T("cast:draws"), turn = T("cast:turn")},
    }
end

-- The laptop drops every registration when it restarts and fires the server event zyke_laptop:Ready once it is back
local function registerApp()
    exports.zyke_laptop:RegisterApp({
        id = "example_tictactoe",
        label = T("app:name"),
        icon = "grid-3x3",
        category = "accessories",
        description = T("app:description"),
        ui = "web/index.html",
        window = {width = 520, height = 600, minWidth = 380, minHeight = 480, resizable = true},
        preinstalled = true,
        -- Laptop.rooms: two players a table, join gives each one a name the other sees
        rooms = {maxMembers = 2, messageBytes = 256, join = allowJoin},
        -- Laptop.cast: the viewer page screens show, and the check of every snapshot the window sends
        cast = {ui = "web/cast.html", snapshot = checkSnapshot},
    })
end

AddEventHandler("zyke_laptop:Ready", registerApp)

-- This resource started after the laptop, so Ready has already fired
if (GetResourceState("zyke_laptop") == "started") then registerApp() end