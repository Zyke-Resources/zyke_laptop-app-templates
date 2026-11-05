-- The tables, made on start, and the transaction history. Every transaction is one row, read back from both sides: the
-- sender sees it as money out, the receiver as money in. The other tables keep their queries in their own files

---@class BankTransactionRow
---@field id integer
---@field sender_identifier string
---@field sender_name string
---@field receiver_identifier string
---@field receiver_name string
---@field amount integer
---@field note string
---@field kind BankTransactionKind
---@field createdAt integer

---@class BankParty
---@field identifier string
---@field name string

-- "standingFailed" is a standing payment that could not be paid and was stopped, no money moved
---@alias BankTransactionKind "transfer" | "bill" | "request" | "standing" | "standingFailed"

TransactionDb = {}

---@type table<string, true>
TransactionKinds = {transfer = true, bill = true, request = true, standing = true, standingFailed = true}

local ready = promise.new()

local tables = {
    [[
        CREATE TABLE IF NOT EXISTS `zyke_laptop_bank_transactions` (
            `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
            `sender_identifier` VARCHAR(64) NOT NULL,
            `sender_name` VARCHAR(128) NOT NULL,
            `receiver_identifier` VARCHAR(64) NOT NULL,
            `receiver_name` VARCHAR(128) NOT NULL,
            `amount` INT UNSIGNED NOT NULL,
            `note` VARCHAR(255) NOT NULL DEFAULT '',
            `kind` VARCHAR(16) NOT NULL DEFAULT 'transfer',
            -- Only for a paid bill: one row per payment, however often its delivery runs
            `payment_id` VARCHAR(64) NULL DEFAULT NULL,
            `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            KEY `sender_identifier` (`sender_identifier`),
            KEY `receiver_identifier` (`receiver_identifier`),
            UNIQUE KEY `payment_id` (`payment_id`)
        )
    ]],
    [[
        CREATE TABLE IF NOT EXISTS `zyke_laptop_bank_payees` (
            `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
            `owner_identifier` VARCHAR(64) NOT NULL,
            `payee_identifier` VARCHAR(64) NOT NULL,
            `name` VARCHAR(128) NOT NULL,
            `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            UNIQUE KEY `owner_payee` (`owner_identifier`, `payee_identifier`)
        )
    ]],
    [[
        CREATE TABLE IF NOT EXISTS `zyke_laptop_bank_requests` (
            `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
            `requester_identifier` VARCHAR(64) NOT NULL,
            `requester_name` VARCHAR(128) NOT NULL,
            `payer_identifier` VARCHAR(64) NOT NULL,
            `payer_name` VARCHAR(128) NOT NULL,
            `amount` INT UNSIGNED NOT NULL,
            `note` VARCHAR(255) NOT NULL DEFAULT '',
            -- open, paying, paid, declined, cancelled or expired
            `status` VARCHAR(16) NOT NULL DEFAULT 'open',
            `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            `answered_at` TIMESTAMP NULL DEFAULT NULL,
            PRIMARY KEY (`id`),
            KEY `requester` (`requester_identifier`, `status`),
            KEY `payer` (`payer_identifier`, `status`)
        )
    ]],
    [[
        CREATE TABLE IF NOT EXISTS `zyke_laptop_bank_standing` (
            `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
            `payer_identifier` VARCHAR(64) NOT NULL,
            `payer_name` VARCHAR(128) NOT NULL,
            `receiver_identifier` VARCHAR(64) NOT NULL,
            `receiver_name` VARCHAR(128) NOT NULL,
            `amount` INT UNSIGNED NOT NULL,
            `note` VARCHAR(255) NOT NULL DEFAULT '',
            `interval_days` SMALLINT UNSIGNED NOT NULL,
            -- Seconds since the epoch the next payment falls due
            `next_run_at` INT UNSIGNED NOT NULL,
            -- active, stopped (balance too low) or cancelled
            `status` VARCHAR(16) NOT NULL DEFAULT 'active',
            `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            KEY `due` (`status`, `next_run_at`),
            KEY `payer` (`payer_identifier`, `status`)
        )
    ]],
    -- Money sent to a character who was offline, paid out when they are next in
    [[
        CREATE TABLE IF NOT EXISTS `zyke_laptop_bank_held` (
            `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
            `identifier` VARCHAR(64) NOT NULL,
            `amount` INT UNSIGNED NOT NULL,
            `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            KEY `identifier` (`identifier`)
        )
    ]],
}

MySQL.ready(function()
    for i = 1, #tables do
        MySQL.query.await(tables[i])
    end

    -- CREATE TABLE IF NOT EXISTS leaves an existing table as it is, so columns added to the design are added here
    if (not Z.hasDatabaseColumn("zyke_laptop_bank_transactions", "kind")) then
        MySQL.query.await("ALTER TABLE `zyke_laptop_bank_transactions` ADD COLUMN `kind` VARCHAR(16) NOT NULL DEFAULT 'transfer' AFTER `note`")
    end

    ready:resolve(true)
end)

-- Waits for the tables, a paid bill or a selected character can arrive before MySQL is ready
function TransactionDb.await()
    Citizen.Await(ready)
end

---@param sender BankParty
---@param receiver BankParty
---@param amount integer
---@param note string
---@param kind BankTransactionKind
---@return integer id
function TransactionDb.insert(sender, receiver, amount, note, kind)
    return MySQL.insert.await("INSERT INTO `zyke_laptop_bank_transactions` (sender_identifier, sender_name, receiver_identifier, receiver_name, amount, note, kind) VALUES (?, ?, ?, ?, ?, ?, ?)", {
        sender.identifier, sender.name, receiver.identifier, receiver.name, amount, note, kind,
    })
end

-- A paid bill. A second call for the same payment adds nothing, so a bill delivered twice is still one row
---@param payer BankParty
---@param payee BankParty
---@param amount integer
---@param paymentId string
function TransactionDb.insertBill(payer, payee, amount, paymentId)
    MySQL.insert.await("INSERT IGNORE INTO `zyke_laptop_bank_transactions` (sender_identifier, sender_name, receiver_identifier, receiver_name, amount, note, kind, payment_id) VALUES (?, ?, ?, ?, ?, '', 'bill', ?)", {
        payer.identifier, payer.name, payee.identifier, payee.name, amount, paymentId,
    })
end

-- LIKE treats % and _ as wildcards, a search for "50%" means the text
---@param text string
---@return string pattern
local function likePattern(text)
    return "%" .. text:gsub("[\\%%_]", "\\%0") .. "%"
end

---@class BankHistoryFilter
---@field direction "all" | "in" | "out"
---@field kind? BankTransactionKind
---@field search string
---@field offset integer

---@param identifier string
---@param filter BankHistoryFilter
---@param limit integer
---@return BankTransactionRow[] rows @ Newest first
function TransactionDb.listFor(identifier, filter, limit)
    local where = {}
    local params = {}

    if (filter.direction == "in") then
        where[1] = "receiver_identifier = ?"
        params[1] = identifier
    elseif (filter.direction == "out") then
        where[1] = "sender_identifier = ?"
        params[1] = identifier
    else
        where[1] = "(sender_identifier = ? OR receiver_identifier = ?)"
        params[1], params[2] = identifier, identifier
    end

    if (filter.kind) then
        where[#where + 1] = "kind = ?"
        params[#params + 1] = filter.kind
    end

    if (filter.search ~= "") then
        local pattern = likePattern(filter.search)

        -- The other side's name: a search for a name finds both directions
        where[#where + 1] = "(note LIKE ? OR (sender_identifier = ? AND receiver_name LIKE ?) OR (receiver_identifier = ? AND sender_name LIKE ?))"
        params[#params + 1] = pattern
        params[#params + 1] = identifier
        params[#params + 1] = pattern
        params[#params + 1] = identifier
        params[#params + 1] = pattern
    end

    params[#params + 1] = limit
    params[#params + 1] = filter.offset

    -- Times go to the page as seconds since the epoch
    local query = ("SELECT id, sender_identifier, sender_name, receiver_identifier, receiver_name, amount, note, kind, UNIX_TIMESTAMP(created_at) AS createdAt FROM `zyke_laptop_bank_transactions` WHERE %s ORDER BY id DESC LIMIT ? OFFSET ?"):format(table.concat(where, " AND "))

    return MySQL.query.await(query, params)
end

-- Money in and out per calendar month, the oldest month first. A stopped standing payment moved nothing and is left out
---@param identifier string
---@param months integer @ This month included
---@return {month: string, moneyIn: integer, moneyOut: integer}[] summary
function TransactionDb.summary(identifier, months)
    local rows = MySQL.query.await([[
        SELECT DATE_FORMAT(created_at, '%Y-%m') AS month,
            CAST(SUM(IF(receiver_identifier = ?, amount, 0)) AS UNSIGNED) AS moneyIn,
            CAST(SUM(IF(sender_identifier = ?, amount, 0)) AS UNSIGNED) AS moneyOut
        FROM `zyke_laptop_bank_transactions`
        WHERE (sender_identifier = ? OR receiver_identifier = ?)
            AND kind <> 'standingFailed'
            AND created_at >= DATE_SUB(DATE_FORMAT(CURRENT_DATE, '%Y-%m-01'), INTERVAL ? MONTH)
        GROUP BY month
    ]], {identifier, identifier, identifier, identifier, months - 1})

    local byMonth = {}

    for i = 1, #rows do
        byMonth[rows[i].month] = rows[i]
    end

    -- Every month is listed, also one without transactions
    local now = os.date("*t")
    local summary = {}

    for i = months - 1, 0, -1 do
        local stamp = os.time({year = now.year, month = now.month - i, day = 1, hour = 12})
        local month = os.date("%Y-%m", stamp)
        local row = byMonth[month]

        summary[#summary + 1] = {month = month, moneyIn = row and row.moneyIn or 0, moneyOut = row and row.moneyOut or 0}
    end

    return summary
end