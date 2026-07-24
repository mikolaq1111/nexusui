--[[
    config.lua  (plugin-libray)
    ===========================
    Persistent configuration storage for NexusUI menus.
    Saves / loads user settings (toggle states, slider values, dropdown choices,
    text-box content, window positions, etc.) to a JSON file on disk.

    Executor file-system functions used:
        writefile(path, content)   — write a string to a file
        readfile(path)             — read a string from a file
        isfile(path)               — returns true if the file exists
        makefolder(path)           — creates a directory (idempotent)

    These are standard executor globals (Synapse X, KRNL, Script-Ware, etc.).
    If the executor does not support them, all operations become no-ops so the
    script continues to run without errors.

    Usage:
        local Config = require(...)

        -- Create a config file in the "nexus" folder:
        local cfg = Config.new("nexus/my_menu.json")

        -- Save a value:
        cfg:Set("volume", 75)
        cfg:Set("autoAim", true)
        cfg:Save()

        -- Load and retrieve:
        cfg:Load()
        local vol = cfg:Get("volume", 50)   -- 50 is the default

        -- Bulk-save from component handles:
        cfg:SaveFromHandles({
            volume  = sliderHandle,
            autoAim = toggleHandle,
        })
        cfg:LoadToHandles({
            volume  = sliderHandle,
            autoAim = toggleHandle,
        })
--]]

-- ─── Executor capability detection ───────────────────────────────────────────
local ENV = {
    write  = type(writefile)  == "function" and writefile  or nil,
    read   = type(readfile)   == "function" and readfile   or nil,
    exists = type(isfile)     == "function" and isfile     or nil,
    mkdir  = type(makefolder) == "function" and makefolder or nil,
}

local function canWrite()  return ENV.write  ~= nil end
local function canRead()   return ENV.read   ~= nil end
local function canExists() return ENV.exists ~= nil end
local function canMkdir()  return ENV.mkdir  ~= nil end

-- ─── JSON encoder / decoder ───────────────────────────────────────────────────
-- Roblox exposes HttpService.JSONEncode / JSONDecode even in executors.
local HttpService = game:GetService("HttpService")

local function jsonEncode(t)
    local ok, result = pcall(function() return HttpService:JSONEncode(t) end)
    return ok and result or "{}"
end

local function jsonDecode(s)
    local ok, result = pcall(function() return HttpService:JSONDecode(s) end)
    return ok and result or {}
end

-- ─── Config class ─────────────────────────────────────────────────────────────
local Config = {}
Config.__index = Config

--[[
    Config.new(filePath [, defaults])
        filePath — relative path on disk, e.g. "nexus/settings.json"
        defaults — optional table of default values loaded on construction
    Returns a Config instance.
--]]
function Config.new(filePath, defaults)
    local self       = setmetatable({}, Config)
    self._path       = filePath or "nexus_config.json"
    self._data       = {}          -- in-memory key-value store
    self._dirty      = false       -- true when unsaved changes exist
    self._autoSave   = false       -- set to true to save on every :Set()

    -- Apply defaults first, then try to load from disk
    if defaults then
        for k, v in pairs(defaults) do
            self._data[k] = v
        end
    end
    self:Load()   -- silently no-ops if file doesn't exist yet

    return self
end

-- ─── Core get / set ───────────────────────────────────────────────────────────
--[[
    cfg:Set(key, value)
        Store a value.  Triggers auto-save if enabled.
--]]
function Config:Set(key, value)
    self._data[key] = value
    self._dirty     = true
    if self._autoSave then
        self:Save()
    end
end

--[[
    cfg:Get(key [, default])
        Retrieve a value.  Returns `default` (or nil) if the key isn't stored.
--]]
function Config:Get(key, default)
    local v = self._data[key]
    if v == nil then return default end
    return v
end

--[[
    cfg:Delete(key)
        Remove a stored key.
--]]
function Config:Delete(key)
    self._data[key] = nil
    self._dirty     = true
end

--[[
    cfg:Clear()
        Wipe all in-memory data (does NOT delete the file).
--]]
function Config:Clear()
    self._data  = {}
    self._dirty = true
end

-- ─── Persistence ─────────────────────────────────────────────────────────────
--[[
    cfg:Save()
        Serialise _data to JSON and write to _path.
        Creates parent directories automatically.
        Returns true on success, false on failure.
--]]
function Config:Save()
    if not canWrite() then
        warn("[Config] writefile not available — config not saved.")
        return false
    end

    -- Ensure parent folder exists
    local folder = self._path:match("^(.+)/[^/]+$")
    if folder and canMkdir() then
        pcall(function() ENV.mkdir(folder) end)
    end

    local encoded = jsonEncode(self._data)
    local ok = pcall(function() ENV.write(self._path, encoded) end)
    if ok then
        self._dirty = false
    else
        warn("[Config] Failed to write file: " .. self._path)
    end
    return ok
end

--[[
    cfg:Load()
        Read the JSON file from disk and merge into _data.
        Existing in-memory keys NOT present in the file are preserved.
        Returns true on success, false if file missing or parse error.
--]]
function Config:Load()
    if not canRead() then return false end
    if canExists() and not ENV.exists(self._path) then return false end

    local raw
    local ok = pcall(function() raw = ENV.read(self._path) end)
    if not ok or not raw then return false end

    local decoded = jsonDecode(raw)
    for k, v in pairs(decoded) do
        self._data[k] = v
    end
    self._dirty = false
    return true
end

--[[
    cfg:Reload()
        Discard in-memory data and reload entirely from disk.
--]]
function Config:Reload()
    self._data = {}
    return self:Load()
end

-- ─── Auto-save ────────────────────────────────────────────────────────────────
--[[
    cfg:EnableAutoSave(enabled)
        When true, every :Set() immediately flushes to disk.
        Useful for small configs.  Use with care on high-frequency updates.
--]]
function Config:EnableAutoSave(enabled)
    self._autoSave = enabled ~= false
end

--[[
    cfg:StartPeriodicSave(intervalSeconds)
        Launches a background loop that saves every N seconds if dirty.
        Returns a stop function.
--]]
function Config:StartPeriodicSave(intervalSeconds)
    intervalSeconds = intervalSeconds or 30
    local running   = true
    task.spawn(function()
        while running do
            task.wait(intervalSeconds)
            if self._dirty then
                self:Save()
            end
        end
    end)
    return function()
        running = false
    end
end

-- ─── Component-handle integration ─────────────────────────────────────────────
--[[
    cfg:SaveFromHandles(handleMap)
        Reads the current value from each NexusUI component handle and stores it.
        handleMap = { configKey = componentHandle, ... }

    Example:
        cfg:SaveFromHandles({
            volume   = volumeSlider,
            autofire = autofireToggle,
            mode     = modeDropdown,
        })
--]]
function Config:SaveFromHandles(handleMap)
    for key, handle in pairs(handleMap) do
        if handle and type(handle.Get) == "function" then
            self:Set(key, handle:Get())
        end
    end
    self:Save()
end

--[[
    cfg:LoadToHandles(handleMap [, defaults])
        Reads values from config and applies them to component handles via :Set().
        If a key isn't in the config, the handle is left unchanged (or set to
        defaults[key] if provided).
--]]
function Config:LoadToHandles(handleMap, defaults)
    defaults = defaults or {}
    for key, handle in pairs(handleMap) do
        if handle and type(handle.Set) == "function" then
            local val = self:Get(key, defaults[key])
            if val ~= nil then
                pcall(function() handle:Set(val) end)
            end
        end
    end
end

-- ─── Window position persistence ─────────────────────────────────────────────
--[[
    cfg:SaveWindowPosition(windowId, frame)
        Stores the absolute X/Y position of a window frame.
--]]
function Config:SaveWindowPosition(windowId, frame)
    local abs = frame.AbsolutePosition
    self:Set("_win_" .. windowId, { x = abs.X, y = abs.Y })
    self:Save()
end

--[[
    cfg:RestoreWindowPosition(windowId, frame)
        Moves the frame to the stored position (if any).
        Returns true if a saved position was found.
--]]
function Config:RestoreWindowPosition(windowId, frame)
    local saved = self:Get("_win_" .. windowId)
    if saved and saved.x and saved.y then
        frame.Position = UDim2.new(0, saved.x, 0, saved.y)
        return true
    end
    return false
end

-- ─── Debug ────────────────────────────────────────────────────────────────────
function Config:Dump()
    return jsonEncode(self._data)
end

function Config:PrintAll()
    print("[Config] Contents of " .. self._path)
    for k, v in pairs(self._data) do
        print(string.format("  %-24s = %s", tostring(k), tostring(v)))
    end
end

return Config
