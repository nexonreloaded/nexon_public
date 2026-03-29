--[[
╔══════════════════════════════════════════════════════════════╗
║          NEXON RELOADED — Notification System                ║
║                       server.lua                            ║
╚══════════════════════════════════════════════════════════════╝

    Szerver oldali exportok — más server script-ekből hívható.

    ── EXPORTOK ──────────────────────────────────────────────

    exports['nxn-notifications']:SendSimple(source, options)
    exports['nxn-notifications']:SendStatus(source, options)
    exports['nxn-notifications']:SendInteraction(source, options)
    exports['nxn-notifications']:SendDiscovery(source, options)
    exports['nxn-notifications']:SendPrompt(source, options)
    exports['nxn-notifications']:SendDismiss(source, id)
    exports['nxn-notifications']:SendDismissAll(source)
    exports['nxn-notifications']:SendUpdate(source, id, options)

    -- Broadcast: összes játékosnak
    exports['nxn-notifications']:BroadcastSimple(options)
]]

-- ── Segédfüggvény: NUI esemény küldése kliensnek ───────────────
local function triggerClient(source, eventName, ...)
    TriggerClientEvent(eventName, source, ...)
end

-- ══════════════════════════════════════════════════════════════
-- SZERVER → KLIENS EXPORTOK
-- ══════════════════════════════════════════════════════════════

---Egyszerű értesítő küldése egy játékosnak
---@param source number  Player server ID
---@param options table  { title, icon?, category?, color?, duration?, shake? }
exports('SendSimple', function(source, options)
    options.type = "simple"
    TriggerClientEvent('nxn:notify', source, options)
end)

---Állapot értesítő küldése egy játékosnak
---@param source number
---@param options table  { title, icon?, category?, value, maxValue?, subtext?, color?, duration? }
exports('SendStatus', function(source, options)
    options.type = "status"
    TriggerClientEvent('nxn:notify', source, options)
end)

---Interakció értesítő küldése egy játékosnak
---@param source number
---@param options table  { name, playerId?, message, progress?, icon?, category?, color?, duration? }
exports('SendInteraction', function(source, options)
    options.type = "interaction"
    TriggerClientEvent('nxn:notify', source, options)
end)

---Helyszín értesítő küldése egy játékosnak
---@param source number
---@param options table  { title, tag?, imageUrl?, meta?, color?, duration? }
exports('SendDiscovery', function(source, options)
    options.type = "discovery"
    TriggerClientEvent('nxn:notify', source, options)
end)

---Prompt küldése egy játékosnak
---@param source number
---@param options table  { key?, text, highlight?, color?, duration? }
exports('SendPrompt', function(source, options)
    options.type = "prompt"
    TriggerClientEvent('nxn:notify', source, options)
end)

---Notifikáció elrejtése egy játékosnál
---@param source number
---@param id string
exports('SendDismiss', function(source, id)
    TriggerClientEvent('nxn:dismiss', source, id)
end)

---Összes notifikáció elrejtése egy játékosnál
---@param source number
exports('SendDismissAll', function(source)
    TriggerClientEvent('nxn:dismissAll', source)
end)

---Notifikáció frissítése egy játékosnál
---@param source number
---@param id string
---@param options table
exports('SendUpdate', function(source, id, options)
    TriggerClientEvent('nxn:update', source, id, options)
end)

-- ══════════════════════════════════════════════════════════════
-- BROADCAST (összes játékosnak)
-- ══════════════════════════════════════════════════════════════

---Egyszerű értesítő küldése minden játékosnak
---@param options table
exports('BroadcastSimple', function(options)
    options.type = "simple"
    TriggerClientEvent('nxn:notify', -1, options)
end)

---Állapot értesítő küldése minden játékosnak
---@param options table
exports('BroadcastStatus', function(options)
    options.type = "status"
    TriggerClientEvent('nxn:notify', -1, options)
end)

---Discovery értesítő küldése minden játékosnak
---@param options table
exports('BroadcastDiscovery', function(options)
    options.type = "discovery"
    TriggerClientEvent('nxn:notify', -1, options)
end)
