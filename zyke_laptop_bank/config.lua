Config = {
    -- Must be unique across every app on the laptop: letters, digits, _ and -
    appId = "bank",

    -- Framework account the app shows and transfers from, "bank" on ESX and QBCore
    account = "bank",

    -- Limits of one transfer, request or standing payment, in whole dollars
    minAmount = 1,
    maxAmount = 1000000,
    -- Characters
    maxNoteLength = 60,

    -- Seconds a player waits between two transfers, requests or new standing payments, so a double click can't send twice
    cooldown = 3,
    -- Seconds between two recipient lookups, so phone numbers and names can't be guessed in bulk
    lookupCooldown = 1,

    -- Money sent to someone who is not in the city waits in the bank and reaches them when they are next in.
    -- false refuses transfers, requests and standing payments whose recipient is offline
    offlineRecipients = true,
    -- Finding a recipient by full name searches every character, false only the players in the city
    nameLookupOffline = true,

    -- Transactions per page of the history
    historyPageSize = 25,
    -- Months the in and out summary covers, this month included
    summaryMonths = 6,

    -- Saved payees per character
    maxPayees = 25,

    requests = {
        -- Open requests one character may have waiting at once
        maxOpen = 10,
        -- Days before an unanswered request expires
        expiryDays = 7,
        -- Answered and expired requests the page lists
        historyLength = 20,
    },

    standing = {
        -- Active standing payments per character
        maxActive = 10,
        -- Days between two payments
        minIntervalDays = 1,
        maxIntervalDays = 30,
    },

    -- Minutes between two runs of the standing payment, request expiry and held money checks. They also run on start
    -- and when a character is selected
    processMinutes = 5,

    -- Bills paid through the laptop's pay sheet, from the bank or in crypto. label is a locale key, amount whole dollars.
    -- The money goes to "server", it leaves the economy; a business would use "society:<job>"
    bills = {
        {id = "utilities", label = "bill:utilities", amount = 180, payee = "server"},
        {id = "phone", label = "bill:phone", amount = 60, payee = "server"},
    },
    -- Days a paid bill stays paid
    billPeriodDays = 7,
}