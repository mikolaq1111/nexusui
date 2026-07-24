--[[
    init.lua  (ui-library)
    ======================
    Public entry-point / façade for NexusUI.

    When loaded via loadstring from GitHub the caller receives a "Library"
    object with a single constructor:

        local NexusUI = loadstring(game:HttpGet(RAW_URL))()
        local win     = NexusUI:CreateWindow({ Title="My Menu", Tabs={"Main"} })
        local content = win:GetContent()
        NexusUI:CreateButton(content, { Text="Hello", OnClick = function() print("hi") end })

    The library auto-selects the safest GUI parent:
        1. gethui()                  — executor hook (most secure, bypasses coregui filter)
        2. game:GetService("CoreGui")— fallback for regular plugins / localscripts
        3. game.Players.LocalPlayer.PlayerGui — last resort (visible to other scripts)

    All components follow the pattern:
        handle = NexusUI:CreateXxx(parentFrame, optionsTable)
        handle.Instance  → the root GuiObject
        handle:Set(...)  → update state
        handle:Get(...)  → read state
        handle:Destroy() → remove cleanly
--]]

-- ─── Dependency loading ───────────────────────────────────────────────────────
-- When loaded as a Roblox ModuleScript tree:
--   local Theme      = require(script.theme)
--   local Components = require(script.components)
-- When loaded via loadstring (flat GitHub approach) the caller must pre-load
-- theme and components themselves, OR we use an inline loader pattern below.
-- For simplicity this init.lua is written to work BOTH ways.

local Theme, Components

local ok = pcall(function()
    -- ModuleScript path (inside Roblox Studio or Rojo)
    Theme      = require(script.theme)
    Components = require(script.components)
end)

if not ok then
    -- loadstring / executor path: dependencies must be provided as upvalues
    -- or the caller inlines them.  The script/main.lua handles this.
    error("[NexusUI] Could not auto-require theme/components. "
        .."Use the main.lua loader which loadstring()s all modules in order.")
end

-- ─── Secure GUI parent ────────────────────────────────────────────────────────
local function getSecureParent()
    -- Priority 1: executor hook (bypasses Roblox's CoreGui content filter)
    if type(gethui) == "function" then
        return gethui()
    end
    -- Priority 2: CoreGui (available to LocalScripts and plugins)
    local cg_ok, cg = pcall(function()
        return game:GetService("CoreGui")
    end)
    if cg_ok and cg then return cg end
    -- Priority 3: PlayerGui (always available but least secure)
    return game.Players.LocalPlayer.PlayerGui
end

-- ─── Library object ───────────────────────────────────────────────────────────
local Library = {}
Library.__index = Library

--[[
    Library.new(customTheme)
    Creates a new Library instance.  Pass a partial or full theme table to
    override individual design tokens without replacing everything.
--]]
function Library.new(customTheme)
    local self = setmetatable({}, Library)

    -- Merge custom tokens on top of the default theme
    self.Theme = setmetatable(customTheme or {}, { __index = Theme })

    -- Secure host container (ScreenGui)
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name                  = "NexusUI_" .. tostring(math.random(1000,9999))
    screenGui.ResetOnSpawn          = false
    screenGui.ZIndexBehavior        = Enum.ZIndexBehavior.Sibling
    screenGui.DisplayOrder          = 999          -- render above game HUD
    screenGui.IgnoreGuiInset        = true         -- fill the whole screen
    screenGui.Parent                = getSecureParent()
    self._screenGui                 = screenGui

    -- Plugins reference (set by main.lua after loading plugin-libray)
    self._plugins = nil

    -- Track all open windows for batch destroy
    self._windows = {}

    return self
end

--[[
    library:SetPlugins(pluginsTable)
    Called by main.lua after the plugin-libray is loaded, so components can
    use tween helpers, drag, and config modules.
--]]
function Library:SetPlugins(plugins)
    self._plugins = plugins
end

-- ── Component proxies ─────────────────────────────────────────────────────────
-- Each method delegates to the matching Components.CreateXxx function,
-- automatically injecting the shared theme and plugins.

function Library:CreateWindow(options)
    local handle = Components.CreateWindow(
        self._screenGui, options, self.Theme, self._plugins
    )
    table.insert(self._windows, handle)
    return handle
end

function Library:CreateButton(parent, options)
    return Components.CreateButton(parent, options, self.Theme, self._plugins)
end

function Library:CreateToggle(parent, options)
    return Components.CreateToggle(parent, options, self.Theme, self._plugins)
end

function Library:CreateSlider(parent, options)
    return Components.CreateSlider(parent, options, self.Theme, self._plugins)
end

function Library:CreateTextBox(parent, options)
    return Components.CreateTextBox(parent, options, self.Theme, self._plugins)
end

function Library:CreateDropdown(parent, options)
    return Components.CreateDropdown(parent, options, self.Theme, self._plugins)
end

function Library:CreateLabel(parent, options)
    return Components.CreateLabel(parent, options, self.Theme, self._plugins)
end

function Library:CreateSeparator(parent, options)
    return Components.CreateSeparator(parent, options, self.Theme, self._plugins)
end

function Library:CreateBadge(parent, options)
    return Components.CreateBadge(parent, options, self.Theme, self._plugins)
end

-- ── Utility ──────────────────────────────────────────────────────────────────

--- Close every window and destroy the ScreenGui entirely.
function Library:DestroyAll()
    for _, win in ipairs(self._windows) do
        pcall(function() win:Destroy() end)
    end
    self._windows = {}
    if self._screenGui then self._screenGui:Destroy() end
end

--- Toggle visibility of the entire UI (useful for a show/hide keybind).
function Library:SetVisible(visible)
    self._screenGui.Enabled = visible
end

function Library:IsVisible()
    return self._screenGui.Enabled
end

-- ─── Module return ───────────────────────────────────────────────────────────
-- When used as a ModuleScript: require() returns Library itself.
-- When used via loadstring: the executed chunk must call Library.new()
-- (main.lua does this).
return Library
