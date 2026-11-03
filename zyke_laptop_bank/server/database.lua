-- Every transfer is one row, read back from both sides: the sender sees it as money out, the receiver as money in

---@class BankTransactionRow
---@field id integer
---@field sender_identifier string
---@field sender_name string
---@field receiver_identifier string
---@field receiver_name string
---@field amount integer
---@field note string
---@field createdAt integer

---@class BankParty
---@field identifier string
---@field name string

TransactionDb = {}

local ready = promise.new()

MySQL.ready(function()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `zyke_laptop_bank_transactions` (
            `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
            `sender_identifier` VARCHAR(64) NOT NULL,
            `sender_name` VARCHAR(128) NOT NULL,
            `receiver_identifier` VARCHAR(64) NOT NULL,
            `receiver_name` VARCHAR(128) NOT NULL,
            `amount` INT UNSIGNED NOT NULL,
            `note` VARCHAR(255) NOT NULL DEFAULT '',
            -- Only for a paid bill: one row per payment, however often its delivery runs
            `payment_id` VARCHAR(64) NULL DEFAULT NULL,
            `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            KEY `sender_identifier` (`sender_identifier`),
            KEY `receiver_identifier` (`receiver_identifier`),
            UNIQUE KEY `payment_id` (`payment_id`)
        )
    ]])

    ready:resolve(true)
end)

-- Waits for the table, a paid bill can arrive before MySQL is ready
function TransactionDb.await()
    Citizen.Await(ready)
end

---@param sender BankParty
---@param receiver BankParty
---@param amount integer
---@param note string
---@return integer id
function TransactionDb.insert(sender, receiver, amount, note)
    return MySQL.insert.await("INSERT INTO `zyke_laptop_bank_transactions` (sender_identifier, sender_name, receiver_identifier, receiver_name, amount, note) VALUES (?, ?, ?, ?, ?, ?)", {
        sender.identifier, sender.name, receiver.identifier, receiver.name, amount, note,
    })
end

-- A paid bill. A second call for the same payment adds nothing, so a bill delivered twice is still one row
---@param payer BankParty
---@param payee BankParty
---@param amount integer
---@param paymentId string
function TransactionDb.insertBill(payer, payee, amount, paymentId)
    MySQL.insert.await("INSERT IGNORE INTO `zyke_laptop_bank_transactions` (sender_identifier, sender_name, receiver_identifier, receiver_name, amount, note, payment_id) VALUES (?, ?, ?, ?, ?, '', ?)", {
        payer.identifier, payer.name, payee.identifier, payee.name, amount, paymentId,
    })
end

---@param identifier string
---@param limit integer
---@return BankTransactionRow[] rows @ Newest first
function TransactionDb.listFor(identifier, limit)
    -- Times go to the page as seconds since the epoch
    return MySQL.query.await("SELECT id, sender_identifier, sender_name, receiver_identifier, receiver_name, amount, note, UNIX_TIMESTAMP(created_at) AS createdAt FROM `zyke_laptop_bank_transactions` WHERE sender_identifier = ? OR receiver_identifier = ? ORDER BY id DESC LIMIT ?", {
        identifier, identifier, limit,
    })
end