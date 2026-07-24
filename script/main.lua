--[[
╔══════════════════════════════════════════════════════════════════════════════╗
║                         NexusUI  ·  main.lua                               ║
║                    Root execution / bootstrap script                        ║
╠══════════════════════════════════════════════════════════════════════════════╣
║  PURPOSE                                                                    ║
║    • Fetches all library modules from GitHub (raw) via loadstring           ║
║    • Initialises the UI library and plugin helpers                          ║
║    • Builds a fully-featured demonstration menu with:                       ║
║        Tab 1 "Main"     — toggles, sliders, status badges                  ║
║        Tab 2 "Combat"   — buttons with callbacks, dropdowns                 ║
║        Tab 3 "Visual"   — colour/appearance controls                        ║
║        Tab 4 "Settings" — config save/load, text inputs, keybind display   ║
║    • Persists settings between sessions via Config module                   ║
║    • Registers a keyboard shortcut (RightShift) to show/hide the menu      ║
╠══════════════════════════════════════════════════════════════════════════════╣
║  GITHUB RAW BASE                                                             ║
║    Set RAW_BASE below to the root of your repository's raw content URL.    ║
╚══════════════════════════════════════════════════════════════════════════════╝
--]]

-- ─── 1. Configuration ─────────────────────────────────────────────────────────
--  Replace with your actual GitHub raw URL.
--  Format: https://raw.githubusercontent.com/USERNAME/REPO/BRANCH/
local RAW_BASE = "https://raw.githubusercontent.com/mikolaq1111/nexusui/main/"

-- Hide/show keybind
local TOGGLE_KEY = Enum.KeyCode.RightShift

-- Config file path (written by the executor)
local CONFIG_PATH = "nexus/nexus_settings.json"

-- ─── 2. Safe HTTP fetch ───────────────────────────────────────────────────────
local function fetchRaw(path)
    local url = RAW_BASE .. path
    local ok, result = pcall(function()
        return game:HttpGet(url, true)
    end)
    if not ok then
        error(("[NexusUI Loader] HTTP fetch failed for: %s\n%s"):format(url, tostring(result)))
    end
    return result
end

local function loadRemote(path)
    local code    = fetchRaw(path)
    local fn, err = loadstring(code)
    if not fn then
        error(("[NexusUI Loader] Compile error in %s:\n%s"):format(path, tostring(err)))
    end
    return fn()
end

-- ─── 3. Bootstrap modules ─────────────────────────────────────────────────────
print("[NexusUI] Loading theme …")
local Theme = loadRemote("ui-library/theme.lua")

print("[NexusUI] Loading components …")
local Components = loadRemote("ui-library/components.lua")

-- ── Patch theme + components into ui-library/init.lua's expected upvalues ──
-- Because loadstring gives each chunk a fresh environment, we pre-load
-- theme and components and inject them so init.lua can find them.
--
-- Strategy: override the init.lua loader so that when it calls
--   require(script.theme) / require(script.components)
-- we return our already-loaded tables.  We do this by wrapping init.lua's
-- code with a fake "script" environment.  The simplest executor-safe approach
-- is to patch the globals table before executing init.lua.
--
-- NOTE: In a real Rojo / Studio project you would use proper ModuleScript
-- children and this patching is unnecessary.

local _savedRequire = require   -- keep original in case it's needed elsewhere

-- Temporary shim that intercepts require(script.theme) / require(script.components)
local function patchedRequire(mod)
    -- ModuleScript children are compared by object identity; we can't do that
    -- here so we fall back to original require for everything else.
    return _savedRequire(mod)
end

-- We load init.lua via a wrapper that already has theme/components in scope
-- instead of relying on require().
local libraryCode = fetchRaw("ui-library/init.lua")
-- Inject dependencies before the chunk runs:
local libraryEnv  = setmetatable({
    -- Override require inside init.lua so "require(script.theme)" returns our table
    require = function(_mod)
        -- We can't match by instance, so return nils and let init.lua's pcall fail,
        -- then the chunk will error and we catch it below.
        return _savedRequire(_mod)
    end,
    script  = game,      -- dummy script reference
    game    = game,
    task    = task,
    print   = print,
    warn    = warn,
    error   = error,
    pairs   = pairs,
    ipairs  = ipairs,
    type    = type,
    math    = math,
    table   = table,
    string  = string,
    pcall   = pcall,
    setmetatable = setmetatable,
    tostring     = tostring,
    Instance     = Instance,
    UDim         = UDim,
    UDim2        = UDim2,
    Vector2      = Vector2,
    Color3       = Color3,
    Enum         = Enum,
    ColorSequence = ColorSequence,
    ColorSequenceKeypoint = ColorSequenceKeypoint,
    TweenInfo    = TweenInfo,
    gethui       = (type(gethui)=="function") and gethui or nil,
}, { __index = _G })

-- Because init.lua calls require(script.theme) inside a pcall and falls back
-- to an error if that fails, we supply Theme/Components as upvalues by
-- manually constructing the Library class here instead of executing init.lua.
-- This keeps the bootstrap simple and avoids complex environment tricks.

print("[NexusUI] Constructing Library …")

-- ── Inline Library construction (mirrors ui-library/init.lua logic) ──────────
local function getSecureParent()
    if type(gethui) == "function" then return gethui() end
    local ok, cg = pcall(function() return game:GetService("CoreGui") end)
    if ok and cg then return cg end
    return game.Players.LocalPlayer.PlayerGui
end

local Library = {}
Library.__index = Library

function Library.new(customTheme)
    local self     = setmetatable({}, Library)
    self.Theme     = setmetatable(customTheme or {}, { __index = Theme })
    self._plugins  = nil
    self._windows  = {}

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name             = "NexusUI_" .. tostring(math.random(1000, 9999))
    screenGui.ResetOnSpawn     = false
    screenGui.ZIndexBehavior   = Enum.ZIndexBehavior.Sibling
    screenGui.DisplayOrder     = 999
    screenGui.IgnoreGuiInset   = true
    screenGui.Parent           = getSecureParent()
    self._screenGui            = screenGui

    return self
end

function Library:SetPlugins(plugins) self._plugins = plugins end

local function proxy(name)
    Library[name] = function(self, ...)
        return Components[name](...)
    end
end

-- Attach component constructors that pass theme + plugins automatically
for _, name in ipairs({
    "CreateWindow","CreateButton","CreateToggle","CreateSlider",
    "CreateTextBox","CreateDropdown","CreateLabel","CreateSeparator","CreateBadge"
}) do
    Library[name] = function(self, ...)
        local args = {...}
        -- CreateWindow takes (options) and injects screenGui as parent
        if name == "CreateWindow" then
            local handle = Components[name](self._screenGui, args[1], self.Theme, self._plugins)
            table.insert(self._windows, handle)
            return handle
        end
        -- All others take (parent, options)
        return Components[name](args[1], args[2], self.Theme, self._plugins)
    end
end

function Library:SetVisible(v) self._screenGui.Enabled = v end
function Library:IsVisible()  return self._screenGui.Enabled end
function Library:DestroyAll()
    for _, w in ipairs(self._windows) do pcall(function() w:Destroy() end) end
    self._windows = {}
    if self._screenGui then self._screenGui:Destroy() end
end

-- ─── 4. Load plugin-libray ────────────────────────────────────────────────────
print("[NexusUI] Loading plugins …")
local Tween  = loadRemote("plugin-libray/tween.lua")
local Drag   = loadRemote("plugin-libray/drag.lua")
local Config = loadRemote("plugin-libray/config.lua")

local Plugins = {
    Tween  = Tween,
    Drag   = Drag,
    Config = Config,
    newConfig = function(path, defaults) return Config.new(path, defaults) end,
    play      = function(...) return Tween.play(...) end,
}

-- ─── 5. Initialise Library instance ──────────────────────────────────────────
local ui = Library.new()
ui:SetPlugins(Plugins)

-- ─── 5b. Device helpers ───────────────────────────────────────────────────────
local UIS2     = game:GetService("UserInputService")
local isMobile = UIS2.TouchEnabled and not UIS2.MouseEnabled
local vp       = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize
                 or Vector2.new(800, 600)

-- ─── 6. Persistent config ─────────────────────────────────────────────────────
local cfg = Plugins.newConfig(CONFIG_PATH, {
    aimbot       = false,
    aimSmooth    = 5,
    fov          = 120,
    espPlayers   = true,
    espBoxes     = true,
    espDistance  = 500,
    watermark    = true,
    fpsUnlock    = false,
    theme        = "Violet",
    username     = "",
    windowX      = nil,
    windowY      = nil,
})

-- ─── 7. Build the Window ──────────────────────────────────────────────────────
-- Window width: fill 96% on phone, cap at 420 on tablet/PC
local winW = math.min(math.floor(vp.X * 0.96), 420)
local winH = math.min(math.floor(vp.Y * 0.88), 520)

local win = ui:CreateWindow({
    Title       = "NexusUI  v1.0",
    Size        = UDim2.new(0, winW, 0, winH),
    Position    = UDim2.new(0.5, -winW/2, 0.5, -winH/2),
    CanClose    = true,
    CanMinimise = true,
    Tabs        = { "Main", "Combat", "Visual", "Settings" },
})

-- Restore saved window position (if any)
cfg:RestoreWindowPosition("main", win.Instance)

-- Save position whenever it changes (hook into drag end)
Drag.makeDraggable(win.Instance, win.Instance:FindFirstChild("TitleBar"), {
    OnEnd = function()
        cfg:SaveWindowPosition("main", win.Instance)
    end,
})

-- ─── 7b. Mobile toggle button ────────────────────────────────────────────────
-- The button lives in its OWN dedicated ScreenGui that is NEVER disabled.
-- Previously it was inside ui._screenGui, so calling ui:SetVisible(false)
-- hid the button itself — making it impossible to reopen the menu.
--
-- Fix: separate ScreenGui for the button + track open state with a local bool
-- instead of reading ui:IsVisible(). We only toggle win.Instance visibility,
-- the main ScreenGui stays Enabled = true at all times.
local guiOpen = true   -- shared state used by both mobile btn and desktop keybind

if isMobile then
    -- Dedicated always-on ScreenGui so the button is NEVER hidden
    local btnGui = Instance.new("ScreenGui")
    btnGui.Name            = "NexusMobileToggleGui"
    btnGui.ResetOnSpawn    = false
    btnGui.DisplayOrder    = 1000          -- above the main UI
    btnGui.IgnoreGuiInset  = true
    btnGui.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
    -- Use same secure parent as the main library
    local function getSecureParent2()
        if type(gethui) == "function" then return gethui() end
        local ok2, cg2 = pcall(function() return game:GetService("CoreGui") end)
        if ok2 and cg2 then return cg2 end
        return game.Players.LocalPlayer.PlayerGui
    end
    btnGui.Parent = getSecureParent2()

    local mobileBtn = Instance.new("TextButton")
    mobileBtn.Name             = "NexusMobileToggle"
    mobileBtn.Size             = UDim2.new(0, 56, 0, 56)
    mobileBtn.Position         = UDim2.new(1, -68, 1, -80)   -- bottom-right
    mobileBtn.AnchorPoint      = Vector2.new(0, 0)
    mobileBtn.BackgroundColor3 = Theme.Accent
    mobileBtn.BorderSizePixel  = 0
    mobileBtn.Font             = Theme.FontBody
    mobileBtn.TextSize         = 24
    mobileBtn.Text             = "☰"
    mobileBtn.TextColor3       = Theme.TextPrimary
    mobileBtn.AutoButtonColor  = false
    mobileBtn.ZIndex           = 1
    mobileBtn.Parent           = btnGui
    local mbCorner = Instance.new("UICorner")
    mbCorner.CornerRadius = UDim.new(1, 0)
    mbCorner.Parent       = mobileBtn
    local mbStroke = Instance.new("UIStroke")
    mbStroke.Color     = Theme.AccentLight
    mbStroke.Thickness = 2
    mbStroke.Parent    = mobileBtn

    mobileBtn.MouseButton1Click:Connect(function()
        guiOpen = not guiOpen
        if guiOpen then
            -- Show: make win.Instance visible then spring it open
            win.Instance.Visible = true
            Tween.openWindow(win.Instance, UDim2.new(0, winW, 0, winH))
            mobileBtn.Text = "✕"
        else
            -- Hide: shrink then set invisible (Tween.closeWindow does this)
            Tween.closeWindow(win.Instance)
            mobileBtn.Text = "☰"
        end
    end)
end

-- ─── 8. Tab: Main ────────────────────────────────────────────────────────────
local tabMain = win:GetTab("Main")

ui:CreateLabel(tabMain, { Text = "⚡  CORE FEATURES", Color = Theme.TextAccent, Size = 12 })
ui:CreateSeparator(tabMain)

-- Watermark toggle
local toggleWatermark = ui:CreateToggle(tabMain, {
    Label    = "Watermark",
    Default  = cfg:Get("watermark", true),
    OnChange = function(v)
        cfg:Set("watermark", v)
        -- (In a real script, show/hide a watermark label here)
        print("[Main] Watermark:", v)
    end,
})

-- FPS Unlocker toggle
local toggleFPS = ui:CreateToggle(tabMain, {
    Label    = "FPS Unlocker",
    Default  = cfg:Get("fpsUnlock", false),
    OnChange = function(v)
        cfg:Set("fpsUnlock", v)
        if v then
            -- Unlock frame-rate cap
            local ok = pcall(function()
                setfpscap(0)
            end)
            if not ok then warn("[FPS] setfpscap not available") end
        end
    end,
})

ui:CreateSeparator(tabMain)
ui:CreateLabel(tabMain, { Text = "📊  SESSION INFO" })

-- Status badge row (inline demo)
local badgeRow = Instance.new("Frame")
badgeRow.Size                = UDim2.new(1, 0, 0, 28)
badgeRow.BackgroundTransparency = 1
badgeRow.ZIndex              = 12
badgeRow.Parent              = tabMain
local badgeLayout = Instance.new("UIListLayout")
badgeLayout.FillDirection    = Enum.FillDirection.Horizontal
badgeLayout.Padding          = UDim.new(0, 6)
badgeLayout.Parent           = badgeRow

ui:CreateBadge(badgeRow, { Text = "ACTIVE",  Color = Theme.Success })
ui:CreateBadge(badgeRow, { Text = "v1.0",    Color = Theme.Info    })
ui:CreateBadge(badgeRow, { Text = "NEXUSUI", Color = Theme.Accent  })

-- Notification test button
ui:CreateButton(tabMain, {
    Text    = "Send Test Notification",
    Icon    = "🔔",
    OnClick = function()
        print("[NexusUI] Notification triggered! (hook your notify() here)")
        -- Example: game:GetService("StarterGui"):SetCore("SendNotification", {...})
        local ok = pcall(function()
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title    = "NexusUI",
                Text     = "Notification system working!",
                Duration = 3,
            })
        end)
        if not ok then print("[Notify] CoreGui notify unavailable in executor") end
    end,
})

-- ─── 9. Tab: Combat ──────────────────────────────────────────────────────────
local tabCombat = win:GetTab("Combat")

ui:CreateLabel(tabCombat, { Text = "🎯  AIMBOT", Color = Theme.TextAccent, Size = 12 })
ui:CreateSeparator(tabCombat)

local toggleAimbot = ui:CreateToggle(tabCombat, {
    Label    = "Aimbot Enabled",
    Default  = cfg:Get("aimbot", false),
    OnChange = function(v)
        cfg:Set("aimbot", v)
        print("[Combat] Aimbot:", v)
    end,
})

local sliderSmooth = ui:CreateSlider(tabCombat, {
    Label    = "Aim Smoothness",
    Min      = 1,
    Max      = 20,
    Default  = cfg:Get("aimSmooth", 5),
    OnChange = function(v)
        cfg:Set("aimSmooth", v)
    end,
})

local sliderFov = ui:CreateSlider(tabCombat, {
    Label    = "Field of View",
    Min      = 30,
    Max      = 360,
    Default  = cfg:Get("fov", 120),
    Suffix   = "°",
    OnChange = function(v)
        cfg:Set("fov", v)
    end,
})

local ddTarget = ui:CreateDropdown(tabCombat, {
    Label    = "Target Priority",
    Items    = { "Nearest", "Lowest HP", "Highest Threat", "Crosshair" },
    Default  = "Nearest",
    OnSelect = function(item)
        print("[Combat] Target Priority:", item)
    end,
})

ui:CreateSeparator(tabCombat)

ui:CreateButton(tabCombat, {
    Text    = "Reset Combat Settings",
    Icon    = "↺",
    Primary = false,
    OnClick = function()
        toggleAimbot:Set(false)
        sliderSmooth:Set(5)
        sliderFov:Set(120)
        ddTarget:Set("Nearest")
        cfg:Set("aimbot",    false)
        cfg:Set("aimSmooth", 5)
        cfg:Set("fov",       120)
        print("[Combat] Settings reset to defaults.")
    end,
})

-- ─── 10. Tab: Visual ──────────────────────────────────────────────────────────
local tabVisual = win:GetTab("Visual")

ui:CreateLabel(tabVisual, { Text = "👁  ESP", Color = Theme.TextAccent, Size = 12 })
ui:CreateSeparator(tabVisual)

local toggleESP = ui:CreateToggle(tabVisual, {
    Label    = "Player ESP",
    Default  = cfg:Get("espPlayers", true),
    OnChange = function(v) cfg:Set("espPlayers", v) end,
})

local toggleBoxes = ui:CreateToggle(tabVisual, {
    Label    = "ESP Boxes",
    Default  = cfg:Get("espBoxes", true),
    OnChange = function(v) cfg:Set("espBoxes", v) end,
})

local sliderEspDist = ui:CreateSlider(tabVisual, {
    Label    = "ESP Distance",
    Min      = 50,
    Max      = 1000,
    Default  = cfg:Get("espDistance", 500),
    Suffix   = "m",
    OnChange = function(v) cfg:Set("espDistance", v) end,
})

ui:CreateSeparator(tabVisual)
ui:CreateLabel(tabVisual, { Text = "🎨  APPEARANCE" })

local ddTheme = ui:CreateDropdown(tabVisual, {
    Label    = "UI Theme",
    Items    = { "Violet", "Crimson", "Ocean", "Emerald", "Monochrome" },
    Default  = cfg:Get("theme", "Violet"),
    OnSelect = function(item)
        cfg:Set("theme", item)
        print("[Visual] Theme changed to:", item)
        -- (A full implementation would rebuild the ScreenGui with new colours)
    end,
})

-- ─── 11. Tab: Settings ────────────────────────────────────────────────────────
local tabSettings = win:GetTab("Settings")

ui:CreateLabel(tabSettings, { Text = "⚙  GENERAL", Color = Theme.TextAccent, Size = 12 })
ui:CreateSeparator(tabSettings)

local txtUser = ui:CreateTextBox(tabSettings, {
    Label       = "Display Name Override",
    Placeholder = "Leave blank to use Roblox name",
    Default     = cfg:Get("username", ""),
    OnChange    = function(t) cfg:Set("username", t) end,
})

ui:CreateSeparator(tabSettings)
-- Only show keybind hint on desktop (no keyboard on touch devices)
if not isMobile then
    ui:CreateLabel(tabSettings, {
        Text = "⌨  Keybind: " .. tostring(TOGGLE_KEY.Name) .. " to show/hide menu",
    })
else
    ui:CreateLabel(tabSettings, {
        Text = "📱  Tap the ☰ button (bottom-right) to show/hide menu",
    })
end

ui:CreateSeparator(tabSettings)

-- Config Save / Load buttons
ui:CreateButton(tabSettings, {
    Text    = "💾  Save Config",
    OnClick = function()
        -- Bulk-save all component states
        cfg:SaveFromHandles({
            watermark   = toggleWatermark,
            fpsUnlock   = toggleFPS,
            aimbot      = toggleAimbot,
            aimSmooth   = sliderSmooth,
            fov         = sliderFov,
            espPlayers  = toggleESP,
            espBoxes    = toggleBoxes,
            espDistance = sliderEspDist,
            theme       = ddTheme,
            username    = txtUser,
        })
        print("[Config] Saved to:", CONFIG_PATH)
        -- Visual feedback: briefly flash border accent
        local rootStroke = win.Instance:FindFirstChildOfClass("UIStroke")
        if rootStroke then
            Tween.play(rootStroke, "Fast", { Color = Theme.Success })
            task.delay(0.6, function()
                Tween.play(rootStroke, "Normal", { Color = Theme.Border })
            end)
        end
    end,
})

ui:CreateButton(tabSettings, {
    Text    = "📂  Load Config",
    Primary = false,
    OnClick = function()
        cfg:Load()
        cfg:LoadToHandles({
            watermark   = toggleWatermark,
            fpsUnlock   = toggleFPS,
            aimbot      = toggleAimbot,
            aimSmooth   = sliderSmooth,
            fov         = sliderFov,
            espPlayers  = toggleESP,
            espBoxes    = toggleBoxes,
            espDistance = sliderEspDist,
            username    = txtUser,
        })
        ddTheme:Set(cfg:Get("theme", "Violet"))
        print("[Config] Loaded from:", CONFIG_PATH)
    end,
})

ui:CreateButton(tabSettings, {
    Text    = "🗑  Reset All Defaults",
    Danger  = true,
    OnClick = function()
        cfg:Clear()
        cfg:Save()
        -- Reload default states
        toggleWatermark:Set(true)
        toggleFPS:Set(false)
        toggleAimbot:Set(false)
        sliderSmooth:Set(5)
        sliderFov:Set(120)
        toggleESP:Set(true)
        toggleBoxes:Set(true)
        sliderEspDist:Set(500)
        ddTheme:Set("Violet")
        txtUser:Set("")
        print("[Config] All settings reset.")
    end,
})

-- ─── 12. Keybind: toggle visibility (desktop only) ──────────────────────────
-- Same fix as the mobile button: we track state with guiOpen and only animate
-- win.Instance.  Never disable the whole ScreenGui.
if not isMobile then
    local UIS = game:GetService("UserInputService")
    UIS.InputBegan:Connect(function(inp, gameProcessed)
        if gameProcessed then return end
        if inp.KeyCode == TOGGLE_KEY then
            guiOpen = not guiOpen
            if guiOpen then
                win.Instance.Visible = true
                Tween.openWindow(win.Instance, UDim2.new(0, winW, 0, winH))
            else
                Tween.closeWindow(win.Instance)
            end
        end
    end)
end

-- ─── 13. Periodic config auto-save ───────────────────────────────────────────
-- Save dirty config every 60 seconds so data isn't lost if the game crashes.
local stopAutoSave = cfg:StartPeriodicSave(60)

-- ─── 14. Cleanup on character removal ────────────────────────────────────────
game.Players.LocalPlayer.CharacterRemoving:Connect(function()
    cfg:Save()   -- flush before respawn wipes everything
end)

-- ─── 15. Done ─────────────────────────────────────────────────────────────────
print("╔══════════════════════════════╗")
print("║  NexusUI loaded successfully ║")
print("║  Press", TOGGLE_KEY.Name, "to toggle    ║")
print("╚══════════════════════════════╝")
