--[[
╔══════════════════════════════════════════════════════════════════════════════╗
║           NexusUI  ·  Murder Mystery 2  ·  Script  v1.2                    ║
╠══════════════════════════════════════════════════════════════════════════════╣
║  FIXED in v1.2                                                              ║
║    • BillboardGui.Parent was nil → ESP invisible  (parented to char root)  ║
║    • getRole() used wrong StringValue → role always "Innocent"             ║
║        now checks character tools (Knife/Gun)                              ║
║    • `continue` keyword crashed update loop in Lua 5.1 executors           ║
║    • Drag registered twice with stale reference → window unmovable         ║
║    • Coin farm searched wrong workspace path                               ║
║    • Features applied before character loaded                              ║
╠══════════════════════════════════════════════════════════════════════════════╣
║  ONE-LINER:                                                                 ║
║    loadstring(game:HttpGet(                                                 ║
║      "https://raw.githubusercontent.com/mikolaq1111/nexusui/main/script/mm2.lua" ║
║    ))()                                                                     ║
╚══════════════════════════════════════════════════════════════════════════════╝
--]]

-- ─── 1. Raw base URL ─────────────────────────────────────────────────────────
local RAW_BASE = "https://raw.githubusercontent.com/mikolaq1111/nexusui/main/"

-- ─── 2. Module loader ────────────────────────────────────────────────────────
local function loadRemote(path)
    local ok, result = pcall(function()
        return game:HttpGet(RAW_BASE .. path, true)
    end)
    if not ok then
        error("[MM2] HTTP failed for: " .. path .. "\n" .. tostring(result))
    end
    local fn, err = loadstring(result)
    if not fn then
        error("[MM2] Compile error in: " .. path .. "\n" .. tostring(err))
    end
    return fn()
end

print("[MM2] Loading NexusUI …")
local Theme      = loadRemote("ui-library/theme.lua")
local Components = loadRemote("ui-library/components.lua")
local Tween      = loadRemote("plugin-libray/tween.lua")
local Drag       = loadRemote("plugin-libray/drag.lua")
local Config     = loadRemote("plugin-libray/config.lua")

-- ─── 3. Services ─────────────────────────────────────────────────────────────
local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS        = game:GetService("UserInputService")
local lp         = Players.LocalPlayer
local cam        = workspace.CurrentCamera

-- ─── 4. Secure parent helper ─────────────────────────────────────────────────
local function getSecureParent()
    if type(gethui) == "function" then return gethui() end
    local ok, cg = pcall(function() return game:GetService("CoreGui") end)
    if ok and cg then return cg end
    return lp.PlayerGui
end

-- ─── 5. Inline Library build ─────────────────────────────────────────────────
local Library = {}
Library.__index = Library
function Library.new(customTheme)
    local self      = setmetatable({}, Library)
    self.Theme      = setmetatable(customTheme or {}, { __index = Theme })
    self._plugins   = nil
    self._windows   = {}
    local sg        = Instance.new("ScreenGui")
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

-- ─── 6. Device / screen ──────────────────────────────────────────────────────
local isMobile = UIS.TouchEnabled and not UIS.MouseEnabled
local vp       = cam and cam.ViewportSize or Vector2.new(800, 600)
local winW     = math.min(math.floor(vp.X * 0.96), 430)
local winH     = math.min(math.floor(vp.Y * 0.88), 530)

-- ─── 7. Config ───────────────────────────────────────────────────────────────
local Plugins = {
    Tween = Tween, Drag = Drag, Config = Config,
    newConfig = function(p, d) return Config.new(p, d) end,
    play      = function(...) return Tween.play(...) end,
}

local cfg = Plugins.newConfig("nexus/mm2_settings.json", {
    espEnabled   = true,
    espNames     = true,
    espDistance  = 500,
    aimbotOn     = false,
    aimbotSmooth = 6,
    aimbotFov    = 90,
    coinFarm     = false,
    walkSpeed    = 16,
    jumpPower    = 50,
    noclip       = false,
    fly          = false,
    chatSpy      = false,
})

-- ─── 8. Window ───────────────────────────────────────────────────────────────
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

-- FIX: drag is already set up inside CreateWindow (via plugins.Drag).
-- We do NOT call Drag.makeDraggable again here — calling it twice cleared
-- the first set of connections and re-registered with a potentially nil
-- TitleBar reference, making the window unmovable.
-- Window position save/restore is handled separately:
cfg:RestoreWindowPosition("mm2win", win.Instance)
-- Save position on drag end — hook into the existing drag via an extra
-- InputEnded listener on the titleBar:
local titleBar = win.Instance:FindFirstChild("TitleBar")
if titleBar then
    titleBar.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            cfg:SaveWindowPosition("mm2win", win.Instance)
        end
    end)
end

-- ─── 8b. Mobile toggle button (own ScreenGui — never hides) ──────────────────
if isMobile then
    local btnGui            = Instance.new("ScreenGui")
    btnGui.Name             = "NexusMM2ToggleGui"
    btnGui.ResetOnSpawn     = false
    btnGui.DisplayOrder     = 1000
    btnGui.IgnoreGuiInset   = true
    btnGui.Parent           = getSecureParent()

    local mb                = Instance.new("TextButton")
    mb.Size                 = UDim2.new(0, 56, 0, 56)
    mb.Position             = UDim2.new(1, -68, 1, -80)
    mb.BackgroundColor3     = Theme.Accent
    mb.BorderSizePixel      = 0
    mb.Font                 = Theme.FontBody
    mb.TextSize             = 24
    mb.Text                 = "☰"
    mb.TextColor3           = Theme.TextPrimary
    mb.AutoButtonColor      = false
    mb.ZIndex               = 1
    mb.Parent               = btnGui
    local mbC               = Instance.new("UICorner")
    mbC.CornerRadius        = UDim.new(1, 0)
    mbC.Parent              = mb

    -- Make the button itself draggable so the user can reposition it
    Drag.makeDraggable(mb, mb)

    mb.MouseButton1Click:Connect(function()
        guiOpen = not guiOpen
        if guiOpen then
            win.Instance.Visible = true
            Tween.openWindow(win.Instance, UDim2.new(0, winW, 0, winH))
            mb.Text = "✕"
        else
            Tween.closeWindow(win.Instance)
            mb.Text = "☰"
        end
    end)
end

-- ═════════════════════════════════════════════════════════════════════════════
-- ─── TAB: ESP ────────────────────────────────────────────────────────────────
-- ═════════════════════════════════════════════════════════════════════════════
local tESP = win:GetTab("ESP")
ui:CreateLabel(tESP, { Text = "👁  PLAYER ESP", Color = Theme.TextAccent, Size = 12 })
ui:CreateSeparator(tESP)

local ROLE_COLOR = {
    Murderer = Color3.fromRGB(255, 60,  60),
    Sheriff  = Color3.fromRGB( 60, 160, 255),
    Innocent = Color3.fromRGB( 60, 230,  90),
    Unknown  = Color3.fromRGB(200, 200, 200),
}

local espEnabled  = cfg:Get("espEnabled",  true)
local espNames    = cfg:Get("espNames",    true)
local espDistance = cfg:Get("espDistance", 500)

-- FIX: Role detection via character tools, NOT a StringValue.
-- Murderer always has a tool named "Knife" in their character.
-- Sheriff always has a tool named "Sheriff's Gun" (or "ClassicSheriff").
local function getRole(player)
    local char = player.Character
    if not char then return "Unknown" end
    -- Tool search covers both character (equipped) and Backpack (unequipped)
    local function hasTool(name)
        if char:FindFirstChild(name) then return true end
        local bp = player:FindFirstChild("Backpack")
        if bp and bp:FindFirstChild(name) then return true end
        return false
    end
    if hasTool("Knife") or hasTool("MM2Knife") then
        return "Murderer"
    end
    if hasTool("Sheriff's Gun") or hasTool("ClassicSheriff") or hasTool("Gun") then
        return "Sheriff"
    end
    return "Innocent"
end

-- ESP object store: player → { billboard, nameLabel, roleLabel, charConn }
local espObjects = {}

local function createESPFor(player)
    if player == lp then return end
    if espObjects[player] then return end

    local billboard = Instance.new("BillboardGui")
    billboard.Name           = "NexusESP_" .. player.Name
    billboard.AlwaysOnTop    = true
    billboard.Size           = UDim2.new(0, 130, 0, 44)
    billboard.StudsOffset    = Vector3.new(0, 3.2, 0)
    billboard.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    -- !! FIX: billboard MUST have a Parent to be visible !!
    -- We parent to the character root so it auto-removes on respawn.
    -- If the character isn't loaded yet we'll attach it in charConn.
    billboard.Enabled        = espEnabled and espNames

    local nameLbl = Instance.new("TextLabel")
    nameLbl.Size                    = UDim2.new(1, 0, 0.55, 0)
    nameLbl.BackgroundTransparency  = 1
    nameLbl.Font                    = Theme.FontTitle
    nameLbl.TextSize                = 13
    nameLbl.TextColor3              = ROLE_COLOR.Unknown
    nameLbl.TextStrokeTransparency  = 0.3
    nameLbl.Text                    = player.Name
    nameLbl.ZIndex                  = 1
    nameLbl.Parent                  = billboard

    local roleLbl = Instance.new("TextLabel")
    roleLbl.Size                    = UDim2.new(1, 0, 0.45, 0)
    roleLbl.Position                = UDim2.new(0, 0, 0.55, 0)
    roleLbl.BackgroundTransparency  = 1
    roleLbl.Font                    = Theme.FontBody
    roleLbl.TextSize                = 10
    roleLbl.TextColor3              = ROLE_COLOR.Unknown
    roleLbl.TextStrokeTransparency  = 0.3
    roleLbl.Text                    = "[?]"
    roleLbl.ZIndex                  = 1
    roleLbl.Parent                  = billboard

    -- Attach billboard to the HumanoidRootPart (parent + adornee = same part)
    local function attach(char)
        local root = char:WaitForChild("HumanoidRootPart", 8)
        if root then
            billboard.Adornee = root
            billboard.Parent  = root   -- ← THE KEY FIX
        end
    end

    local charConn = player.CharacterAdded:Connect(attach)
    if player.Character then
        task.spawn(attach, player.Character)
    end

    espObjects[player] = {
        billboard = billboard,
        nameLbl   = nameLbl,
        roleLbl   = roleLbl,
        charConn  = charConn,
    }
end

local function removeESPFor(player)
    local h = espObjects[player]
    if not h then return end
    if h.charConn then h.charConn:Disconnect() end
    if h.billboard then h.billboard:Destroy() end
    espObjects[player] = nil
end

local function refreshAllESP()
    -- Remove everyone then re-add if enabled
    for p in pairs(espObjects) do
        removeESPFor(p)
    end
    if not espEnabled then return end
    for _, p in ipairs(Players:GetPlayers()) do
        createESPFor(p)
    end
end

-- FIX: replaced `continue` (Lua 5.1 unsupported) with nested `if` guards.
RunService.RenderStepped:Connect(function()
    if not espEnabled then return end
    for player, h in pairs(espObjects) do
        local char   = player.Character
        local isOk   = char ~= nil
        local root   = isOk and char:FindFirstChild("HumanoidRootPart") or nil
        isOk = isOk and root ~= nil
        if isOk then
            -- Distance cull
            local myRoot = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
            if myRoot and (root.Position - myRoot.Position).Magnitude > espDistance then
                isOk = false
            end
        end
        if isOk then
            local role = getRole(player)
            local col  = ROLE_COLOR[role] or ROLE_COLOR.Unknown
            h.billboard.Enabled  = espNames
            h.nameLbl.TextColor3 = col
            h.roleLbl.TextColor3 = col
            h.roleLbl.Text       = "[" .. role .. "]"
        else
            h.billboard.Enabled = false
        end
    end
end)

Players.PlayerAdded:Connect(function(p)
    if espEnabled then createESPFor(p) end
end)
Players.PlayerRemoving:Connect(removeESPFor)

-- Controls
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
    OnChange = function(v)
        espNames = v
        cfg:Set("espNames", v)
        for _, h in pairs(espObjects) do
            h.billboard.Enabled = v
        end
    end,
})

local slESPDist = ui:CreateSlider(tESP, {
    Label    = "Render Distance",
    Min      = 50, Max = 1000, Default = espDistance, Suffix = " m",
    OnChange = function(v) espDistance = v; cfg:Set("espDistance", v) end,
})

ui:CreateSeparator(tESP)
ui:CreateLabel(tESP, { Text = "  🔴 Murderer  🔵 Sheriff  🟢 Innocent", Size = 11 })

-- Start ESP
refreshAllESP()

-- ═════════════════════════════════════════════════════════════════════════════
-- ─── TAB: Aimbot ─────────────────────────────────────────────────────────────
-- ═════════════════════════════════════════════════════════════════════════════
local tAim = win:GetTab("Aimbot")
ui:CreateLabel(tAim, { Text = "🎯  LOCK-ON  (Murderer)", Color = Theme.TextAccent, Size = 12 })
ui:CreateSeparator(tAim)

local aimbotOn     = cfg:Get("aimbotOn",     false)
local aimbotSmooth = cfg:Get("aimbotSmooth", 6)
local aimbotFov    = cfg:Get("aimbotFov",    90)

-- FOV circle (Drawing API — available in most executors)
local fovCircle
local hasDrawing = pcall(function()
    fovCircle          = Drawing.new("Circle")
    fovCircle.Visible  = false
    fovCircle.Radius   = aimbotFov
    fovCircle.Color    = Color3.fromRGB(255, 80, 80)
    fovCircle.Thickness= 1.5
    fovCircle.Filled   = false
end)

local function nearestMurderer()
    local best, bestDist = nil, math.huge
    local center = Vector2.new(vp.X / 2, vp.Y / 2)
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= lp and getRole(p) == "Murderer" and p.Character then
            local root = p.Character:FindFirstChild("HumanoidRootPart")
            if root then
                local sp, onScreen = cam:WorldToViewportPoint(root.Position)
                if onScreen then
                    local dist = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                    if dist < aimbotFov and dist < bestDist then
                        best, bestDist = p, dist
                    end
                end
            end
        end
    end
    return best
end

RunService.RenderStepped:Connect(function()
    if hasDrawing and fovCircle then
        fovCircle.Position = Vector2.new(vp.X / 2, vp.Y / 2)
        fovCircle.Radius   = aimbotFov
        fovCircle.Visible  = aimbotOn
    end
    if not aimbotOn then return end
    local target = nearestMurderer()
    if not target or not target.Character then return end
    local head = target.Character:FindFirstChild("Head")
    if not head then return end
    local goalCF = CFrame.lookAt(cam.CFrame.Position, head.Position)
    cam.CFrame   = cam.CFrame:Lerp(goalCF, 1 / math.max(aimbotSmooth, 1))
end)

ui:CreateToggle(tAim, {
    Label    = "Aimbot (Murderer Lock)",
    Default  = aimbotOn,
    OnChange = function(v) aimbotOn = v; cfg:Set("aimbotOn", v) end,
})
ui:CreateSlider(tAim, {
    Label    = "Smoothness",
    Min      = 1, Max = 20, Default = aimbotSmooth,
    OnChange = function(v) aimbotSmooth = v; cfg:Set("aimbotSmooth", v) end,
})
ui:CreateSlider(tAim, {
    Label    = "FOV Radius",
    Min      = 20, Max = 300, Default = aimbotFov, Suffix = " px",
    OnChange = function(v) aimbotFov = v; cfg:Set("aimbotFov", v) end,
})
ui:CreateSeparator(tAim)
ui:CreateLabel(tAim, { Text = "  Locks camera to nearest Murderer inside FOV." })

-- ═════════════════════════════════════════════════════════════════════════════
-- ─── TAB: Farm ───────────────────────────────────────────────────────────────
-- ═════════════════════════════════════════════════════════════════════════════
local tFarm = win:GetTab("Farm")
ui:CreateLabel(tFarm, { Text = "💰  COIN FARM", Color = Theme.TextAccent, Size = 12 })
ui:CreateSeparator(tFarm)

local coinFarm    = cfg:Get("coinFarm", false)
local coinConn    = nil

-- FIX: MM2 coins are children of the active map model, not a top-level folder.
-- We search the entire workspace for parts named "Coin".
local function collectCoins()
    local char = lp.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Name == "Coin" then
            -- Teleport onto the coin to collect it via Touch
            root.CFrame = CFrame.new(obj.Position + Vector3.new(0, 2, 0))
            task.wait(0.05)
        end
    end
end

local function startCoinFarm()
    if coinConn then coinConn:Disconnect() end
    coinConn = RunService.Heartbeat:Connect(function()
        if not coinFarm then return end
        collectCoins()
    end)
end

local function stopCoinFarm()
    if coinConn then coinConn:Disconnect(); coinConn = nil end
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

ui:CreateButton(tFarm, {
    Text    = "Collect All Coins (once)",
    Icon    = "⚡",
    Primary = false,
    OnClick = function() task.spawn(collectCoins) end,
})

ui:CreateSeparator(tFarm)
ui:CreateLabel(tFarm, { Text = "🔐  SAFE FARM", Color = Theme.TextAccent, Size = 12 })
ui:CreateSeparator(tFarm)

local safeConn = nil
local function collectSafes()
    local char = lp.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Name:lower():find("safe") then
            root.CFrame = CFrame.new(obj.Position + Vector3.new(0, 2, 0))
            task.wait(0.1)
        end
    end
end

ui:CreateToggle(tFarm, {
    Label    = "Auto Open Safes",
    Default  = false,
    OnChange = function(v)
        if v then
            if safeConn then safeConn:Disconnect() end
            safeConn = RunService.Heartbeat:Connect(function()
                task.spawn(collectSafes)
                task.wait(1)
            end)
        else
            if safeConn then safeConn:Disconnect(); safeConn = nil end
        end
    end,
})

-- ═════════════════════════════════════════════════════════════════════════════
-- ─── TAB: Player ─────────────────────────────────────────────────────────────
-- ═════════════════════════════════════════════════════════════════════════════
local tPlayer = win:GetTab("Player")
ui:CreateLabel(tPlayer, { Text = "🏃  MOVEMENT", Color = Theme.TextAccent, Size = 12 })
ui:CreateSeparator(tPlayer)

-- Helper: get local humanoid safely
local function getHum()
    local char = lp.Character
    return char and char:FindFirstChildOfClass("Humanoid")
end
local function getRoot()
    local char = lp.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

-- Apply speed / jump whenever character (re)spawns
local function applyPlayerStats(hum)
    if not hum then return end
    hum.WalkSpeed = cfg:Get("walkSpeed", 16)
    hum.JumpPower = cfg:Get("jumpPower", 50)
end
lp.CharacterAdded:Connect(function(char)
    local hum = char:WaitForChild("Humanoid", 8)
    applyPlayerStats(hum)
end)
applyPlayerStats(getHum())  -- apply to already-loaded char

local slSpeed = ui:CreateSlider(tPlayer, {
    Label    = "Walk Speed",
    Min = 4, Max = 120, Default = cfg:Get("walkSpeed", 16),
    OnChange = function(v)
        cfg:Set("walkSpeed", v)
        local h = getHum(); if h then h.WalkSpeed = v end
    end,
})

local slJump = ui:CreateSlider(tPlayer, {
    Label    = "Jump Power",
    Min = 7, Max = 300, Default = cfg:Get("jumpPower", 50),
    OnChange = function(v)
        cfg:Set("jumpPower", v)
        local h = getHum(); if h then h.JumpPower = v end
    end,
})

ui:CreateSeparator(tPlayer)
ui:CreateLabel(tPlayer, { Text = "✈  SPECIAL", Color = Theme.TextAccent, Size = 12 })
ui:CreateSeparator(tPlayer)

-- ── Noclip ───────────────────────────────────────────────────────────────────
local noclipConn = nil
local function setNoclip(on)
    if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
    if on then
        noclipConn = RunService.Stepped:Connect(function()
            local char = lp.Character
            if not char then return end
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = false end
            end
        end)
    else
        local char = lp.Character
        if char then
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = true end
            end
        end
    end
end

ui:CreateToggle(tPlayer, {
    Label    = "Noclip",
    Default  = false,
    OnChange = function(v) cfg:Set("noclip", v); setNoclip(v) end,
})

-- ── Fly ──────────────────────────────────────────────────────────────────────
local flyOn   = false
local flyBody = nil
local flyConn = nil
local FLY_SPEED = 36

local function setFly(on)
    flyOn = on
    -- Clean up previous state
    if flyConn then flyConn:Disconnect(); flyConn = nil end
    if flyBody and flyBody.Parent then flyBody:Destroy() end
    flyBody = nil

    local char = lp.Character
    local root = getRoot()
    local hum  = getHum()
    if not (char and root and hum) then return end

    if on then
        hum.PlatformStand = true
        flyBody           = Instance.new("BodyVelocity")
        flyBody.Velocity  = Vector3.zero
        flyBody.MaxForce  = Vector3.new(1e5, 1e5, 1e5)
        flyBody.Name      = "NexusFly"
        flyBody.Parent    = root

        flyConn = RunService.Heartbeat:Connect(function()
            if not flyOn or not flyBody or not flyBody.Parent then
                if flyConn then flyConn:Disconnect(); flyConn = nil end
                return
            end
            local dir = Vector3.zero
            local cf  = cam.CFrame
            if UIS:IsKeyDown(Enum.KeyCode.W) then dir = dir + cf.LookVector  end
            if UIS:IsKeyDown(Enum.KeyCode.S) then dir = dir - cf.LookVector  end
            if UIS:IsKeyDown(Enum.KeyCode.A) then dir = dir - cf.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.D) then dir = dir + cf.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.Space)     then dir = dir + Vector3.new(0,1,0) end
            if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then dir = dir - Vector3.new(0,1,0) end
            flyBody.Velocity = dir.Magnitude > 0
                and dir.Unit * FLY_SPEED
                or  Vector3.zero
        end)
    else
        if hum then hum.PlatformStand = false end
    end
end

-- Re-apply fly on respawn
lp.CharacterAdded:Connect(function()
    task.wait(0.5)
    if flyOn then setFly(true) end
    if noclipConn then setNoclip(true) end
end)

ui:CreateToggle(tPlayer, {
    Label    = "Fly  (WASD + Space / Shift)",
    Default  = false,
    OnChange = function(v) cfg:Set("fly", v); setFly(v) end,
})

ui:CreateSeparator(tPlayer)
ui:CreateButton(tPlayer, {
    Text    = "Reset Character",
    Icon    = "↺",
    Primary = false,
    OnClick = function()
        local h = getHum(); if h then h.Health = 0 end
    end,
})

-- ═════════════════════════════════════════════════════════════════════════════
-- ─── TAB: Misc ───────────────────────────────────────────────────────────────
-- ═════════════════════════════════════════════════════════════════════════════
local tMisc = win:GetTab("Misc")
ui:CreateLabel(tMisc, { Text = "💬  CHAT SPY", Color = Theme.TextAccent, Size = 12 })
ui:CreateSeparator(tMisc)

local chatSpyConns = {}
local function setChatSpy(on)
    for _, c in ipairs(chatSpyConns) do c:Disconnect() end
    chatSpyConns = {}
    if not on then return end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= lp then
            local conn = p.Chatted:Connect(function(msg)
                print(("[ChatSpy] %s: %s"):format(p.Name, msg))
            end)
            table.insert(chatSpyConns, conn)
        end
    end
    local addConn = Players.PlayerAdded:Connect(function(p)
        if p == lp then return end
        local conn = p.Chatted:Connect(function(msg)
            print(("[ChatSpy] %s: %s"):format(p.Name, msg))
        end)
        table.insert(chatSpyConns, conn)
    end)
    table.insert(chatSpyConns, addConn)
end

ui:CreateToggle(tMisc, {
    Label    = "Chat Spy (prints to console)",
    Default  = false,
    OnChange = function(v) cfg:Set("chatSpy", v); setChatSpy(v) end,
})

ui:CreateSeparator(tMisc)
ui:CreateLabel(tMisc, { Text = "🌐  SERVER", Color = Theme.TextAccent, Size = 12 })
ui:CreateSeparator(tMisc)

local function serverInfo()
    return ("Players: %d/%d  |  Job: %s…"):format(
        #Players:GetPlayers(), Players.MaxPlayers, game.JobId:sub(1, 8))
end
local srvLbl = ui:CreateLabel(tMisc, { Text = serverInfo(), Size = 11 })
ui:CreateButton(tMisc, {
    Text = "Refresh Server Info", Primary = false,
    OnClick = function() srvLbl:Set(serverInfo()) end,
})
ui:CreateButton(tMisc, {
    Text = "Rejoin Same Server", Icon = "🔄", Primary = false,
    OnClick = function()
        pcall(function()
            game:GetService("TeleportService"):TeleportToPlaceInstance(
                game.PlaceId, game.JobId, lp)
        end)
    end,
})
ui:CreateButton(tMisc, {
    Text = "New Server", Icon = "🌍", Primary = false,
    OnClick = function()
        pcall(function()
            game:GetService("TeleportService"):Teleport(game.PlaceId, lp)
        end)
    end,
})

-- ═════════════════════════════════════════════════════════════════════════════
-- ─── TAB: Settings ───────────────────────────────────────────────────────────
-- ═════════════════════════════════════════════════════════════════════════════
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
    Text = "📂  Load Config", Primary = false,
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
    ui:CreateLabel(tSet, { Text = "⌨  RightShift  →  show / hide menu" })
else
    ui:CreateLabel(tSet, { Text = "📱  Tap ☰ (drag to reposition) to toggle menu" })
end
ui:CreateSeparator(tSet)
ui:CreateLabel(tSet, { Text = "  NexusUI MM2  v1.2  ·  mikolaq1111", Size = 10 })

-- ─── Desktop keybind ─────────────────────────────────────────────────────────
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

-- ─── Auto-save ───────────────────────────────────────────────────────────────
cfg:StartPeriodicSave(60)
lp.CharacterRemoving:Connect(function() cfg:Save() end)

print("╔═══════════════════════════╗")
print("║  NexusUI MM2 v1.2  ✓     ║")
print("║  RightShift  →  toggle   ║")
print("╚═══════════════════════════╝")
