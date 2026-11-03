-- Answers the website's page in web/, which asks for its text and content through Setup. A site with server data
-- passes requests on with Z.callback, as zyke_laptop_app_template does. server.lua registers the site

-- Every string of the locale file, the page picks the keys it shows
---@return table<string, string> strings
local function getStrings()
    local strings = {}

    for key, value in pairs(Translations) do
        if (type(value) == "string") then strings[key] = value end
    end

    return strings
end

---@param _ table
---@param cb fun(setup: {url: string, strings: table<string, string>, contact: {phone: string, address: string}})
RegisterNUICallback("Setup", function(_, cb)
    cb({url = Config.site.url, strings = getStrings(), contact = Config.contact})
end)