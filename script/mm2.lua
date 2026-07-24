--[[
╔══════════════════════════════════════════════════════════════════════════════╗
║              NexusUI  ·  Murder Mystery 2  ·  Script                       ║
║                      game:  142823291  (MM2)                                ║
╠══════════════════════════════════════════════════════════════════════════════╣
║  TABS                                                                       ║
║    ESP      — player boxes, role tags, distance, line-of-sight colour       ║
║    Aimbot   — lock-on for Murderer knife, smoothness, FOV circle            ║
║    Farm     — coin auto-collect, auto-open safes, speed hack                ║
║    Player   — fly, noclip, walkspeed, jump power, infinite jump             ║
║    Misc     — chat spy, server info, rejoin, credits                        ║
║    Settings — save/load config, toggle key, credits                         ║
╠══════════════════════════════════════════════════════════════════════════════╣
║  LOAD ONE-LINER (paste in executor):                                        ║
║    loadstring(game:HttpGet(                                                 ║
║      "https://raw.githubusercontent.com/mikolaq1111/nexusui/main/script/mm2.lua" ║
║    ))()                                                                     ║
╚══════════════════════════════════════════════════════════════════════════════╝
--]]

-- ─── 1. Safety check ─────────────────────────────────────────────────────────
if game.PlaceId ~= 142823291 then
    warn("[MM2] Wrong game! PlaceId expected: 142823291, got: " .. game.PlaceId)
    -- Remove the line above if you want to run on any place during testing.
end

-- ─── 2. Raw base URL ─────────────────────────────────────────────────────────
local RAW_BASE = "https://raw.githubusercontent.com/mikolaq1111/nexusui/main/"

-- ─── 3. Module loader ────────────────────────────────────────────────────────
local function loadRemote(path)
    local ok, result = pcall(function()
        return game:HttpGet(RAW_BASE .. path, true)
    end)
    if not ok then error("[MM2] HTTP fail: " .. path .. "\n" .. tostring(result)) end
    local fn, err = loadstring(result)
    if not fn then error("[MM2] Compile error: " .. path .. "\n" .. tostring(err)) end
    return fn()
end

print("[MM2] Loading NexusUI modules …")
local Theme      = loadRemote("ui-library/theme.lua")
local Components = loadRemote("ui-library/components.lua")
local Tween      = loadRemote("plugin-libray/tween.lua")
local Drag       = loadRemote("plugin-libray/drag.lua")
local Config     = loadRemote("plugin-libray/config.lua")

-- ─── 4. Build Library inline (same as main.lua bootstrap) ────────────────────
local function getSecureParent()
    if type(gethui) == "function" then return gethui() end
    local ok, cg = pcall(function() return game:GetService("CoreGui") end)
    if ok and cg then return cg end
    return game.Players.LocalPlayer.PlayerGui
end

local Library = {}
Library.__index = Library
function Library.new(customTheme)
    local self = setmetatable({}, Library)
    self.Theme      = setmetatable(customTheme or {}, { __index = Theme })
    self._plugins   = nil
    self._windows   = {}
    local sg = Instance.new("ScreenGui")
    sg.Name             = "NexusMM2_" .. tostring(math.random(1000,9999))
    sg.ResetOnSpawn     = false
    sg.ZIndexBehavior   = Enum.ZIndexBehavior.Sibling
    sg.DisplayOrder     = 999
    sg.IgnoreGuiInset   = true
    sg.Parent           = getSecureParent()
    self._screenGui     = sg
    return self
end
function Library:SetPlugins(p) self._plugins = p end
for _, name in ipairs({
    "CreateWindow","CreateButton","CreateToggle","CreateSlider",
    "CreateTextBox","CreateDropdown","CreateLabel","CreateSeparator","CreateBadge"
}) do
    Library[name] = function(self, ...)
        local args = {...}
        if name == "CreateWindow" then
            local h = Components[name](self._screenGui, args[1], self.Theme, self._plugins)
            table.insert(self._windows, h)
            return h
        end
        return Components[name](args[1], args[2], self.Theme, self._plugins)
    end
end

-- ─── 5. Services & locals ────────────────────────────────────────────────────
local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS        = game:GetService("UserInputService")
local TweenSvc   = game:GetService("TweenService")
local lp         = Players.LocalPlayer
local cam        = workspace.CurrentCamera

local Plugins = {
    Tween  = Tween,  Drag = Drag,  Config = Config,
    newConfig = function(p,d) return Config.new(p,d) end,
    play      = function(...) return Tween.play(...) end,
}

-- ─── 6. Device detection ─────────────────────────────────────────────────────
local isMobile = UIS.TouchEnabled and not UIS.MouseEnabled
local vp       = cam and cam.ViewportSize or Vector2.new(800,600)
local winW     = math.min(math.floor(vp.X * 0.96), 430)
local winH     = math.min(math.floor(vp.Y * 0.88), 530)

-- ─── 7. Persistent config ────────────────────────────────────────────────────
local cfg = Plugins.newConfig("nexus/mm2_settings.json", {
    -- ESP
    espEnabled   = true,
    espBoxes     = true,
    espNames     = true,
    espDistance  = 500,
    espLines     = false,
    -- Aimbot
    aimbotOn     = false,
    aimbotSmooth = 6,
    aimbotFov    = 90,
    -- Farm
    coinFarm     = false,
    autoSafe     = false,
    -- Player
    walkSpeed    = 16,
    jumpPower    = 50,
    noclip       = false,
    fly          = false,
    -- Misc
    chatSpy      = false,
})

-- ─── 8. UI ───────────────────────────────────────────────────────────────────
local ui = Library.new()
ui:SetPlugins(Plugins)

local guiOpen = true

local win = ui:CreateWindow({
    Title       = "NexusUI  ·  MM2",
    Size        = UDim2.new(0, winW, 0, winH),
    Position    = UDim2.new(0.5, -winW/2, 0.5, -winH/2),
    CanClose    = true,
    CanMinimise = true,
    Tabs        = { "ESP", "Aimbot", "Farm", "Player", "Misc", "Settings" },
})
cfg:RestoreWindowPosition("mm2win", win.Instance)
Drag.makeDraggable(win.Instance, win.Instance:FindFirstChild("TitleBar"), {
    OnEnd = function() cfg:SaveWindowPosition("mm2win", win.Instance) end,
})

-- Mobile floating toggle button (own ScreenGui so it never hides)
if isMobile then
    local btnGui = Instance.new("ScreenGui")
    btnGui.Name           = "NexusMM2Toggle"
    btnGui.ResetOnSpawn   = false
    btnGui.DisplayOrder   = 1000
    btnGui.IgnoreGuiInset = true
    btnGui.Parent         = getSecureParent()
    local mb = Instance.new("TextButton")
    mb.Size             = UDim2.new(0,56,0,56)
    mb.Position         = UDim2.new(1,-68,1,-80)
    mb.BackgroundColor3 = Theme.Accent
    mb.BorderSizePixel  = 0
    mb.Font             = Theme.FontBody
    mb.TextSize         = 24
    mb.Text             = "☰"
    mb.TextColor3       = Theme.TextPrimary
    mb.AutoButtonColor  = false
    mb.ZIndex           = 1
    mb.Parent           = btnGui
    local c = Instance.new("UICorner") c.CornerRadius=UDim.new(1,0) c.Parent=mb
    mb.MouseButton1Click:Connect(function()
        guiOpen = not guiOpen
        if guiOpen then
            win.Instance.Visible = true
            Tween.openWindow(win.Instance, UDim2.new(0,winW,0,winH))
            mb.Text = "✕"
        else
            Tween.closeWindow(win.Instance)
            mb.Text = "☰"
        end
    end)
end

-- ─────────────────────────────────────────────────────────────────────────────
-- ─── TAB: ESP ────────────────────────────────────────────────────────────────
-- ─────────────────────────────────────────────────────────────────────────────
local tESP = win:GetTab("ESP")

ui:CreateLabel(tESP, { Text = "👁  PLAYER ESP", Color = Theme.TextAccent, Size = 12 })
ui:CreateSeparator(tESP)

-- Role colours used for ESP highlights
local ROLE_COLORS = {
    Murderer  = Color3.fromRGB(255,  60,  60),
    Sheriff   = Color3.fromRGB( 60, 160, 255),
    Innocent  = Color3.fromRGB( 60, 230,  90),
    Unknown   = Color3.fromRGB(200, 200, 200),
}

-- ESP state
local espEnabled  = cfg:Get("espEnabled",  true)
local espBoxes    = cfg:Get("espBoxes",    true)
local espNames    = cfg:Get("espNames",    true)
local espLines    = cfg:Get("espLines",    false)
local espDistance = cfg:Get("espDistance", 500)

-- Storage for ESP drawings (one table per player)
local espObjects = {}   -- [player] = { box, nameTag, line, ... }

-- Helper: get player role from MM2's game values
local function getRole(player)
    local char = player.Character
    if not char then return "Unknown" end
    -- MM2 stores role inside a StringValue named "Role" in the character or a
    -- RemoteEvent response.  We read the leaderstats / status value if present.
    local roleVal = char:FindFirstChild("Role")
                 or (player:FindFirstChild("leaderstats") and
                     player.leaderstats:FindFirstChild("Role"))
    if roleVal then return roleVal.Value end
    return "Innocent"   -- safe default
end

-- Helper: world-to-viewport with visibility check
local function worldToScreen(pos)
    local screenPos, onScreen = cam:WorldToViewportPoint(pos)
    return Vector2.new(screenPos.X, screenPos.Y), onScreen, screenPos.Z
end

-- Create a BillboardGui-based ESP tag above a character
local function createESPFor(player)
    if player == lp then return end
    if espObjects[player] then return end

    local holder = {}

    -- ── Name / role tag (BillboardGui) ───────────────────────────────────
    local billboard = Instance.new("BillboardGui")
    billboard.Name          = "NexusESP_" .. player.Name
    billboard.AlwaysOnTop   = true
    billboard.Size          = UDim2.new(0, 120, 0, 40)
    billboard.StudsOffset   = Vector3.new(0, 3, 0)
    billboard.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size                 = UDim2.new(1, 0, 0.6, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Font                 = Theme.FontBody
    nameLabel.TextSize             = 12
    nameLabel.TextColor3           = ROLE_COLORS.Unknown
    nameLabel.TextStrokeTransparency = 0.5
    nameLabel.Text                 = player.Name
    nameLabel.Parent               = billboard

    local roleLabel = Instance.new("TextLabel")
    roleLabel.Size                 = UDim2.new(1, 0, 0.4, 0)
    roleLabel.Position             = UDim2.new(0, 0, 0.6, 0)
    roleLabel.BackgroundTransparency = 1
    roleLabel.Font                 = Theme.FontBody
    roleLabel.TextSize             = 10
    roleLabel.TextColor3           = ROLE_COLORS.Unknown
    roleLabel.TextStrokeTransparency = 0.5
    roleLabel.Text                 = "[?]"
    roleLabel.Parent               = billboard

    holder.billboard  = billboard
    holder.nameLabel  = nameLabel
    holder.roleLabel  = roleLabel
    holder.player     = player

    -- Attach billboard when character spawns
    local function attachBillboard(char)
        local root = char:WaitForChild("HumanoidRootPart", 5)
        if root then billboard.Adornee = root end
    end

    if player.Character then attachBillboard(player.Character) end
    holder.charConn = player.CharacterAdded:Connect(attachBillboard)

    espObjects[player] = holder
end

local function removeESPFor(player)
    local h = espObjects[player]
    if not h then return end
    if h.charConn then h.charConn:Disconnect() end
    if h.billboard and h.billboard.Parent then h.billboard:Destroy() end
    espObjects[player] = nil
end

local function refreshAllESP()
    if not espEnabled then
        for player in pairs(espObjects) do removeESPFor(player) end
        return
    end
    for _, player in ipairs(Players:GetPlayers()) do
        createESPFor(player)
    end
end

-- Update loop: sync colours, visibility, distance culling
RunService.RenderStepped:Connect(function()
    if not espEnabled then return end
    for player, h in pairs(espObjects) do
        local char = player.Character
        if not char then
            h.billboard.Enabled = false
            continue
        end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then
            h.billboard.Enabled = false
            continue
        end
        -- Distance cull
        local myRoot = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
        if myRoot and (root.Position - myRoot.Position).Magnitude > espDistance then
            h.billboard.Enabled = false
            continue
        end
        local role  = getRole(player)
        local col   = ROLE_COLORS[role] or ROLE_COLORS.Unknown
        h.billboard.Enabled       = espNames
        h.nameLabel.TextColor3    = col
        h.roleLabel.TextColor3    = col
        h.roleLabel.Text          = "[" .. role .. "]"
    end
end)

Players.PlayerAdded:Connect(function(p) if espEnabled then createESPFor(p) end end)
Players.PlayerRemoving:Connect(removeESPFor)

-- Build ESP controls
local togESP = ui:CreateToggle(tESP, {
    Label    = "ESP Enabled",
    Default  = espEnabled,
    OnChange = function(v)
        espEnabled = v
        cfg:Set("espEnabled", v)
        refreshAllESP()
    end,
})

local togESPNames = ui:CreateToggle(tESP, {
    Label    = "Show Names / Roles",
    Default  = espNames,
    OnChange = function(v) espNames = v; cfg:Set("espNames", v) end,
})

local slESPDist = ui:CreateSlider(tESP, {
    Label    = "ESP Distance",
    Min      = 50, Max = 1000, Default = espDistance,
    Suffix   = " m",
    OnChange = function(v) espDistance = v; cfg:Set("espDistance", v) end,
})

ui:CreateSeparator(tESP)
ui:CreateLabel(tESP, { Text = "  🔴 Murderer  🔵 Sheriff  🟢 Innocent", Size = 11 })

-- Initialise ESP for players already in server
refreshAllESP()

-- ─────────────────────────────────────────────────────────────────────────────
-- ─── TAB: Aimbot ─────────────────────────────────────────────────────────────
-- ─────────────────────────────────────────────────────────────────────────────
local tAim = win:GetTab("Aimbot")

ui:CreateLabel(tAim, { Text = "🎯  LOCK-ON  (Murderer only)", Color = Theme.TextAccent, Size = 12 })
ui:CreateSeparator(tAim)

local aimbotOn     = cfg:Get("aimbotOn",     false)
local aimbotSmooth = cfg:Get("aimbotSmooth", 6)
local aimbotFov    = cfg:Get("aimbotFov",    90)
local aimbotTarget = nil

-- FOV circle drawn on the screen
local fovCircle = Drawing and Drawing.new("Circle") or nil
if fovCircle then
    fovCircle.Visible   = false
    fovCircle.Radius    = aimbotFov
    fovCircle.Color     = Color3.fromRGB(255, 80, 80)
    fovCircle.Thickness = 1
    fovCircle.Filled    = false
end

local function isMurderer(player)
    return getRole(player) == "Murderer"
end

local function nearestMurderer()
    local best, bestDist = nil, math.huge
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= lp and isMurderer(p) and p.Character then
            local root = p.Character:FindFirstChild("HumanoidRootPart")
            if root then
                local screenPos, onScreen = worldToScreen(root.Position)
                if onScreen then
                    local center = Vector2.new(vp.X/2, vp.Y/2)
                    local dist   = (screenPos - center).Magnitude
                    if dist < aimbotFov and dist < bestDist then
                        best, bestDist = p, dist
                    end
                end
            end
        end
    end
    return best
end

-- Aimbot render loop
RunService.RenderStepped:Connect(function()
    -- Update FOV circle position
    if fovCircle then
        fovCircle.Position = Vector2.new(vp.X/2, vp.Y/2)
        fovCircle.Radius   = aimbotFov
        fovCircle.Visible  = aimbotOn
    end
    if not aimbotOn then return end

    local target = nearestMurderer()
    aimbotTarget = target
    if not target or not target.Character then return end
    local head = target.Character:FindFirstChild("Head")
    if not head then return end

    -- Smooth camera look-at
    local goalCF = CFrame.lookAt(cam.CFrame.Position, head.Position)
    cam.CFrame   = cam.CFrame:Lerp(goalCF, 1 / aimbotSmooth)
end)

ui:CreateToggle(tAim, {
    Label    = "Aimbot (Murderer Lock)",
    Default  = aimbotOn,
    OnChange = function(v) aimbotOn = v; cfg:Set("aimbotOn", v) end,
})

ui:CreateSlider(tAim, {
    Label    = "Smoothness  (lower = faster)",
    Min      = 1, Max = 20, Default = aimbotSmooth,
    OnChange = function(v) aimbotSmooth = v; cfg:Set("aimbotSmooth", v) end,
})

ui:CreateSlider(tAim, {
    Label    = "FOV Radius",
    Min      = 20, Max = 300, Default = aimbotFov, Suffix = " px",
    OnChange = function(v) aimbotFov = v; cfg:Set("aimbotFov", v) end,
})

ui:CreateSeparator(tAim)
ui:CreateLabel(tAim, { Text = "⚠  Only locks onto the Murderer role." })

-- ─────────────────────────────────────────────────────────────────────────────
-- ─── TAB: Farm ───────────────────────────────────────────────────────────────
-- ─────────────────────────────────────────────────────────────────────────────
local tFarm = win:GetTab("Farm")

ui:CreateLabel(tFarm, { Text = "💰  COIN FARM", Color = Theme.TextAccent, Size = 12 })
ui:CreateSeparator(tFarm)

local coinFarm = cfg:Get("coinFarm", false)
local autoSafe = cfg:Get("autoSafe", false)

-- Coin collector: teleports character to each coin in the workspace
local coinLoop = nil
local function startCoinFarm()
    coinLoop = RunService.Heartbeat:Connect(function()
        if not coinFarm then return end
        local char = lp.Character
        if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return end

        -- MM2 coins are typically named "Coin" or sit inside a "Coins" folder
        local coinsFolder = workspace:FindFirstChild("Coins")
                         or workspace:FindFirstChild("MapModel")
        if not coinsFolder then return end

        for _, obj in ipairs(coinsFolder:GetDescendants()) do
            if obj:IsA("BasePart") and (obj.Name == "Coin" or obj.Name == "coin") then
                -- Teleport to coin position to collect it
                root.CFrame = CFrame.new(obj.Position + Vector3.new(0, 2, 0))
                task.wait(0.05)   -- small delay to let touch event fire
            end
        end
    end)
end

local function stopCoinFarm()
    if coinLoop then coinLoop:Disconnect(); coinLoop = nil end
end

if coinFarm then startCoinFarm() end

ui:CreateToggle(tFarm, {
    Label    = "Auto Coin Collect",
    Default  = coinFarm,
    OnChange = function(v)
        coinFarm = v
        cfg:Set("coinFarm", v)
        if v then startCoinFarm() else stopCoinFarm() end
    end,
})

ui:CreateSeparator(tFarm)
ui:CreateLabel(tFarm, { Text = "🔐  SAFE CRACKER", Color = Theme.TextAccent, Size = 12 })
ui:CreateSeparator(tFarm)

-- Auto open safes by touching them
local safeLoop = nil
local function startSafeFarm()
    safeLoop = RunService.Heartbeat:Connect(function()
        if not autoSafe then return end
        local char = lp.Character
        if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return end

        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") and obj.Name:lower():find("safe") then
                root.CFrame = CFrame.new(obj.Position + Vector3.new(0, 2, 0))
                task.wait(0.1)
            end
        end
    end)
end

ui:CreateToggle(tFarm, {
    Label    = "Auto Open Safes",
    Default  = autoSafe,
    OnChange = function(v)
        autoSafe = v
        cfg:Set("autoSafe", v)
        if v then startSafeFarm()
        elseif safeLoop then safeLoop:Disconnect(); safeLoop = nil end
    end,
})

ui:CreateSeparator(tFarm)
ui:CreateButton(tFarm, {
    Text    = "Teleport to All Coins (once)",
    Icon    = "⚡",
    Primary = false,
    OnClick = function()
        local char  = lp.Character
        local root  = char and char:FindFirstChild("HumanoidRootPart")
        if not root then return end
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") and obj.Name == "Coin" then
                root.CFrame = CFrame.new(obj.Position + Vector3.new(0,2,0))
                task.wait(0.04)
            end
        end
    end,
})

-- ─────────────────────────────────────────────────────────────────────────────
-- ─── TAB: Player ─────────────────────────────────────────────────────────────
-- ─────────────────────────────────────────────────────────────────────────────
local tPlayer = win:GetTab("Player")

ui:CreateLabel(tPlayer, { Text = "🏃  MOVEMENT", Color = Theme.TextAccent, Size = 12 })
ui:CreateSeparator(tPlayer)

-- WalkSpeed
local slSpeed = ui:CreateSlider(tPlayer, {
    Label    = "Walk Speed",
    Min      = 4, Max = 100, Default = cfg:Get("walkSpeed", 16),
    OnChange = function(v)
        cfg:Set("walkSpeed", v)
        local char = lp.Character
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = v end
    end,
})

-- Re-apply speed on character respawn
lp.CharacterAdded:Connect(function(char)
    local hum = char:WaitForChild("Humanoid", 5)
    if hum then hum.WalkSpeed = slSpeed:Get() end
end)

-- JumpPower
local slJump = ui:CreateSlider(tPlayer, {
    Label    = "Jump Power",
    Min      = 7, Max = 200, Default = cfg:Get("jumpPower", 50),
    OnChange = function(v)
        cfg:Set("jumpPower", v)
        local char = lp.Character
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum.JumpPower = v end
    end,
})

ui:CreateSeparator(tPlayer)
ui:CreateLabel(tPlayer, { Text = "✈  SPECIAL", Color = Theme.TextAccent, Size = 12 })
ui:CreateSeparator(tPlayer)

-- Noclip
local noclipConn = nil
local function setNoclip(on)
    if on then
        noclipConn = RunService.Stepped:Connect(function()
            local char = lp.Character
            if not char then return end
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end)
    else
        if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
        local char = lp.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = true end
            end
        end
    end
end

ui:CreateToggle(tPlayer, {
    Label    = "Noclip",
    Default  = cfg:Get("noclip", false),
    OnChange = function(v) cfg:Set("noclip", v); setNoclip(v) end,
})

-- Fly
local flyOn   = false
local flyBody = nil
local function setFly(on)
    flyOn = on
    local char = lp.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    if not char or not root then return end

    if on then
        -- Disable gravity with a BodyVelocity
        hum.PlatformStand = true
        flyBody = Instance.new("BodyVelocity")
        flyBody.Velocity     = Vector3.zero
        flyBody.MaxForce     = Vector3.new(1e5, 1e5, 1e5)
        flyBody.Name         = "NexusFlyBody"
        flyBody.Parent       = root
        -- Fly loop: WASD moves in camera direction
        local flyConn
        flyConn = RunService.Heartbeat:Connect(function()
            if not flyOn or not flyBody or not flyBody.Parent then
                flyConn:Disconnect(); return
            end
            local speed = 30
            local cf    = cam.CFrame
            local dir   = Vector3.zero
            if UIS:IsKeyDown(Enum.KeyCode.W) then dir = dir + cf.LookVector end
            if UIS:IsKeyDown(Enum.KeyCode.S) then dir = dir - cf.LookVector end
            if UIS:IsKeyDown(Enum.KeyCode.A) then dir = dir - cf.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.D) then dir = dir + cf.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0,1,0) end
            if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then dir = dir - Vector3.new(0,1,0) end
            flyBody.Velocity = dir.Magnitude > 0
                and dir.Unit * speed
                or  Vector3.zero
        end)
    else
        if flyBody and flyBody.Parent then flyBody:Destroy() end
        flyBody = nil
        if hum then hum.PlatformStand = false end
    end
end

ui:CreateToggle(tPlayer, {
    Label    = "Fly  (WASD + Space/Shift)",
    Default  = cfg:Get("fly", false),
    OnChange = function(v) cfg:Set("fly", v); setFly(v) end,
})

ui:CreateSeparator(tPlayer)
ui:CreateButton(tPlayer, {
    Text    = "Reset Character",
    Icon    = "↺",
    Primary = false,
    OnClick = function()
        local char = lp.Character
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum.Health = 0 end
    end,
})

-- ─────────────────────────────────────────────────────────────────────────────
-- ─── TAB: Misc ───────────────────────────────────────────────────────────────
-- ─────────────────────────────────────────────────────────────────────────────
local tMisc = win:GetTab("Misc")

ui:CreateLabel(tMisc, { Text = "💬  CHAT SPY", Color = Theme.TextAccent, Size = 12 })
ui:CreateSeparator(tMisc)

local chatSpy    = cfg:Get("chatSpy", false)
local chatSpyCon = nil

local function setChatSpy(on)
    chatSpy = on
    if on then
        chatSpyCon = Players.PlayerAdded:Connect(function() end)   -- placeholder
        -- Hook into existing players' chats
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= lp then
                -- Roblox doesn't expose chat events directly in executors;
                -- we bind to the Chat service fired event instead.
                local ok = pcall(function()
                    game:GetService("Chat").Chatted:Connect(function(msg)
                        print(("[ChatSpy] %s: %s"):format(p.Name, msg))
                    end)
                end)
            end
        end
    else
        if chatSpyCon then chatSpyCon:Disconnect(); chatSpyCon = nil end
    end
end

ui:CreateToggle(tMisc, {
    Label    = "Chat Spy (prints to console)",
    Default  = chatSpy,
    OnChange = function(v) cfg:Set("chatSpy", v); setChatSpy(v) end,
})

ui:CreateSeparator(tMisc)
ui:CreateLabel(tMisc, { Text = "🌐  SERVER", Color = Theme.TextAccent, Size = 12 })
ui:CreateSeparator(tMisc)

-- Server info label
local serverInfoLbl = ui:CreateLabel(tMisc, {
    Text  = ("Players: %d / %d  |  Job: %s"):format(
        #Players:GetPlayers(),
        Players.MaxPlayers,
        game.JobId:sub(1, 8) .. "…"
    ),
    Size  = 11,
})

ui:CreateButton(tMisc, {
    Text    = "Refresh Server Info",
    Primary = false,
    OnClick = function()
        serverInfoLbl:Set(
            ("Players: %d / %d  |  Job: %s"):format(
                #Players:GetPlayers(),
                Players.MaxPlayers,
                game.JobId:sub(1, 8) .. "…"
            )
        )
    end,
})

ui:CreateButton(tMisc, {
    Text    = "Rejoin Same Server",
    Icon    = "🔄",
    Primary = false,
    OnClick = function()
        local TS = game:GetService("TeleportService")
        pcall(function()
            TS:TeleportToPlaceInstance(game.PlaceId, game.JobId, lp)
        end)
    end,
})

ui:CreateButton(tMisc, {
    Text    = "New Server",
    Icon    = "🌍",
    Primary = false,
    OnClick = function()
        local TS = game:GetService("TeleportService")
        pcall(function() TS:Teleport(game.PlaceId, lp) end)
    end,
})

ui:CreateSeparator(tMisc)
ui:CreateLabel(tMisc, { Text = "  Made with NexusUI  ·  github.com/mikolaq1111/nexusui", Size = 10 })

-- ─────────────────────────────────────────────────────────────────────────────
-- ─── TAB: Settings ───────────────────────────────────────────────────────────
-- ─────────────────────────────────────────────────────────────────────────────
local tSet = win:GetTab("Settings")

ui:CreateLabel(tSet, { Text = "⚙  CONFIG", Color = Theme.TextAccent, Size = 12 })
ui:CreateSeparator(tSet)

ui:CreateButton(tSet, {
    Text    = "💾  Save Config",
    OnClick = function()
        cfg:SaveFromHandles({
            espEnabled  = togESP,
            espNames    = togESPNames,
            espDistance = slESPDist,
            walkSpeed   = slSpeed,
            jumpPower   = slJump,
        })
        print("[MM2] Config saved.")
        local s = win.Instance:FindFirstChildOfClass("UIStroke")
        if s then
            Tween.play(s, "Fast",   { Color = Theme.Success })
            task.delay(0.7, function()
                Tween.play(s, "Normal", { Color = Theme.Border })
            end)
        end
    end,
})

ui:CreateButton(tSet, {
    Text    = "📂  Load Config",
    Primary = false,
    OnClick = function()
        cfg:Load()
        cfg:LoadToHandles({
            espEnabled  = togESP,
            espNames    = togESPNames,
            espDistance = slESPDist,
            walkSpeed   = slSpeed,
            jumpPower   = slJump,
        })
        print("[MM2] Config loaded.")
    end,
})

ui:CreateSeparator(tSet)

if not isMobile then
    ui:CreateLabel(tSet, { Text = "⌨  RightShift → show / hide menu" })
else
    ui:CreateLabel(tSet, { Text = "📱  Tap ☰ (bottom-right) to show / hide" })
end

ui:CreateSeparator(tSet)
ui:CreateLabel(tSet, { Text = "  NexusUI MM2  ·  v1.0  ·  by mikolaq1111", Size = 10 })

-- ─── 9. Desktop keybind (RightShift) ─────────────────────────────────────────
if not isMobile then
    UIS.InputBegan:Connect(function(inp, gp)
        if gp then return end
        if inp.KeyCode == Enum.KeyCode.RightShift then
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

-- ─── 10. Auto-save ───────────────────────────────────────────────────────────
cfg:StartPeriodicSave(60)
lp.CharacterRemoving:Connect(function() cfg:Save() end)

-- ─── Done ────────────────────────────────────────────────────────────────────
print("╔══════════════════════════╗")
print("║  NexusUI MM2 loaded ✓   ║")
print("║  RightShift → toggle    ║")
print("╚══════════════════════════╝")
