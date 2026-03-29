--[[
╔══════════════════════════════════════════════════════════════╗
║          NEXON RELOADED — Notification System                ║
║                       config.lua                            ║
╚══════════════════════════════════════════════════════════════╝

    Minden beállítás itt konfigurálható.
    Ne módosítsd a client.lua-t!
]]

Config = {}

-- ── STACK / QUEUE ──────────────────────────────────────────────
Config.Stack = {
    maxVisible = 5,     -- Egyszerre max ennyi notifikáció látható
    maxQueue   = 20,    -- Queue-ban max ennyi várakozhat
    direction  = "down" -- "down" | "up" — stack növekedési iránya
}

-- ── POZÍCIÓ ────────────────────────────────────────────────────
Config.Position = {
    -- Notification stack helye
    -- "top-right" | "top-left" | "bottom-right" | "bottom-left"
    stack = "top-right",

    -- Prompt (E - Interact stb.) helye
    -- "bottom-center" | "bottom-left" | "bottom-right"
    prompt = "bottom-center",

    -- Pixel offset-ek a képernyő szélétől
    offsetX = 32,
    offsetY = 96,
}

-- ── IDŐZÍTÉSEK (ms) ────────────────────────────────────────────
Config.Timing = {
    defaultDuration = 5000,  -- Alapértelmezett megjelenési idő (0 = végtelen)
    animateIn       = 350,   -- Megjelenési animáció hossza
    animateOut      = 300,   -- Eltűnési animáció hossza
}

-- ── ANIMÁCIÓK ──────────────────────────────────────────────────
Config.Animation = {
    -- Megjelenési stílus: "slide-fade" | "slide" | "fade" | "scale"
    enterStyle = "slide-fade",

    -- Eltűnési stílus: "slide-fade" | "slide" | "fade" | "scale"
    exitStyle  = "slide-fade",

    -- Error típusnál shake animáció
    errorShake = true,
}

-- ── TÍPUSONKÉNTI ALAPÉRTELMEZÉSEK ──────────────────────────────
Config.Types = {
    simple = {
        defaultDuration = 4000,
    },
    status = {
        defaultDuration = 5000,
    },
    interaction = {
        defaultDuration = 0,    -- 0 = végtelen, manuálisan kell zárni
    },
    discovery = {
        defaultDuration = 6000,
    },
    prompt = {
        defaultDuration = 0,    -- 0 = végtelen, manuálisan kell zárni
    },
}

-- ── ELŐRE DEFINIÁLT SZÍNEK ─────────────────────────────────────
-- Ezeket lehet megadni a color paraméterként
Config.Colors = {
    primary = "#e80043",
    error   = "#d53d18",
    success = "#22c55e",
    warning = "#f59e0b",
    info    = "#3b82f6",
    white   = "#ffffff",
    muted   = "#767577",
}

-- ── DEBUG ──────────────────────────────────────────────────────
Config.Debug = false  -- true = részletes print-ek a console-ba
