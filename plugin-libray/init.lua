--[[
    init.lua  (plugin-libray)
    =========================
    Public façade that assembles and returns all plugin helpers as a
    single table.  This is the only file main.lua needs to require/loadstring.

    Returned table shape:
        Plugins = {
            Tween   — animation helpers (play, sequence, openWindow, pulse, …)
            Drag    — drag-and-drop (makeDraggable, makeResizable, …)
            Config  — persistent JSON storage (new, Set, Get, Save, Load, …)
        }

    When loaded via loadstring from GitHub the caller does:
        local rawBase = "https://raw.githubusercontent.com/…/plugin-libray/"
        local Plugins = loadstring(game:HttpGet(rawBase .. "init.lua"))()

    The init.lua itself loadstrings the sub-modules so every module gets its
    own clean environment.  If running inside Roblox Studio via Rojo you can
    swap loadstring() for require() instead.
--]]

-- ─── Raw GitHub base URL ──────────────────────────────────────────────────────
-- UPDATE THIS to your actual repository URL before deploying.
-- The trailing slash is required.
local RAW_BASE = "https://raw.githubusercontent.com/OWNER/REPO/main/plugin-libray/"

-- ─── Loader helper ───────────────────────────────────────────────────────────
-- Chooses between require() (Studio/Rojo) and loadstring() (executor).
local function loadModule(moduleName, moduleScript)
    -- If a ModuleScript sibling exists, prefer require() for Studio compat.
    if moduleScript then
        local ok, result = pcall(require, moduleScript)
        if ok then return result end
    end
    -- Fall back to HTTP loadstring for executor environments.
    local url  = RAW_BASE .. moduleName .. ".lua"
    local code = game:HttpGet(url, true)      -- true = bypass cache
    local fn, err = loadstring(code)
    if not fn then
        error(("[PluginLibray] Failed to compile %s: %s"):format(moduleName, tostring(err)))
    end
    return fn()
end

-- ─── Load sub-modules ─────────────────────────────────────────────────────────
-- When running as a ModuleScript tree, script.tween / script.drag / script.config
-- resolve to child ModuleScripts automatically.
local tweenScript  = (script and pcall(function() return script.tween  end)) and script.tween  or nil
local dragScript   = (script and pcall(function() return script.drag   end)) and script.drag   or nil
local configScript = (script and pcall(function() return script.config end)) and script.config or nil

local Tween  = loadModule("tween",  tweenScript)
local Drag   = loadModule("drag",   dragScript)
local Config = loadModule("config", configScript)

-- ─── Assemble Plugins table ───────────────────────────────────────────────────
local Plugins = {}

Plugins.Tween  = Tween
Plugins.Drag   = Drag
Plugins.Config = Config

--[[
    Plugins.newConfig(filePath, defaults)
        Convenience shortcut to create a Config instance without needing to
        reference Plugins.Config.new() directly.
--]]
function Plugins.newConfig(filePath, defaults)
    return Config.new(filePath, defaults)
end

--[[
    Plugins.play(instance, presetOrInfo, properties [, callback])
        Convenience shortcut for Tween.play()
--]]
function Plugins.play(instance, presetOrInfo, properties, callback)
    return Tween.play(instance, presetOrInfo, properties, callback)
end

return Plugins
