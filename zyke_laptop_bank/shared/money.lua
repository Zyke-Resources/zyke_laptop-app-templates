-- Whole dollars with thousands separators, such as $1,250
---@param amount integer
---@return string text
function FormatMoney(amount)
    local digits = tostring(math.abs(amount))
    local grouped = digits:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")

    return (amount < 0 and "-$" or "$") .. grouped
end