---@meta
-- Lua definitions of zyke_laptop's exports and the tables they take, for LuaLS. Add this file to your workspace's
-- library, such as "workspace.library": ["../[zyke]/zyke_laptop/extras/sdk/zyke_laptop.lua"] in .luarc.json, then
-- type the exports where you use them:
--
--     local laptop = exports.zyke_laptop --[[@as ZykeLaptopServerExports]]
--     local laptop = exports.zyke_laptop --[[@as ZykeLaptopClientExports]]
--
-- Kept in step with the code: laptop_sdk_check warns about an export that is missing here

-- Exports of zyke_laptop's client scripts
---@class ZykeLaptopClientExports
ZykeLaptopClientExports = {}

-- Opens the OS without a prop, for resources with their own computer or laptop in the world
---@return boolean opened
function ZykeLaptopClientExports:OpenScreen() end

-- The UI animates out on its own when the player closes it, this is for closing it from Lua
function ZykeLaptopClientExports:CloseScreen() end

---@return boolean open
function ZykeLaptopClientExports:IsScreenOpen() end

---@return boolean connected @ The OS is connected to the Onion network
function ZykeLaptopClientExports:IsConnected() end

---@return LaptopActivity? activity
function ZykeLaptopClientExports:GetActivity() end

function ZykeLaptopClientExports:TakeOut() end

function ZykeLaptopClientExports:PutAway() end

-- What is plugged into a laptop's ports, as every client in its routing bucket sees it
---@param ownerId integer
---@return table<string, {type: string, item: string}>? devices @ Nil when this client does not see that laptop
function ZykeLaptopClientExports:GetLaptopDevices(ownerId) end

-- Opens the port view of a placed laptop within reach, or of the player's own laptop in their hands with its screen
-- shut. The activity stays "holding" for the held one
---@param ownerId integer
function ZykeLaptopClientExports:OpenPorts(ownerId) end

function ZykeLaptopClientExports:ClosePorts() end

---@return boolean servicing
function ZykeLaptopClientExports:IsServicing() end

-- The ports every laptop has, in the port view's order
---@return LaptopPort[] ports
function ZykeLaptopClientExports:GetLaptopPorts() end

---@param appId string
---@param params? table @ Passed to the app's window
---@return boolean delivered
function ZykeLaptopClientExports:OpenApp(appId, params) end

---@param url string
---@return boolean delivered
function ZykeLaptopClientExports:OpenUrl(url) end

-- Clicks on one of its actions fire zyke_laptop:NotificationAction (resource, notificationId, actionId, data) in this
-- client, actionId is nil for a click on the notification itself. Its banner chimes, or plays notification.sound, with
-- the player's volume, UI-sounds switch and Do Not Disturb, and only while the laptop's screen is open: one that
-- arrives with the laptop closed shows silently in its list
---@param notification LaptopNotification
---@return boolean delivered
function ZykeLaptopClientExports:Notify(notification) end

-- Hands the player a bookmark, for example when a contact in the world gives them an address. It waits in the KVP
-- until a browser saved it, so one given while no OS runs reaches the next one that boots. The browser adds each id
-- once and saves that with the bookmark, so calling this again is harmless
---@param bookmark LaptopBookmark
---@return boolean kept @ Handed to the OS or kept for the next one, not whether the player had it already
function ZykeLaptopClientExports:AddBookmark(bookmark) end

-- Only a page open in the OS gets it, none is while no OS runs
---@param appId string
---@param data any @ Passed to the app's page as a message event
---@return boolean delivered
function ZykeLaptopClientExports:SendAppMessage(appId, data) end

---@param siteId string
---@param data any @ Passed to the site's page as a message event
---@return boolean delivered
function ZykeLaptopClientExports:SendSiteMessage(siteId, data) end

-- Only for an app the calling resource registered
---@param appId string
---@param count integer @ 0 hides it
---@return boolean set
function ZykeLaptopClientExports:SetAppBadge(appId, count) end

-- Opens Mail, writing to an address when one is given. Like OpenApp it needs an OS that runs, see exports.lua
---@param to? string
---@return boolean delivered
function ZykeLaptopClientExports:OpenMail(to) end

-- Opens Natter, on a chat when an id is given. Like OpenApp it needs an OS that runs, see exports.lua
---@param chatId? string
---@return boolean delivered
function ZykeLaptopClientExports:OpenMessenger(chatId) end

-- Posts a call on the dispatch board from this client, at the player unless coords names a place close to them
---@param data {title: string, description?: string, code?: string, priority?: integer, coords?: vector3 | {x: number, y: number, z?: number}, location?: string, departments?: string | string[], jobs?: string | string[], types?: string | string[], caller?: string}
function ZykeLaptopClientExports:SendMdtAlert(data) end

-- Exports of zyke_laptop's server scripts
---@class ZykeLaptopServerExports
ZykeLaptopServerExports = {}

---@param plyId integer
---@return boolean connected
function ZykeLaptopServerExports:IsConnected(plyId) end

---@param ownerId integer
---@return LaptopState?
function ZykeLaptopServerExports:GetLaptop(ownerId) end

-- The player's character put this laptop down. A held laptop is its holder's
---@param plyId integer
---@param ownerId integer
---@return boolean isOwner
function ZykeLaptopServerExports:IsLaptopOwner(plyId, ownerId) end

-- Sets or clears the finish of the laptop item in a player's inventory slot, for a resource that sells finishes. When
-- that laptop is out, held or put down, everyone who sees it gets the new colour at once
---@param plyId integer
---@param slot integer @ Inventory slot of the laptop item
---@param finishId? string @ Id from Config.Settings.finishes, nil for the stock finish
---@return boolean changed
---@return string? err @ "invalidFinish", "noLaptopItem" or "notSaved"
function ZykeLaptopServerExports:SetLaptopFinish(plyId, slot, finishId) end

-- Puts a skin on the laptop item in a player's inventory slot, for a shop or a business. The skin it had is gone, a
-- skin is bought again to go back on. When that laptop is out, everyone who sees it gets the new backplate at once
---@param plyId integer
---@param slot integer @ Inventory slot of the laptop item
---@param skinId? string @ Id listed under Config.Settings.skins, nil for the stock lid
---@return boolean changed
---@return string? err @ "invalidSkin", "noLaptopItem" or "notSaved"
function ZykeLaptopServerExports:SetLaptopSkin(plyId, slot, skinId) end

-- The player holds a laptop or stands at one put down, theirs or anyone's, for resources that only let players do
-- something from a laptop
---@param plyId integer
---@return boolean atLaptop
function ZykeLaptopServerExports:IsAtLaptop(plyId) end

-- Checked again when asked, the client only scans every few seconds: a player who left the hotspot's or router's
-- range falls back to the phone, and a phone that left the inventory or a Wi-Fi card that left the laptop takes it
-- offline
---@param plyId integer
---@return LaptopNetwork? network @ Nil when the player has no laptop on screen, or it is offline or limited
function ZykeLaptopServerExports:GetLaptopNetwork(plyId) end

-- The serial of the laptop the player's OS runs on right now, their own or another player's they use
---@param plyId integer
---@return string? serial @ Nil while their OS is off
function ZykeLaptopServerExports:GetLaptopSerial(plyId) end

-- The serial of the SSD in the laptop the player's OS runs on right now, the key of its drive
---@param plyId integer
---@return string? drive @ Nil while their OS is off or the laptop has no SSD
function ZykeLaptopServerExports:GetLaptopDriveSerial(plyId) end

-- The OS the player runs right now: "veil" from a USB stick, otherwise the one installed on the laptop
---@param plyId integer
---@return LaptopOsId? osId @ Nil while their OS is off or the drive has none
function ZykeLaptopServerExports:GetLaptopOs(plyId) end

-- What is plugged into a laptop's ports, as every client in its routing bucket sees it
---@param ownerId integer
---@return table<string, {type: string, item: string}>? devices @ Nil when this client does not see that laptop
function ZykeLaptopServerExports:GetLaptopDevices(ownerId) end

-- Plugs the item in the player's exact slot into a port. The item leaves the inventory first and goes back with the
-- same metadata if the laptop can't take it. A data stick gets its serial here the first time
---@param plyId integer
---@param ownerId integer
---@param portId string
---@param slot integer
---@param expectedName? string @ Item the slot held when the player picked it
---@return boolean plugged
---@return string? reason @ Locale key
function ZykeLaptopServerExports:PlugDevice(plyId, ownerId, portId, slot, expectedName) end

-- Pulls the device out of a port and gives the player that same item with its metadata. The port is emptied first
-- and filled again when the item could not be given
---@param plyId integer
---@param ownerId integer
---@param portId string
---@return boolean unplugged
---@return string? reason @ Locale key
function ZykeLaptopServerExports:UnplugDevice(plyId, ownerId, portId) end

-- The hardware of a laptop: one a player has out, by their server id, a laptop item in a player's slot, or one by its
-- serial while it is out, or any time without a laptop item
---@param target integer | LaptopHardwareTarget
---@return LaptopHardware? hardware @ A copy, nil for a laptop item that was not taken out since hardware came in
function ZykeLaptopServerExports:GetLaptopHardware(target) end

-- Metadata for a new laptop item built as one of the prebuilts, for Z.addItem. Every serial is new
---@param prebuiltId? string @ hardware.default when left out
---@param base? table @ More metadata the item gets, such as a finish or the os installed. Its owner, a character identifier, becomes the laptop's owner instead
---@return table | false metadata @ False with the reason, an export drops anything after a nil
---@return string? err @ "unknownPrebuilt"
function ZykeLaptopServerExports:CreateLaptopMetadata(prebuiltId, base) end

-- Metadata for a new part item, for Z.addItem, with the label and description ox_inventory shows
---@param itemName string
---@param modelId string
---@param opts? LaptopPartOptions
---@return table | false metadata @ False with the reason, an export drops anything after a nil
---@return string? err @ "unknownItem" or "unknownModel"
function ZykeLaptopServerExports:CreatePartMetadata(itemName, modelId, opts) end

-- What a part item is and what shape it is in, for shops, tooltips and other resources. A memory fault only shows once
-- the stick was tested
---@param itemName string
---@param metadata? table
---@return LaptopPartInfo? info @ Nil for an item that is no part or a model the catalogue doesn't have
function ZykeLaptopServerExports:GetPartInfo(itemName, metadata) end

-- Installs a part item into, or takes the part out of, a slot of the laptop item in a player's inventory slot, with the
-- service view's checks and hooks but no screws. An installed item is not taken from any inventory, and a removed part
-- is handed back to the caller, not given to anyone
---@param plyId integer
---@param slot integer @ Inventory slot of the laptop item
---@param slotId string @ "board", "cooler", "ram0", "ram1", "ssd", "wifi" or "battery"
---@param item? {name: string, metadata: table} @ The part to install, nil takes the part out
---@return boolean done
---@return LaptopStoredPart | string | nil result @ The removed part with its item metadata, or the locale key of the reason
function ZykeLaptopServerExports:SetLaptopHardwareSlot(plyId, slot, slotId, item) end

-- The repair shop's shortcut for a laptop item in a player's inventory slot, without the service view or its supplies:
-- "clean" blows the fan clean, "repaste" puts fresh paste or a fresh pad on, "battery" reconditions the battery to full
-- health
---@param plyId integer
---@param slot integer @ Inventory slot of the laptop item
---@param kinds ("clean" | "repaste" | "battery")[]
---@return boolean repaired
---@return string? err @ Locale key
function ZykeLaptopServerExports:RepairLaptop(plyId, slot, kinds) end

-- What a laptop's parts are and how they run, worked out as for the OS: the processor, its built-in graphics, the
-- memory that works, the heat from dust and dried paste and the one speed factor it all comes to
---@param target string | LaptopItemTarget @ The serial of a laptop that is out, or a laptop item
---@return LaptopSpecs | false specs @ False with the reason, an export drops anything after a nil
---@return string? err @ "invalid", "notOut", "noLaptopItem" or "noHardware"
function ZykeLaptopServerExports:GetLaptopSpecs(target) end

-- Wears a laptop on top of the wear it gathers on its own, for a load such as mining. A laptop that is out wears
-- through the same values its own wear grows, so neither undoes the other, and every OS on it gets its parts as they
-- are now. A laptop item is written in its slot, and a laptop item's metadata or hardware passed in comes back worn for
-- the caller to keep. A computer's parts never wear on their own, but this wears them too
---@param target string | LaptopItemTarget @ The serial of a laptop that is out, or a laptop item
---@param wear LaptopWear
---@return boolean worn
---@return table | string | nil result @ The worn metadata or hardware for a target passed as one, otherwise the reason it failed: "invalid", "notOut", "noLaptopItem", "noHardware", "inService" or "notSaved"
function ZykeLaptopServerExports:WearLaptop(target, wear) end

-- A laptop that is out, held or put down, as the status exports tell about it
---@param serial string
---@return LaptopStatus? status @ Nil while the laptop isn't out
function ZykeLaptopServerExports:GetLaptopStatus(serial) end

-- The status of many laptops in one call, for a resource that checks a room full of them at once
---@param serials string[]
---@return table<string, LaptopStatus> statuses @ By serial, only the laptops that are out
function ZykeLaptopServerExports:GetLaptopStatuses(serials) end

-- The laptops and computers put down right now. One waiting to go back to its character's inventory is in no world and
-- left out
---@param filter? LaptopPlacedFilter
---@return LaptopPlacedEntry[] laptops
function ZykeLaptopServerExports:GetPlacedLaptops(filter) end

---@param serial string
---@return string? identifier @ Character that owns the laptop, nil when nobody does
function ZykeLaptopServerExports:GetLaptopOwner(serial) end

-- The laptop has no owner any more, and whoever takes it out next claims it
---@param serial string
---@param origin? string @ "release" when left out
---@return boolean released @ False when it had no owner
function ZykeLaptopServerExports:ReleaseLaptopOwner(serial, origin) end

-- The laptops a character owns, the newest first
---@param identifier string
---@return LaptopOwnedEntry[] laptops
function ZykeLaptopServerExports:GetCharacterLaptops(identifier) end

-- Only exports read the flag, nothing in the laptop acts on it
---@param serial string
---@return boolean stolen
function ZykeLaptopServerExports:IsLaptopReportedStolen(serial) end

-- The laptop's owner by its chassis serial. LaptopOwnerChanged names the calling resource as what set it
---@param serial string
---@param identifier string
---@return boolean set
---@return string? err
function ZykeLaptopServerExports:SetLaptopOwner(serial, identifier) end

-- The drive exports take a drive's serial, a laptop's serial reads the SSD in it
---@param serial string
---@return LaptopLogEntry[] logs
function ZykeLaptopServerExports:GetLaptopLogs(serial) end

---@param serial string
---@return boolean isUnlocked
function ZykeLaptopServerExports:IsLaptopDriveUnlocked(serial) end

---@param serial string
---@return LaptopRecoveryReport? report
function ZykeLaptopServerExports:GetLaptopRecoveryReport(serial) end

-- A device type another resource adds, such as an antenna. It goes away when that resource stops, devices already in
-- a port stay there and can still be pulled out
---@param def LaptopDeviceRegistration
---@return boolean registered
---@return string? err
function ZykeLaptopServerExports:RegisterDeviceType(def) end

-- The ports every laptop has, in the port view's order
---@return LaptopPort[] ports
function ZykeLaptopServerExports:GetLaptopPorts() end

-- The devices in the laptop the player's OS runs on right now, their own or another player's they use
---@param plyId integer
---@return table<string, LaptopDeviceInfo>? devices @ Nil while their OS is off or runs without a laptop prop
function ZykeLaptopServerExports:GetSessionDevices(plyId) end

-- Takes the laptop out of the player's hands, a placed laptop stays where it is
---@param plyId integer
function ZykeLaptopServerExports:RemoveLaptop(plyId) end

---@return boolean enabled
function ZykeLaptopServerExports:IsCasinoEnabled() end

---@param player integer | string @ Server id or character identifier
---@return integer? balance @ Cents, nil without a wallet or while the casino is off
function ZykeLaptopServerExports:GetCasinoBalance(player) end

-- Gives or takes credits outside the games, written to the ledger as an adjustment with the reason
---@param player integer | string @ Server id or character identifier
---@param amount integer @ Cents, negative to take
---@param reason? string
---@return boolean adjusted
---@return integer | string balanceOrError @ The balance after it, or "disabled", "invalid", "noAccount" or "insufficient"
function ZykeLaptopServerExports:AdjustCasinoCredits(player, amount, reason) end

---@param contact ChatContactRegistration
---@return boolean registered
function ZykeLaptopServerExports:RegisterChatContact(contact) end

---@param contactId string
---@return boolean removed
function ZykeLaptopServerExports:RemoveChatContact(contactId) end

-- Listing messages players have on screen show the new listings at once
---@param contactId string
---@param listings ChatListing[]
---@return boolean updated
function ZykeLaptopServerExports:SetChatListings(contactId, listings) end

-- Delivers a message from the contact, even to a player who is offline or signed out
---@param contactId string
---@param target integer | string @ Player server id or handle
---@param message string | ChatMessageInput
---@return string? messageId @ Nil when the contact, target or message is invalid, or the player blocked the contact
function ZykeLaptopServerExports:SendChatMessage(contactId, target, message) end

-- Changes a message one of the resource's contacts sent. Top-level fields are replaced, card fields are merged into
-- the card, and false removes a field
---@param messageId string
---@param patch ChatMessageInput | {card?: ChatCard | false}
---@return boolean updated
function ZykeLaptopServerExports:UpdateChatMessage(messageId, patch) end

-- Opens the contact's conversation in Shroud if the player's screen is on, otherwise tells them a message is waiting
---@param plyId integer
---@param contactId string
---@return boolean sent
function ZykeLaptopServerExports:OpenChat(plyId, contactId) end

---@param plyId integer
---@return string? handle @ Nil while the player is signed out
function ZykeLaptopServerExports:GetChatHandle(plyId) end

---@param handle string
---@param since? integer @ Seconds since the epoch, only traces from then on
---@return ChatTraceRecord[] traces @ Oldest first
function ZykeLaptopServerExports:GetChatTraces(handle, since) end

---@param room ChatRoomRegistration
---@return boolean registered
function ZykeLaptopServerExports:RegisterChatRoom(room) end

---@param roomId string
---@return boolean removed
function ZykeLaptopServerExports:RemoveChatRoom(roomId) end

-- Coin by coin with their current prices, stale ones included and marked
---@return table[] coins
function ZykeLaptopServerExports:GetCryptoCoins() end

---@param coinId string
---@return number? price @ Money per coin, nil before the first update or for a coin that isn't listed
---@return boolean stale
function ZykeLaptopServerExports:GetCryptoPrice(coinId) end

-- Makes the wallet when the character has none yet
---@param target integer | string
---@param coinId string
---@return string? address @ The character's address of that coin
function ZykeLaptopServerExports:GetCryptoAddress(target, coinId) end

---@param address string
---@return string? identifier @ The character the address belongs to
---@return string? coinId @ The coin the address is for
function ZykeLaptopServerExports:GetCryptoAddressOwner(address) end

---@param target integer | string
---@param coinId string
---@return number amount @ Coins, 0 without a wallet
---@return integer units @ Base units, exact
function ZykeLaptopServerExports:GetCryptoBalance(target, coinId) end

-- The addresses, every listed balance and what it is worth at the last prices. Coins still on their way in aren't
-- in the balances
---@param target integer | string
---@return table? wallet @ {addresses = {[coinId] = address}, total, balances = {[coinId] = {units, amount, value}}}
function ZykeLaptopServerExports:GetCryptoWallet(target) end

-- A charge's or payout's transfer, to check on it after a restart of the calling resource
---@param transferId integer
---@return table? transfer @ {id, kind, coin, status, units, amount, feeUnits, confirmations, createdAt, includedAt, confirmAt, sender, recipient, resource, note}
function ZykeLaptopServerExports:GetCryptoTransfer(transferId) end

-- Takes crypto from a character, such as a payment to a seller. coinId "any" takes a money amount in whichever coin
-- covers it with the most value. Money amounts need a fresh price, coin amounts don't. The coins and the network fee
-- leave the wallet at once, and the payment confirms after the coin's blocks
---@param target integer | string
---@param coinId string @ A listed coin's id or "any"
---@param amount number | {fiat?: number, coins?: number | string}
---@param reason? string @ Shown in the player's history
---@param options? CryptoPaymentOptions
---@return boolean charged
---@return CryptoPaymentResult | string resultOrError @ Or "invalid", "stale", "belowMinimum", "insufficient" or "failed"
function ZykeLaptopServerExports:ChargeCrypto(target, coinId, amount, reason, options) end

-- Pays crypto to a character, such as a buyer paying a dark web seller. A money amount needs a fresh price. The
-- coins reach the wallet once the payout confirms, the paying side covers the network fee. The character gets a
-- laptop notification when they are online
---@param target integer | string
---@param coinId string @ A listed coin's id
---@param amount number | {fiat?: number, coins?: number | string}
---@param reason? string @ Shown in the player's history
---@param options? CryptoPaymentOptions
---@return boolean given
---@return CryptoPaymentResult | string resultOrError @ Or "invalid", "stale", "belowMinimum" or "failed"
function ZykeLaptopServerExports:GiveCrypto(target, coinId, amount, reason, options) end

-- Register again on the zyke_laptop:domains:Ready server event, which fires when the laptop restarts
---@param provider DomainProviderRegistration
---@return boolean registered
function ZykeLaptopServerExports:RegisterDomainProvider(provider) end

-- Only the resource that registered a provider can take it away
---@param providerId string
function ZykeLaptopServerExports:UnregisterDomainProvider(providerId) end

---@return DomainProvider[] providers @ By label
function ZykeLaptopServerExports:GetDomainProviders() end

---@param host string
---@return DomainInfo? domain
function ZykeLaptopServerExports:GetDomain(host) end

---@param identifier string
---@return DomainInfo[] domains
function ZykeLaptopServerExports:GetCharacterDomains(identifier) end

-- The active domains pointed at a provider, such as every blog a blog resource serves
---@param providerId string
---@return DomainInfo[] domains
function ZykeLaptopServerExports:GetProviderDomains(providerId) end

-- For a provider's own server checks, such as letting only the owner edit the page
---@param plyId integer
---@param host string
---@return boolean owner @ False for a rental that ran out
function ZykeLaptopServerExports:IsDomainOwner(plyId, host) end

-- Gives a character a domain without payment, also one with an ending that isn't for sale or a reserved name, such
-- as lspd.gov for the police
---@param identifier string
---@param host string
---@param mode? DomainMode @ owned when unset
---@param days? integer @ How long a rental runs
---@return boolean granted
---@return string? err @ "invalid" or "taken"
function ZykeLaptopServerExports:GrantDomain(identifier, host, mode, days) end

---@param host string
---@return boolean released
function ZykeLaptopServerExports:ReleaseDomain(host) end

-- Hands the domain to another character, such as after a sale between players
---@param host string
---@param identifier string
---@return boolean changed
function ZykeLaptopServerExports:SetDomainOwner(host, identifier) end

-- Points the domain at a provider, or nowhere with false
---@param host string
---@param providerId string | false
---@return boolean changed
---@return string? err @ "notFound" or "providerMissing"
function ZykeLaptopServerExports:SetDomainProvider(host, providerId) end

-- Waits for the job's end, so call it from a thread, an event or a command
---@param plyId integer
---@param opts LaptopHackOptions
---@return boolean success
---@return string reason @ success, or why it failed or was refused
---@return LaptopHackTrace? trace @ Nil when it never started
function ZykeLaptopServerExports:RequestHack(plyId, opts) end

-- Returns at once. A job that was accepted calls callback when it ends, a refused one never does
---@param plyId integer
---@param opts LaptopHackOptions
---@param callback fun(success: boolean, reason: string, trace?: LaptopHackTrace)
---@return string? jobId
---@return string? reason @ Why it was refused
function ZykeLaptopServerExports:StartHack(plyId, opts, callback) end

-- Only the resource that asked for a job can cancel it
---@param plyId integer
---@param jobId string
---@return boolean cancelled
function ZykeLaptopServerExports:CancelHack(plyId, jobId) end

---@param to string | string[]
---@param mail MailResourceMail
---@return string? messageKey
---@return string? err
function ZykeLaptopServerExports:SendMail(to, mail) end

---@param identifier string
---@return string? address @ The character's Nimbus address, nil without an account
function ZykeLaptopServerExports:GetMailAddress(identifier) end

---@param identifier string
---@return string[] addresses @ Their Nimbus address first, then every domain address they have access to
function ZykeLaptopServerExports:GetMailAddresses(identifier) end

-- Gives an address on a registered domain to a script, members get access at once. Ownership and grants are not
-- checked, the domain only has to be registered. Yields
---@param address string @ Such as "dispatch@lspd.gov"
---@param members? string[] @ Character identifiers
---@param name? string @ The name mail from it goes out with
---@return boolean created
---@return string? err @ "invalid", "notFound", "taken" or "limit"
function ZykeLaptopServerExports:CreateMailbox(address, members, name) end

---@param address string
---@return boolean deleted
function ZykeLaptopServerExports:DeleteMailbox(address) end

---@param address string
---@param identifier string
---@param hasAccess boolean
---@return boolean changed
function ZykeLaptopServerExports:SetMailboxAccess(address, identifier, hasAccess) end

---@param address string
---@return string[]? members @ Character identifiers, nil for an address that isn't a domain mailbox
function ZykeLaptopServerExports:GetMailboxAccess(address) end

-- The department whose MDT the player may use right now, nil without one
---@param plyId integer
---@return string? departmentId
function ZykeLaptopServerExports:GetMdtDepartment(plyId) end

-- Sets the player's unit status, such as "enroute" when a dispatch resource assigns them to a call
---@param plyId integer
---@param status string @ A status id of the player's department
---@return boolean set
function ZykeLaptopServerExports:SetMdtUnitStatus(plyId, status) end

-- Posts a bulletin as the department itself
---@param departmentId string
---@param data {title: string, body: string, priority?: "info" | "important", mustAck?: boolean, expiresAt?: integer}
---@return integer? id
function ZykeLaptopServerExports:CreateMdtBulletin(departmentId, data) end

-- Adds a calendar event as the department itself, attendees are character identifiers
---@param departmentId string
---@param data table @ {kind, title, start, end, location?, coords?: {x, y, z?}, notes?, attendees?: string[]}, times in unix seconds
---@return integer? id
function ZykeLaptopServerExports:CreateMdtEvent(departmentId, data) end

-- The flag ids the department set on the character
---@param departmentId string
---@param identifier string
---@return string[] flags
function ZykeLaptopServerExports:GetMdtPersonFlags(departmentId, identifier) end

-- The character's phone number, read fresh every time since phones can change numbers without telling anyone. Yields
---@param plyId integer
---@return string? number @ The key
---@return string? phone @ As the phone stores it
---@return string? reason @ "noPhone" when a phone resource runs but they carry no phone or SIM, else zyke_lib's reason
function ZykeLaptopServerExports:GetMessengerNumber(plyId) end

---@param number string
---@return boolean hasAccount
function ZykeLaptopServerExports:HasMessengerAccount(number) end

-- A business players can message, shown as a verified account when verified is set. Replies reach onMessage
---@param id string
---@param business MessengerBusinessRegistration
---@return string? sender @ "biz:<id>", nil when the id or name is invalid
function ZykeLaptopServerExports:RegisterMessengerBusiness(id, business) end

-- Sends a message from a registered business or the built-in "system" account. Reaches the account even while it
-- has no session, unless it blocked the sender
---@param from string @ "system" or a business id
---@param toNumber string
---@param message string | MessengerResourceMessage
---@return string? messageId
function ZykeLaptopServerExports:SendMessengerMessage(from, toNumber, message) end

-- Who messaged whom and when, never the content, newest first. CanReadMessengerMetadata decides who may ask
---@param plyId integer @ The player asking, such as an officer
---@param number string @ The account looked into
---@param filter? {since?: integer, before?: integer, limit?: integer} @ Milliseconds since the epoch
---@return MessengerMetadataRow[]? rows @ Nil when the hook refuses
function ZykeLaptopServerExports:GetMessengerMetadata(plyId, number, filter) end

-- Registers what racks can send compute to, or replaces the calling resource's own. Each tick onWork(work, rack, state)
-- gets the work its share did and may return {status, progress, state}; see the README's Racks section
---@param id string
---@param definition table
---@return boolean registered
---@return string? err @ "invalid" or "taken"
function ZykeLaptopServerExports:RegisterRackWorkload(id, definition) end

-- Takes away a workload the calling resource registered
---@param id string
function ZykeLaptopServerExports:UnregisterRackWorkload(id) end

---@return RackWorkloadInfo[] workloads
function ZykeLaptopServerExports:GetRackWorkloads() end

---@param rackId integer
---@return RackInfo? rack
function ZykeLaptopServerExports:GetRack(rackId) end

-- Every rack that matches the filter, such as the ones near a spot that draw a lot for a power company's tip-off
---@param filter? {owner?: string, member?: string, bucket?: integer, coords?: vector3, radius?: number, minDraw?: number, on?: boolean}
---@return RackInfo[] racks
function ZykeLaptopServerExports:GetRacks(filter) end

-- The racks a character owns or is a member of
---@param identifier string
---@return RackInfo[] racks
function ZykeLaptopServerExports:GetCharacterRacks(identifier) end

-- Where a laptop stands, by its serial, such as to find a stolen one
---@param serial string
---@return integer? rackId
---@return integer? slot
function ZykeLaptopServerExports:FindRackBySerial(serial) end

---@param rackId integer
---@return number draw @ Watts the rack draws now
---@return number compute @ What it gives now, per second
---@return number supply @ Watts it may draw before its breaker trips
function ZykeLaptopServerExports:GetRackPower(rackId) end

-- Sets the watts one rack may draw, over the config and the GetRackPowerSupply hook, such as from a generator or a
-- building's power. false goes back to them. It isn't kept through a restart
---@param rackId integer
---@param watts number | false
---@return boolean set
function ZykeLaptopServerExports:SetRackPowerSupply(rackId, watts) end

---@param rackId integer
---@param on boolean
---@return boolean set
function ZykeLaptopServerExports:SetRackOn(rackId, on) end

-- Sets the share of a rack's compute one workload gets, 0 to 100, without asking its owner
---@param rackId integer
---@param workloadId string
---@param share integer
---@return boolean set
---@return string? err @ "notFound", "invalid", "unknownWorkload" or "overAllocated"
function ZykeLaptopServerExports:SetRackShare(rackId, workloadId, share) end

-- Sets a rack down on a spot the calling resource picked, such as a workshop's floor grid, after it cancelled
-- zyke_laptop:racks:Placing. It takes the rack item from the player, the used slot first, and checks the spot as for a
-- rack set down by hand, but not the player's reach. The player is told why one is refused
---@param plyId integer
---@param coords vector4 @ On the floor under the rack, w is the heading
---@param options? {slot?: integer, free?: boolean} @ free sets it down without taking an item, for an admin
---@return integer? rackId
---@return string? refusal @ Locale key, nil while racks are still loading
function ZykeLaptopServerExports:PlaceRack(plyId, coords, options) end

-- Picks an empty rack up into the player's inventory for the calling resource, with the same rules as at the rack but
-- no reach check. The player is told why one is refused
---@param plyId integer
---@param rackId integer
---@return boolean pickedUp
---@return string? refusal @ Locale key
function ZykeLaptopServerExports:PackRack(plyId, rackId) end

---@param rackId integer
---@return boolean? standing @ Nil until the racks are back from the database
function ZykeLaptopServerExports:IsRackStanding(rackId) end

-- Takes the rack and its laptops out of the world, without giving anything to anyone. Returns the items, so the calling
-- resource decides where they go, such as an evidence locker
---@param rackId integer
---@return {name: string, metadata?: table}[]? items @ The laptops and the rack, nil for no rack or one being changed
function ZykeLaptopServerExports:RemoveRack(rackId) end

-- The site on a domain with the published site while visitors see it. Reads the published site from the database
-- when it isn't in memory, so it may yield
---@param host string
---@return SiteInfo? site @ Nil for a domain without a Sitewright site
function ZykeLaptopServerExports:GetSite(host) end

-- The site's visitor stats for the last days days, today included: totals, each day and the views of each page and
-- post. Nil for a domain without a Sitewright site or while stats are off. Reads the database, so it yields
---@param host string
---@param days? integer @ 30 when left out, at most Config.Domains.builder.stats.retentionDays
---@return SiteStats? stats
function ZykeLaptopServerExports:GetSiteStats(host, days) end

-- Every booking the site's booking blocks took that is still kept, earliest first: upcoming, past, done and cancelled
-- ones. Empty for a domain without bookings or while bookings are off. Reads the database, so it yields
---@param host string
---@return SiteBookingInfo[] bookings
function ZykeLaptopServerExports:GetSiteBookings(host) end

-- Visitors of the domain see its Sitewright site
---@param host string
---@return boolean live
function ZykeLaptopServerExports:IsSitePublished(host) end

-- The same as /laptop_site_takedown and /laptop_site_lock, with the calling resource as who took it down
---@param host string
---@param reason? string @ Shown to the owner
---@param lock? boolean @ Refuse every publish until LiftSiteTakedown
---@return boolean takenDown
---@return string? err @ "notFound" or "notLive", a takedown without lock needs a live site
function ZykeLaptopServerExports:TakeDownSite(host, reason, lock) end

-- The owner may publish again, the site stays offline until they do
---@param host string
---@return boolean lifted
---@return string? err @ "notFound" or "noTakedown"
function ZykeLaptopServerExports:LiftSiteTakedown(host) end

-- The site's co-editors with their role, the domain's owner isn't one of them
---@param host string
---@return SiteEditorRecord[] editors @ The first one named first
function ZykeLaptopServerExports:GetSiteEditors(host) end

-- Gives a character a role on the site, or takes their access away with false, such as for the members of a job. The
-- same as the owner doing it in Sitewright, with no owner as who did it. Yields
---@param host string
---@param identifier string
---@param role SiteEditorRole | false
---@return boolean done
---@return string? err @ "notFound", "invalid", "disabled", "isOwner", "expired" or "editorLimit"
function ZykeLaptopServerExports:SetSiteEditor(host, identifier, role) end

-- A live data block owners can add to their sites, see the README for the definition. It goes away when the calling
-- resource stops, so register it again on the zyke_laptop:Ready server event, which fires when the laptop restarts
---@param blockId string
---@param definition SiteBlockDefinition
---@return boolean registered
---@return string? err @ "invalid" or "taken", the console says why
function ZykeLaptopServerExports:RegisterSiteBlock(blockId, definition) end

-- Only the resource that registered a block can take it away. Sites using it show it as unavailable
---@param blockId string
function ZykeLaptopServerExports:UnregisterSiteBlock(blockId) end

-- Drops the block's kept answers, so the next visitor gets fresh data, such as after the stock it lists changed
---@param blockId string
function ZykeLaptopServerExports:RefreshSiteBlock(blockId) end

-- The registered blocks as the editor offers them, without their functions, by label
---@return SiteBlockInfo[] list
function ZykeLaptopServerExports:GetSiteBlocks() end

-- Registers an app: what the OS shows (label, icon, page, window) and what the server allows its pages (storage,
-- payments, rooms, cast, access, price, permissions). Every client gets it, register again on zyke_laptop:Ready
---@param def SdkAppRegistration
---@return boolean registered
---@return string? err @ "invalid" or "taken"
function ZykeLaptopServerExports:RegisterApp(def) end

---@param def SdkSiteRegistration
---@return boolean registered
---@return string? err @ "invalid" or "taken"
function ZykeLaptopServerExports:RegisterSite(def) end

---@param appId string
function ZykeLaptopServerExports:UnregisterApp(appId) end

---@param siteId string
function ZykeLaptopServerExports:UnregisterSite(siteId) end

-- A world sound at the player's ped, heard by everyone near them, for something physical an app does such as a card or
-- PIN step. Pages never play world sounds; call this from your server code. Only for a resource that registered an app
-- or site, while the player's laptop is on, a few per player and one per sound and area each second. The sounds and
-- their range are the sdk keys in zyke_laptop's shared/unlocked/sounds.lua
---@param plyId integer
---@param name "keypad" | "plug" | "notice" | "cardReader"
---@return boolean played @ False for an unknown name, no laptop on, or a spent budget
function ZykeLaptopServerExports:PlayAppSound(plyId, name) end

---@param plyId integer @ The player who pays, online and at a laptop when they confirm
---@param options SdkPaymentOptions
---@return string? paymentId
---@return string? err @ "invalid", "notRegistered", "payeeNotAllowed", "conflict" or "disabled"
function ZykeLaptopServerExports:CreatePayment(plyId, options) end

---@param paymentId string
---@return SdkPayment? payment @ Nil for another resource's payment
function ZykeLaptopServerExports:GetPayment(paymentId) end

---@param filter? {status?: SdkPaymentStatus, fulfilled?: boolean, identifier?: string, since?: integer, limit?: integer}
---@return SdkPayment[] payments @ The calling resource's, newest first, 100 at most
function ZykeLaptopServerExports:GetPayments(filter) end

---@param paymentId string
---@return boolean marked
function ZykeLaptopServerExports:MarkPaymentFulfilled(paymentId) end

-- Only while it is pending, such as when the order it was for sold out
---@param paymentId string
---@return boolean cancelled
function ZykeLaptopServerExports:CancelPayment(paymentId) end

---@param paymentId string
---@param options? {amount?: integer, reason?: string}
---@return boolean refunded
---@return string? err @ "notFound", "invalid", "payeeFunds" or "failed"
function ZykeLaptopServerExports:RefundPayment(paymentId, options) end

-- The same rule the SDK calls follow, for a resource's own NUI callbacks behind Laptop.post
---@param plyId integer
---@param appId string
---@param kind? "app" | "site" @ "app" when left out
---@return boolean allowed
---@return string? code @ "notRegistered", "noAccess" or "notLicensed"
function ZykeLaptopServerExports:CanUseApp(plyId, appId, kind) end

-- The account the player's laptop is signed in to now, nil while they use none. appUserId only comes for an app or
-- site the calling resource registered on the server
---@param plyId integer
---@param appId? string
---@param kind? "app" | "site" @ "app" when left out
---@return SdkAccount? account
function ZykeLaptopServerExports:GetLaptopAccount(plyId, appId, kind) end

-- An image every viewer's game may load: one of the laptop's own pictures, a file of a resource, an inline image, or
-- an address on a host the config lets through. Any other host would learn who looked at the screen
---@param url any
---@return boolean allowed
function ZykeLaptopServerExports:IsCastImageAllowed(url) end

-- Text cut to a number of characters, nil when it is not valid UTF-8 or holds nothing but control characters
---@param value any
---@param maxLength integer @ Characters
---@return string? text
function ZykeLaptopServerExports:ToCastText(value, maxLength) end

---@param plyId integer
---@param appId string
---@param kind? "app" | "site"
---@return boolean licensed @ True for a free app
function ZykeLaptopServerExports:HasAppLicence(plyId, appId, kind) end

-- Only for an app the calling resource registered, such as for a promotion
---@param target integer | string @ A player's current owner, or an owner key
---@param appId string
---@return boolean granted
function ZykeLaptopServerExports:GrantAppLicence(target, appId) end

---@param target integer | string
---@param appId string
---@return boolean revoked
function ZykeLaptopServerExports:RevokeAppLicence(target, appId) end

---@param appId string
---@param room string
---@param data any
---@param toPlyId? integer @ One member, everyone when left out
---@return boolean sent
function ZykeLaptopServerExports:SendRoomMessage(appId, room, data, toPlyId) end

---@param appId string
---@param room string
---@return {plyId: integer, memberId: string, data?: any}[] members
function ZykeLaptopServerExports:GetRoomMembers(appId, room) end

---@param appId string
---@param room string
---@param plyId integer
---@return boolean kicked
function ZykeLaptopServerExports:KickFromRoom(appId, room, plyId) end

---@param appId string
---@param room string
---@return boolean closed
function ZykeLaptopServerExports:CloseRoom(appId, room) end

---@param options any
---@return string? serial
---@return table? metadata
---@return string? err
function ZykeLaptopServerExports:CreateDataStick(options) end

---@param plyId integer
---@param options {label?: string, files?: SdkStickFileInput[]}
---@return string? serial
---@return string? err @ Also "noSpace" when the inventory refused the item
function ZykeLaptopServerExports:GiveDataStick(plyId, options) end

---@param serial string
---@return {path: string, kind: string, size: integer, modified: integer}[]? files @ Nil for an unknown stick
---@return string? label
function ZykeLaptopServerExports:GetDataStickFiles(serial) end

---@param serial string
---@param path string
---@return string? content
---@return string? err @ "invalid", "notFound" or "disabled"
function ZykeLaptopServerExports:ReadDataStickFile(serial, path) end

---@param serial string
---@param path string
---@param content string
---@param options? {overwrite?: boolean, kind?: "text" | "key"}
---@return boolean written
---@return string? err @ "invalid", "exists", "full" or "disabled"
function ZykeLaptopServerExports:WriteDataStickFile(serial, path, content, options) end

---@param serial string
---@param path string
---@return boolean deleted
---@return string? err @ "invalid", "notFound" or "disabled"
function ZykeLaptopServerExports:DeleteDataStickFile(serial, path) end

---@param serial string
---@param pattern string @ A Lua pattern matched against each path
---@param options? {plain?: boolean}
---@return string[] paths
function ZykeLaptopServerExports:FindDataStickFiles(serial, pattern, options) end

---@param serial string
---@param label string
---@return boolean labelled
---@return string? err @ "invalid", "notFound" or "disabled"
function ZykeLaptopServerExports:SetDataStickLabel(serial, label) end

---@param serial any
---@return boolean exists
function ZykeLaptopServerExports:DataStickExists(serial) end

-- target: a player, read from their current session's account, or an owner key such as "nimbus:<identifier>". What
-- a page wrote is untrusted, check it like any client input
---@param target integer | string
---@param appId string
---@param key? string @ The whole object when left out
---@param kind? "app" | "site"
---@return any value
function ZykeLaptopServerExports:GetAppStorage(target, appId, key, kind) end

---@param target integer | string
---@param appId string
---@param key string
---@param value any @ nil removes it
---@param kind? "app" | "site"
---@return boolean saved
---@return string? err @ "invalid", "tooLarge", "quota" or "notRegistered"
function ZykeLaptopServerExports:SetAppStorage(target, appId, key, value, kind) end

---@param resource? string
---@return table<string, table> health @ By resource, see the README's developer tools
function ZykeLaptopServerExports:GetSdkHealth(resource) end

-- Veil is always onion. The Onion connection comes from the client like IsConnected, so it only counts while the
-- server sees the laptop online
---@param plyId integer
---@return BrowsingTier? tier @ Nil while the player's OS is off
function ZykeLaptopServerExports:GetBrowsingTier(plyId) end

-- Every filter is optional and they all have to match
---@param filter? BrowsingTraceFilter
---@return BrowsingTraceRecord[] traces @ Newest first
function ZykeLaptopServerExports:GetSiteVisitTraces(filter) end

-- Marks a site as monitored for record = "monitored", until the marking resource stops
---@param url string
---@param monitored? boolean @ false stops recording it, defaults to true
---@return boolean changed
function ZykeLaptopServerExports:SetSiteMonitored(url, monitored) end

-- Newest first. Every filter is optional and they all have to match
---@param filter? {id?: string, target?: string, resource?: string, serial?: string, character?: string, since?: integer, limit?: integer}
---@return LaptopHackTrace[] traces
function ZykeLaptopServerExports:GetHackTraces(filter) end

-- A network as it pays now. perUnitHour is what one unit of hashrate mines an hour before the pool's fee, pays the
-- share of its full rate that is, server the hashrate the difficulty counts from the server's racks
---@param coin string
---@return MiningNetworkState? network @ Nil for a coin without a network
function ZykeLaptopServerExports:GetMiningNetwork(coin) end

-- Posts a call on the dispatch board of the departments it names, such as an alarm or a robbery. Answers its id, nil
-- when the data isn't valid or no department matches
---@param data {title: string, description?: string, code?: string, priority?: integer, coords: {x: number, y: number, z?: number}, location?: string, departments?: string | string[], jobs?: string | string[], types?: string | string[], caller?: string, source?: string}
---@return integer? id
function ZykeLaptopServerExports:CreateMdtCall(data) end

-- The character's death certificate, nil without one
---@param identifier string
---@return MdtDeathCertificate? certificate
function ZykeLaptopServerExports:GetMdtDeathCertificate(identifier) end

-- The character's medical record, nil when EMS never wrote one
---@param identifier string
---@return MdtPatient? patient
function ZykeLaptopServerExports:GetMdtPatient(identifier) end

-- For a pharmacy resource: dispenses an active prescription once, a refill left keeps it active
---@param prescriptionId integer
---@return {identifier: string, medication: string, label: string, dose: string, quantity: integer, refillsLeft: integer}? dispensed @ Nil when it isn't active
function ZykeLaptopServerExports:DispenseMdtPrescription(prescriptionId) end

-- Everything the shops know of the plate, newest first
---@param plate string
---@return MdtHistoryEntry[] entries
function ZykeLaptopServerExports:GetMdtServiceHistory(plate) end

-- The plate's newest roadworthiness certificate, nil without one. Check passed and expiresAt
---@param plate string
---@return MdtRoadworthiness? certificate
function ZykeLaptopServerExports:GetMdtCertificate(plate) end

-- A tow request from another resource, such as a dispatch or the police after a crash. Answers its id, nil when the
-- department isn't a mechanic one or the data isn't valid
---@param departmentId string
---@param data {plate?: string, coords: {x: number, y: number, z?: number}, location: string, reason: string, source?: "export" | "police"}
---@return integer? id
function ZykeLaptopServerExports:CreateMdtTowRequest(departmentId, data) end

-- Registers a weapon to a character, such as when a gun shop sells one. An existing serial moves to the new owner
---@param identifier string
---@param serial string
---@param modelLabel string
---@return boolean registered
function ZykeLaptopServerExports:RegisterMdtWeapon(identifier, serial, modelLabel) end

-- Shapes of the SDK
-- SDK: core

---@alias SdkErrorCode "invalid" | "unsupported" | "notRegistered" | "notAllowed" | "noAccess" | "notLicensed" | "denied" | "cancelled" | "busy" | "rateLimited" | "tooLarge" | "quota" | "notFound" | "gone" | "offline" | "notReady" | "noFunds" | "expired" | "timeout" | "failed"
---@alias SdkPaymentStatus "pending" | "settling" | "settled" | "cancelled" | "expired" | "failed" | "review"
---@alias SdkPermission "account" | "clipboard" | "job" | "notifications"

-- The fields of RegisterApp and RegisterSite that decide what the server allows the pages
---@class SdkFeatureFields
---@field storage? {maxBytes?: integer}
---@field payments? {payees?: string[]} @ Payees this app may use, such as "society:fleeca"; every allowed kind when left out
---@field rooms? SdkRoomsRegistration
---@field cast? SdkCastRegistration @ Apps only
---@field access? SdkAccessRules
---@field price? {amount: integer, currency: "bank" | "crypto" | "either", payee?: string}
---@field permissions? SdkPermission[]

-- What another resource passes to the RegisterApp export
---@class SdkAppRegistration : LaptopAppRegistration, SdkFeatureFields

-- What another resource passes to the RegisterSite export, cast is for apps only
---@class SdkSiteRegistration : LaptopSiteRegistration, SdkFeatureFields

---@class SdkRoomsRegistration
---@field maxMembers? integer
---@field messageBytes? integer
---@field rate? {count: integer, rate: number}
---@field join? fun(plyId: integer, room: string, data: any): boolean, any

---@class SdkCastRegistration
---@field ui string @ A page inside the registering resource
---@field snapshot fun(content: any): any
---@field delta? fun(delta: any): any
---@field signal? fun(signal: any): any

---@class SdkAccessRules
---@field jobs? table<string, integer> | string[] @ Job to minimum grade, or job names at any grade
---@field onDuty? boolean
---@field items? string[]
---@field ace? string | string[]
---@field any? boolean @ One passing category is enough instead of all

-- A registration as the registry keeps it
---@class SdkServerApp
---@field key string @ "app:<id>" or "site:<id>"
---@field kind "app" | "site"
---@field id string
---@field resource string
---@field page? LaptopApp | LaptopSite @ What the clients get, nil for a built-in app
---@field fields table<string, any> @ Parsed fields by name, see RegisterSdkField
---@field builtIn? true @ An app of the OS itself, see RegisterBuiltInSdkApp
---@field stale? true @ Its resource stopped with hot reload on and hasn't registered it again yet

---@class SdkAccount
---@field kind "nimbus" | "local" | "guest" | "live"
---@field name string
---@field address? string
---@field appUserId? string
---@field os LaptopOsId
---@field job? {name: string, label: string, grade: integer, gradeLabel: string, onDuty: boolean}

---@class SdkPaymentOptions
---@field app string
---@field kind? "app" | "site"
---@field amount integer
---@field currency? "bank" | "crypto" | "either" @ "bank" when left out
---@field label string
---@field lines? {label: string, qty: number, amount: integer}[]
---@field payee? string @ "server", "society:<name>" or "player:<identifier>"
---@field reference? string
---@field idempotencyKey? string
---@field expiresIn? integer @ Seconds
---@field metadata? table

---@class SdkPayment
---@field id string
---@field resource string
---@field app string
---@field identifier string
---@field reference? string
---@field label string
---@field amount integer
---@field currency "bank" | "crypto" | "either"
---@field method? "bank" | "crypto"
---@field coin? string
---@field cryptoTransfer? integer
---@field payee string
---@field status SdkPaymentStatus
---@field refunded integer
---@field fulfilled boolean
---@field lines? {label: string, qty: number, amount: integer}[]
---@field metadata? table
---@field createdAt integer
---@field expiresAt integer
---@field settledAt? integer

---@class SdkStickFileInput
---@field path string @ Such as "plans/vault.txt"
---@field content string
---@field kind? "text" | "key" @ "text" when left out

---@class SdkHandlerDef
---@field run fun(caller: SdkCaller, app?: SdkServerApp, args: table, request: {feature: string, op: string, kind: "app" | "site", id: string}): table
---@field rate? {count: integer, rate: number}
---@field bucket? string @ Rate bucket shared with other handlers, "<feature>:<op>" when left out
---@field registration? boolean @ False skips the registration check, true when left out

-- The player behind an SDK request, see server/locked/sdk/base/caller.lua
---@class SdkCaller
---@field plyId integer
---@field identifier string @ The character
---@field session LaptopSession
---@field os LaptopOsId
---@field accountKind "nimbus" | "local" | "guest" | "live"
---@field userId? LaptopUserId @ Nil on Veil and other USB boots
---@field ownerKey string @ Where per-account data lives: nimbus:<identifier>, drive:<serial>:<userId>, guest:<plyId>:<nonce> or live:<plyId>:<nonce>
---@field nonce string @ Changes every boot of the session, so live and guest data dies with it

-- Shapes of apps, sites and notifications
---@alias LaptopAppCategory "accessories" | "internet" | "office" | "system" | "utilities" | "other"

-- The page part of an app's registration, see SdkAppRegistration
---@class LaptopAppRegistration
---@field id string
---@field label string
---@field icon? string @ Lucide icon name or an image URL
---@field category? LaptopAppCategory
---@field description? string
---@field ui string @ Page shown in the window, a full URL or a path inside the registering resource
---@field window? LaptopWindowOptions
---@field favorite? boolean
---@field requiresConnection? boolean
---@field singleInstance? boolean
---@field desktop? boolean @ Puts a shortcut on the desktop of each account that gets the app, true when left out
---@field preinstalled? boolean @ Installs the app for each account that sees it for the first time instead of offering it in the app store
---@field os? LaptopOsId[] @ OSes the app shows on, every OS when left out. The recovery toolkit's session shows no registered app
---@field documents? LaptopAppDocument[] @ File types the app opens from Files, 8 at most

-- A file type an app owns: Files shows its emblem and label, and opens the file in the app
---@class LaptopAppDocument
---@field extension string @ Lower case, without the dot
---@field label string
---@field icon? string @ Lucide icon name
---@field color? string @ Such as "#2f7d4f"

-- Section of LS Pages, or of the Onion Directory for an onion site, a site is listed under
---@alias LaptopSiteCategory "government" | "services" | "business" | "shopping" | "finance" | "news" | "community" | "games" | "search" | "other"

-- The page part of a site's registration, see SdkSiteRegistration
---@class LaptopSiteRegistration
---@field id string
---@field url string @ Host typed into the address bar, such as "market5xq...onion"
---@field title string
---@field description? string
---@field keywords? string[] @ Words search matches without showing them
---@field icon? string
---@field ui string @ Page shown in the browser, a full URL or a path inside the registering resource
---@field listed? boolean @ Shown in the directory and search, defaults to true
---@field category? LaptopSiteCategory @ Unknown values are listed as "other"
---@field network? LaptopSiteNetwork @ Defaults to "onion" for .onion hosts and "clearnet" for the rest
---@field monitored? boolean @ Visits are recorded as traces with browsing.record = "monitored"

-- What another resource passes to the Notify export
---@class LaptopNotification
---@field title string
---@field text? string
---@field icon? string
---@field appId? string
---@field url? string @ Opened in the OS's browser when the notification is clicked, before appId
---@field params? table @ Passed to the app appId opens with
---@field duration? integer
---@field id? string @ Replaces the notification with the same id
---@field actions? {id: string, label: string}[] @ Two at most, a click fires zyke_laptop:NotificationAction
---@field data? any @ JSON of 1 KiB at most, handed back with an action
---@field sound? "click" | "send" | "receive" | "success" | "error" | "notification" | false @ Played instead of the chime, false is a silent banner

-- What another resource passes to the AddBookmark export. Every OS's browser shares the player's bookmarks
---@class LaptopBookmark
---@field id string @ Unique within the resource, the browser adds each id once
---@field url string
---@field title? string
---@field force? boolean @ Adds it again even when the player deleted it, for a player asking for the address again