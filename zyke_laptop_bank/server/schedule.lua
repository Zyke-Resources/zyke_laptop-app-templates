-- The work no player asks for: due standing payments, expired requests and held money, on start, every
-- Config.processMinutes and for a character as it is selected

local function processAll()
    TransactionDb.await()

    ExpireRequests()
    Ledger.payAllHeld()
    ProcessStandingPayments()
end

CreateThread(function()
    while (true) do
        processAll()

        Wait(Config.processMinutes * 60000)
    end
end)

---@param plyId integer
AddEventHandler("zyke_lib:OnCharacterSelect", function(plyId)
    TransactionDb.await()

    local identifier = Z.getIdentifier(plyId)
    if (not identifier) then return end

    Ledger.payHeld(plyId, identifier)
    ProcessStandingPayments(identifier)
end)