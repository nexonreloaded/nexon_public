--[[
╔══════════════════════════════════════════════════════════════╗
║          NEXON RELOADED — Notification System                ║
║                       client.lua                            ║
╚══════════════════════════════════════════════════════════════╝

    ── EXPORTOK (más resource-okból hívható) ──────────────────

    exports['nxn-notifications']:ShowSimple(options)
    exports['nxn-notifications']:ShowStatus(options)
    exports['nxn-notifications']:ShowInteraction(options)
    exports['nxn-notifications']:ShowDiscovery(options)
    exports['nxn-notifications']:ShowPrompt(options)
    exports['nxn-notifications']:Dismiss(id)
    exports['nxn-notifications']:DismissAll()
    exports['nxn-notifications']:Update(id, options)

    ── ESEMÉNY-ALAPÚ HÍVÁS ────────────────────────────────────

    TriggerEvent('nxn:notify', { type = "simple", ... })
    TriggerEvent('nxn:dismiss', id)
    TriggerEvent('nxn:dismissAll')
    TriggerEvent('nxn:update', id, options)
]]

-- ── State ──────────────────────────────────────────────────────
local visible  = {}   -- { [id] = true } — jelenleg látható notifikációk
local queue    = {}   -- { {type, options}, ... } — várakozó notifikációk
local timers   = {}   -- { [id] = citizen thread } — auto-dismiss timerek
local idCount  = 0    -- egyedi ID counter

-- ── Segédfüggvények ────────────────────────────────────────────
local function log(...)
    if Config.Debug then
        print("[NXN]", ...)
    end
end

local function uid()
    idCount = idCount + 1
    return ("nxn-%d-%d"):format(GetGameTimer(), idCount)
end

local function visibleCount()
    local n = 0
    for _ in pairs(visible) do n = n + 1 end
    return n
end

local function resolveColor(color)
    if not color then return nil end
    return Config.Colors[color] or color
end

local function getDuration(notifType, options)
    local d = options.duration
    if d ~= nil then return d end
    return Config.Types[notifType] and Config.Types[notifType].defaultDuration
        or Config.Timing.defaultDuration
end

-- ── NUI küldés ─────────────────────────────────────────────────
local function sendNUI(action, data)
    SendNUIMessage({ action = action, data = data })
end

-- ── Init: config küldése a JS-nek ──────────────────────────────
local function initNUI()
    sendNUI("init", {
        animIn      = Config.Timing.animateIn,
        animOut     = Config.Timing.animateOut,
        enterStyle  = Config.Animation.enterStyle,
        exitStyle   = Config.Animation.exitStyle,
        errorShake  = Config.Animation.errorShake,
        stackPos    = Config.Position.stack,
        promptPos   = Config.Position.prompt,
        offsetX     = Config.Position.offsetX,
        offsetY     = Config.Position.offsetY,
    })
    log("NUI inicializálva")
end

-- ── Auto-dismiss timer ──────────────────────────────────────────
local function startTimer(id, duration)
    if not duration or duration <= 0 then return end

    timers[id] = CreateThread(function()
        Wait(duration)
        -- Ellenőrzés hogy még él-e
        if visible[id] then
            exports['nxn-notifications']:Dismiss(id)
        end
    end)
end

local function clearTimer(id)
    if timers[id] then
        -- Thread leállítása nem szükséges, a visible check kezeli
        timers[id] = nil
    end
end

-- ── Queue kezelés ──────────────────────────────────────────────
local function tryDequeue()
    while #queue > 0 and visibleCount() < Config.Stack.maxVisible do
        local next = table.remove(queue, 1)
        -- Rekurzív hívás helyett közvetlen render
        if next.type == "simple" then
            exports['nxn-notifications']:ShowSimple(next.options)
        elseif next.type == "status" then
            exports['nxn-notifications']:ShowStatus(next.options)
        elseif next.type == "interaction" then
            exports['nxn-notifications']:ShowInteraction(next.options)
        elseif next.type == "discovery" then
            exports['nxn-notifications']:ShowDiscovery(next.options)
        end
    end
end

local function enqueue(notifType, options)
    if visibleCount() >= Config.Stack.maxVisible then
        if #queue < Config.Stack.maxQueue then
            table.insert(queue, { type = notifType, options = options })
            log("Queue-ba rakva:", notifType, options.id)
        else
            log("Queue tele, eldobva:", notifType)
        end
        return false
    end
    return true
end

-- ══════════════════════════════════════════════════════════════
-- BELSŐ RENDER FÜGGVÉNYEK
-- ══════════════════════════════════════════════════════════════

local function _showSimple(options)
    local id       = options.id or uid()
    local duration = getDuration("simple", options)

    if not enqueue("simple", { id = id, duration = duration,
        icon = options.icon, category = options.category,
        title = options.title, color = options.color,
        accentColor = resolveColor(options.color),
        shake = options.shake }) then return id end

    visible[id] = true

    sendNUI("simple", {
        id          = id,
        icon        = options.icon or "notifications",
        category    = options.category or "",
        title       = options.title or "",
        accentColor = resolveColor(options.color),
        duration    = duration,
        shake       = options.shake or false,
    })

    startTimer(id, duration)
    log("Simple megjelenítve:", id, options.title)
    return id
end

local function _showStatus(options)
    local id       = options.id or uid()
    local duration = getDuration("status", options)

    if not enqueue("status", { id = id, duration = duration,
        icon = options.icon, category = options.category,
        title = options.title, color = options.color,
        value = options.value, subtext = options.subtext }) then return id end

    visible[id] = true

    sendNUI("status", {
        id          = id,
        icon        = options.icon or "monitor_heart",
        category    = options.category or "",
        title       = options.title or "",
        accentColor = resolveColor(options.color) or Config.Colors.error,
        value       = options.value or 100,
        maxValue    = options.maxValue or 100,
        subtext     = options.subtext or "",
        duration    = duration,
    })

    startTimer(id, duration)
    log("Status megjelenítve:", id, options.title)
    return id
end

local function _showInteraction(options)
    local id       = options.id or uid()
    local duration = getDuration("interaction", options)

    visible[id] = true

    sendNUI("interaction", {
        id          = id,
        icon        = options.icon or "person_search",
        category    = options.category or "Interaction",
        name        = options.name or "Citizen",
        playerId    = options.playerId,
        message     = options.message or "",
        progress    = options.progress or 0,
        accentColor = resolveColor(options.color) or Config.Colors.white,
        duration    = duration,
    })

    startTimer(id, duration)
    log("Interaction megjelenítve:", id, options.name)
    return id
end

local function _showDiscovery(options)
    local id       = options.id or uid()
    local duration = getDuration("discovery", options)

    if not enqueue("discovery", { id = id, duration = duration,
        tag = options.tag, title = options.title,
        imageUrl = options.imageUrl, meta = options.meta,
        color = options.color }) then return id end

    visible[id] = true

    sendNUI("discovery", {
        id          = id,
        tag         = options.tag or "New Sector",
        title       = options.title or "",
        imageUrl    = options.imageUrl or "",
        meta        = options.meta or {},
        accentColor = resolveColor(options.color) or Config.Colors.primary,
        duration    = duration,
    })

    startTimer(id, duration)
    log("Discovery megjelenítve:", id, options.title)
    return id
end

local function _showPrompt(options)
    local id       = options.id or uid()
    local duration = getDuration("prompt", options)

    visible[id] = true

    sendNUI("prompt", {
        id          = id,
        key         = options.key or "E",
        text        = options.text or "",
        highlight   = options.highlight or "",
        accentColor = resolveColor(options.color) or Config.Colors.primary,
    })

    startTimer(id, duration)
    log("Prompt megjelenítve:", id, options.text)
    return id
end

local function _dismiss(id)
    if not visible[id] then return end
    visible[id] = nil
    clearTimer(id)
    sendNUI("dismiss", { id = id })
    log("Elrejtve:", id)

    -- Queue következő elemét próbáljuk megjeleníteni
    Wait(Config.Timing.animateOut + 50)
    tryDequeue()
end

local function _dismissAll()
    for id in pairs(visible) do
        visible[id] = nil
        clearTimer(id)
    end
    queue = {}
    sendNUI("dismissAll", {})
    log("Összes notifikáció elrejtve")
end

local function _update(id, options)
    if not visible[id] then return end
    local payload = { id = id }

    if options.title       then payload.title     = options.title     end
    if options.value       then payload.value      = options.value     end
    if options.label       then payload.label      = options.label     end
    if options.progress    then payload.progress   = options.progress  end
    if options.message     then payload.message    = options.message   end
    if options.color       then payload.accentColor = resolveColor(options.color) end

    sendNUI("update", payload)
    log("Frissítve:", id)
end

-- ══════════════════════════════════════════════════════════════
-- EXPORTOK
-- ══════════════════════════════════════════════════════════════

---Egyszerű szöveges értesítő
---@param options table { id?, icon?, category?, title, color?, duration?, shake? }
---@return string id
exports('ShowSimple', function(options)
    return _showSimple(options)
end)

---Állapot-jelző értesítő progress bar-ral
---@param options table { id?, icon?, category?, title, color?, value, maxValue?, subtext?, duration? }
---@return string id
exports('ShowStatus', function(options)
    return _showStatus(options)
end)

---Játékos-interakció értesítő
---@param options table { id?, icon?, category?, name, playerId?, message, progress?, color?, duration? }
---@return string id
exports('ShowInteraction', function(options)
    return _showInteraction(options)
end)

---Helyszín-felfedezés értesítő
---@param options table { id?, tag?, title, imageUrl?, meta?, color?, duration? }
---  meta: { {icon, text}, ... }
---@return string id
exports('ShowDiscovery', function(options)
    return _showDiscovery(options)
end)

---Interakció prompt (képernyő alján)
---@param options table { id?, key?, text, highlight?, color?, duration? }
---@return string id
exports('ShowPrompt', function(options)
    return _showPrompt(options)
end)

---Notifikáció elrejtése ID alapján
---@param id string
exports('Dismiss', function(id)
    _dismiss(id)
end)

---Összes notifikáció és prompt elrejtése
exports('DismissAll', function()
    _dismissAll()
end)

---Megjelenített notifikáció frissítése
---@param id string
---@param options table { title?, value?, label?, progress?, message?, color? }
exports('Update', function(id, options)
    _update(id, options)
end)

-- ══════════════════════════════════════════════════════════════
-- ESEMÉNY-ALAPÚ HÍVÁS (TriggerEvent)
-- ══════════════════════════════════════════════════════════════

---@usage TriggerEvent('nxn:notify', { type = "simple", title = "Hello", icon = "check" })
AddEventHandler('nxn:notify', function(options)
    local t = options.type
    if     t == "simple"      then _showSimple(options)
    elseif t == "status"      then _showStatus(options)
    elseif t == "interaction" then _showInteraction(options)
    elseif t == "discovery"   then _showDiscovery(options)
    elseif t == "prompt"      then _showPrompt(options)
    else
        log("Ismeretlen típus:", t)
    end
end)

---@usage TriggerEvent('nxn:dismiss', "nxn-123-1")
AddEventHandler('nxn:dismiss', function(id)
    _dismiss(id)
end)

---@usage TriggerEvent('nxn:dismissAll')
AddEventHandler('nxn:dismissAll', function()
    _dismissAll()
end)

---@usage TriggerEvent('nxn:update', "nxn-123-1", { value = 50, title = "Hunger: 50%" })
AddEventHandler('nxn:update', function(id, options)
    _update(id, options)
end)

-- ── Resource betöltéskor NUI init ──────────────────────────────
AddEventHandler('onClientResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    Wait(500) -- NUI betöltési idő
    initNUI()
end)
