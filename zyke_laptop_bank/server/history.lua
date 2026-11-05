-- The history page: one page of transactions at a time, filtered by direction, kind and a search in the note and the
-- other side's name

-- Characters of a search
local maxSearchLength = 40

---@param data any
---@return BankHistoryFilter filter
local function readFilter(data)
    if (type(data) ~= "table") then data = {} end

    local search = type(data.search) == "string" and data.search:gsub("%c", " "):match("^%s*(.-)%s*$") or ""
    if ((utf8.len(search) or maxSearchLength + 1) > maxSearchLength) then search = "" end

    local offset = math.tointeger(tonumber(data.offset)) or 0

    return {
        direction = (data.direction == "in" or data.direction == "out") and data.direction or "all",
        kind = TransactionKinds[data.kind] and data.kind or nil,
        search = search,
        offset = math.max(0, offset),
    }
end

---@param plyId integer
---@param data table @ {direction?, kind?, search?, offset?}
---@return table result
Z.callback.register("zyke_laptop_bank:GetHistory", function(plyId, data)
    local sender, err = GetSender(plyId)
    if (not sender) then return {ok = false, error = err} end

    local filter = readFilter(data)

    -- One row more than a page says whether another page follows
    local rows = TransactionDb.listFor(sender.identifier, filter, Config.historyPageSize + 1)
    local transactions = {}

    for i = 1, math.min(#rows, Config.historyPageSize) do
        transactions[i] = FormatTransaction(rows[i], sender.identifier)
    end

    return {ok = true, transactions = transactions, more = #rows > Config.historyPageSize}
end)