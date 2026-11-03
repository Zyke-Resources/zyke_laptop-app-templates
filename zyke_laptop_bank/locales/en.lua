return {
    -- App
    ["app:name"] = "Fleeca Banking",
    ["app:description"] = "Check your balance and send money to other people.",

    -- Page
    ["web:dateLocale"] = "en-US",
    ["web:currency"] = "USD",
    ["page:balance"] = "Available balance",
    ["page:accountHolder"] = "Account holder",
    ["page:transfer"] = "Send money",
    ["page:recipient"] = "Recipient's ID",
    ["page:recipientPlaceholder"] = "Server ID, for example 12",
    ["page:amount"] = "Amount",
    ["page:note"] = "Note",
    ["page:notePlaceholder"] = "Optional, for example Rent",
    ["page:send"] = "Send",
    ["page:sending"] = "Sending...",
    ["page:history"] = "Recent transactions",
    ["page:noHistory"] = "No transactions yet.",
    ["page:to"] = "To %s",
    ["page:from"] = "From %s",
    ["page:retry"] = "Try again",
    ["page:bills"] = "Bills",
    ["page:pay"] = "Pay",
    ["page:paid"] = "Paid",
    ["page:paying"] = "Paying...",

    -- Bills, see Config.bills
    ["bill:utilities"] = "Water and power",
    ["bill:phone"] = "Phone plan",

    -- Notifications
    ["notify:title"] = "Fleeca Banking",
    ["notify:sent"] = "You sent %s to %s.",
    ["notify:received"] = "%s sent you %s.",
    ["notify:receivedNote"] = "%s sent you %s: \"%s\"",

    -- Errors, shown under the form or over the page
    ["error:notAtLaptop"] = "You need to be at a laptop.",
    ["error:noCharacter"] = "Your character could not be found.",
    ["error:invalidTarget"] = "Enter the recipient's server ID.",
    ["error:self"] = "You can't send money to yourself.",
    ["error:targetOffline"] = "Nobody with that ID is in the city.",
    ["error:amount"] = "Enter a whole amount from %s to %s.",
    ["error:noteLength"] = "The note can be %s characters at most.",
    ["error:funds"] = "Your balance is too low.",
    ["error:cooldown"] = "Wait a moment before sending again.",
    ["error:failed"] = "The transfer did not go through. No money was moved.",
    ["error:unavailable"] = "The bank can't be reached right now.",
    ["error:unknownBill"] = "That bill doesn't exist.",
    ["error:billPaid"] = "That bill is already paid.",
    ["error:payFailed"] = "The payment did not go through.",
}