Config = {
    -- Must be unique across every app on the laptop: letters, digits, _ and -
    appId = "bank",

    -- Framework account the app shows and transfers from, "bank" on ESX and QBCore
    account = "bank",

    -- Limits of one transfer, in whole dollars
    minAmount = 1,
    maxAmount = 1000000,
    -- Characters
    maxNoteLength = 60,

    -- Seconds a player waits between two transfers, so a double click can't send twice
    cooldown = 3,

    -- Transactions the overview lists
    historyLength = 25,

    -- Bills paid through the laptop's pay sheet, from the bank or in crypto. label is a locale key, amount whole dollars.
    -- The money goes to "server", it leaves the economy; a business would use "society:<job>"
    bills = {
        {id = "utilities", label = "bill:utilities", amount = 180, payee = "server"},
        {id = "phone", label = "bill:phone", amount = 60, payee = "server"},
    },
    -- Days a paid bill stays paid
    billPeriodDays = 7,
}