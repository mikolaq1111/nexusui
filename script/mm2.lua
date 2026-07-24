--[[
╔══════════════════════════════════════════════════════════════════════════════╗
║         NexusUI  ·  Murder Mystery 2  ·  v3.0  Aurora Edition              ║
╠══════════════════════════════════════════════════════════════════════════════╣
║  NEW IN v3.0                                                                ║
║  • Aurora animated title-bar gradient (teal→violet→magenta)                ║
║  • Auto Pick Gun  FIXED: uses workspace.ChildAdded event, not polling      ║
║  • Auto Collect Sheriff Star (same event approach)                         ║
║  • Highlight Chams  — Roblox Highlight instance, through-wall glow         ║
║  • Anti-Void  — saves safe position, teleports back if you fall            ║
║  • Kill Counter  — tracks kills this session                               ║
║  • Visual tab  — Lighting presets, Aurora sky, No Fog, Bloom, FOV         ║
║  • Popular features: Inf Stamina, Save/Load position, God attempt,         ║
║    No animations, Speed boost hotkey, Chat spy, Rejoin tools               ║
╠══════════════════════════════════════════════════════════════════════════════╣
║  ONE-LINER:                                                                 ║
║  loadstring(game:HttpGet(                                                   ║
║    "https://raw.githubusercontent.com/mikolaq1111/nexusui/main/script/mm2.lua" ║
║  ))()                                                                       ║
╚══════════════════════════════════════════════════════════════════════════════╝
--]]

-- ─── 1. Module loader ────────────────────────────────────────────────────────
local RAW = "https://raw.githubusercontent.com/mikolaq1111/nexusui/main/"
local function loadMod(path)
    local ok, src = pcall(game.HttpGet, game, RAW..path, true)
    if not ok then error("[MM2] HTTP:"..path.."\n"..tostring(src)) end
    local fn, e = loadstring(src)
    if not fn then error("[MM2] Parse:"..path.."\n"..tostring(e)) end
    return fn()
end
print("[MM2] NexusUI Aurora v3.0 loading…")
local Theme      = loadMod("ui-library/theme.lua")
local Components = loadMod("ui-library/components.lua")
local Tween      = loadMod("plugin-libray/tween.lua")
local Drag       = loadMod("plugin-libray/drag.lua")
local Config     = loadMod("plugin-libray/config.lua")

-- ─── 2. Services ─────────────────────────────────────────────────────────────
local Players    = game:GetService("Players")
local RS         = game:GetService("RunService")
local UIS        = game:GetService("UserInputService")
local TweenSvc   = game:GetService("TweenService")
local Lighting   = game:GetService("Lighting")
local lp         = Players.LocalPlayer
local cam        = workspace.CurrentCamera

-- ─── 3. Helpers ──────────────────────────────────────────────────────────────
local function getSecure()
    if type(gethui)=="function" then return gethui() end
    local ok,cg = pcall(function() return game:GetService("CoreGui") end)
    if ok then return cg end
    return lp.PlayerGui
end
local function getHum()
    local c=lp.Character; return c and c:FindFirstChildOfClass("Humanoid")
end
local function getRoot()
    local c=lp.Character; return c and c:FindFirstChild("HumanoidRootPart")
end

local isMobile = UIS.TouchEnabled and not UIS.MouseEnabled
local vp       = cam.ViewportSize
local winW     = math.min(math.floor(vp.X*0.95), 450)
local winH     = math.min(math.floor(vp.Y*0.90), 545)

-- ─── 4. Inline Library ───────────────────────────────────────────────────────
local Library = {}; Library.__index = Library
function Library.new()
    local self = setmetatable({},Library)
    self.Theme    = setmetatable({},{__index=Theme})
    self._plugins = nil
    self._windows = {}
    local sg = Instance.new("ScreenGui")
    sg.Name="NexusMM2_"..math.random(1e3,9e3)
    sg.ResetOnSpawn=false; sg.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
    sg.DisplayOrder=999; sg.IgnoreGuiInset=true; sg.Parent=getSecure()
    self._screenGui=sg; return self
end
function Library:SetPlugins(p) self._plugins=p end
for _,n in ipairs({"CreateWindow","CreateButton","CreateToggle","CreateSlider",
    "CreateTextBox","CreateDropdown","CreateLabel","CreateSeparator","CreateBadge"}) do
    Library[n]=function(self,...)
        local a={...}
        if n=="CreateWindow" then
            local h=Components[n](self._screenGui,a[1],self.Theme,self._plugins)
            table.insert(self._windows,h); return h
        end
        return Components[n](a[1],a[2],self.Theme,self._plugins)
    end
end

-- ─── 5. Config ───────────────────────────────────────────────────────────────
local Plugins={Tween=Tween,Drag=Drag,Config=Config,
    newConfig=function(p,d) return Config.new(p,d) end,
    play=function(...) return Tween.play(...) end}

local cfg = Plugins.newConfig("nexus/mm2v3.json",{
    -- ESP
    espOn=true, espNames=true, espBoxes=true, espChams=true,
    espDist=700, espRainbow=false,
    -- Aimbot
    aimMode="Lock", aimTarget="Murder", aimSmooth=7, aimFov=110,
    -- Farm
    coinFarm=false, pickGun=true, pickStar=true,
    -- Combat
    killAura=false, auraRange=12, knifeReach=false,
    -- Player
    walkSpeed=16, jumpPower=50,
    noclip=false, fly=false, infJump=false, antiAfk=false,
    antiVoid=true, infStamina=false,
    -- Visual
    crosshair=false, customFov=70, noFog=false,
    lightPreset="Default",
    -- Misc
    roleAlert=true, chatSpy=false,
})

-- ─── 6. Window ───────────────────────────────────────────────────────────────
local ui = Library.new(); ui:SetPlugins(Plugins)
local guiOpen = true

local win = ui:CreateWindow({
    Title     = "✦ NexusUI  ·  MM2  Aurora",
    Size      = UDim2.new(0,winW,0,winH),
    Position  = UDim2.new(0.5,-winW/2,0.5,-winH/2),
    CanClose  = true, CanMinimise = true,
    Tabs      = {"ESP","Aimbot","Farm","Combat","Player","Visual","Settings"},
})
cfg:RestoreWindowPosition("mm2v3",win.Instance)

-- Save position on drag end
local tb = win.Instance:FindFirstChild("TitleBar")
if tb then
    tb.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1
        or i.UserInputType==Enum.UserInputType.Touch then
            cfg:SaveWindowPosition("mm2v3",win.Instance)
        end
    end)
    -- ── Aurora animated title-bar gradient ──────────────────────────────────
    if Components.StartAurora then Components.StartAurora(tb) end
end

-- ─── 7. Toast notification system ────────────────────────────────────────────
local toastGui = Instance.new("ScreenGui")
toastGui.Name="NexusToastV3"; toastGui.ResetOnSpawn=false
toastGui.DisplayOrder=2000; toastGui.IgnoreGuiInset=true
toastGui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
toastGui.Parent=getSecure()

local TOAST_H, TOAST_GAP = 80, 6
local toastStack = {}   -- {frame, targetY}

local function shiftToasts()
    local y = 10
    for _, entry in ipairs(toastStack) do
        TweenSvc:Create(entry.fr, TweenInfo.new(0.18),
            {Position=UDim2.new(1,-318,0,y)}):Play()
        y = y + TOAST_H + TOAST_GAP
    end
end

local function showToast(title, body, color, duration)
    color    = color or Theme.Accent
    duration = duration or 5

    local fr = Instance.new("Frame")
    fr.Size                  = UDim2.new(0,308,0,TOAST_H)
    fr.Position              = UDim2.new(1,10,0,10)
    fr.BackgroundColor3      = Color3.fromRGB(4,4,16)
    fr.BackgroundTransparency= 0.04
    fr.BorderSizePixel       = 0
    fr.ZIndex                = 1
    fr.Parent                = toastGui

    local cr = Instance.new("UICorner"); cr.CornerRadius=UDim.new(0,10); cr.Parent=fr
    local sk = Instance.new("UIStroke"); sk.Color=color; sk.Thickness=1.4; sk.Parent=fr

    -- left accent bar
    local bar = Instance.new("Frame")
    bar.Size=UDim2.new(0,4,1,0); bar.BackgroundColor3=color
    bar.BorderSizePixel=0; bar.ZIndex=2; bar.Parent=fr
    local bc = Instance.new("UICorner"); bc.CornerRadius=UDim.new(0,4); bc.Parent=bar

    -- icon dot
    local dot = Instance.new("Frame")
    dot.Size=UDim2.new(0,8,0,8); dot.Position=UDim2.new(0,14,0,14)
    dot.BackgroundColor3=color; dot.BorderSizePixel=0; dot.ZIndex=2; dot.Parent=fr
    Instance.new("UICorner").Parent=dot

    local tl = Instance.new("TextLabel")
    tl.Size=UDim2.new(1,-26,0,22); tl.Position=UDim2.new(0,26,0,8)
    tl.BackgroundTransparency=1; tl.Font=Enum.Font.GothamBold
    tl.TextSize=13; tl.TextColor3=color; tl.Text=title
    tl.TextXAlignment=Enum.TextXAlignment.Left; tl.ZIndex=2; tl.Parent=fr

    local bl = Instance.new("TextLabel")
    bl.Size=UDim2.new(1,-26,0,34); bl.Position=UDim2.new(0,26,0,30)
    bl.BackgroundTransparency=1; bl.Font=Enum.Font.Gotham
    bl.TextSize=12; bl.TextColor3=Theme.TextSecondary; bl.Text=body
    bl.TextWrapped=true; bl.TextXAlignment=Enum.TextXAlignment.Left
    bl.ZIndex=2; bl.Parent=fr

    local entry = {fr=fr}
    table.insert(toastStack, entry)
    shiftToasts()

    task.delay(duration, function()
        TweenSvc:Create(fr, TweenInfo.new(0.22),
            {Position=UDim2.new(1,10,0,fr.Position.Y.Offset)}):Play()
        task.delay(0.25, function()
            fr:Destroy()
            for i,e in ipairs(toastStack) do
                if e==entry then table.remove(toastStack,i); break end
            end
            shiftToasts()
        end)
    end)
end

-- ─── 8. Role detection ───────────────────────────────────────────────────────
local ROLE_COLOR = {
    Murderer = Color3.fromRGB(255, 55, 55),
    Sheriff  = Color3.fromRGB( 55,165,255),
    Innocent = Color3.fromRGB( 55,230, 95),
    Unknown  = Color3.fromRGB(170,170,170),
}

local function getRole(p)
    local c = p.Character; if not c then return "Unknown" end
    local function has(n)
        if c:FindFirstChild(n) then return true end
        local bp = p:FindFirstChild("Backpack")
        return bp and bp:FindFirstChild(n)~=nil
    end
    if has("Knife") or has("MM2Knife") then return "Murderer" end
    if has("Sheriff's Gun") or has("ClassicSheriff") or has("Gun") then return "Sheriff" end
    return "Innocent"
end

-- ─── 9. Role-reveal toasts (watch tool changes) ──────────────────────────────
local alerted      = {}
local roleAlertOn  = cfg:Get("roleAlert",true)

local function checkAlert(p)
    if not roleAlertOn then return end
    local r = getRole(p)
    if r == "Innocent" or r == "Unknown" then return end
    if alerted[p] == r then return end
    alerted[p] = r
    if p == lp then
        showToast("🎭 YOUR ROLE","You are the "..r.."!", ROLE_COLOR[r], 7)
    else
        local icon = r=="Murderer" and "🔪" or "⭐"
        showToast(icon.." "..r.." FOUND", p.Name.." is the "..r.."!", ROLE_COLOR[r], 8)
    end
end

local function watchChar(p, char)
    char.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then task.delay(0.7, function() checkAlert(p) end) end
    end)
    task.delay(1.5, function() checkAlert(p) end)
end

for _,p in ipairs(Players:GetPlayers()) do
    p.CharacterAdded:Connect(function(c) alerted[p]=nil; watchChar(p,c) end)
    if p.Character then watchChar(p,p.Character) end
end
Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function(c) alerted[p]=nil; watchChar(p,c) end)
end)

-- ─── 10. ESP ─────────────────────────────────────────────────────────────────
local espOn      = cfg:Get("espOn",     true)
local espNames   = cfg:Get("espNames",  true)
local espBoxes   = cfg:Get("espBoxes",  true)
local espChams   = cfg:Get("espChams",  true)
local espDist    = cfg:Get("espDist",   700)
local espRainbow = cfg:Get("espRainbow",false)
local rainbowH   = 0

local espObjs = {}  -- [player] = { highlight, billboard, selBox, bgStroke,
                    --              roleLbl, hpFill, distLbl, charConn }

local function buildESP(p)
    if p == lp or espObjs[p] then return end
    local h = {}

    -- ── Highlight (through-wall chams) ────────────────────────────────────
    local hl = Instance.new("Highlight")
    hl.Name               = "NexusHL_"..p.Name
    hl.FillColor          = ROLE_COLOR.Unknown
    hl.OutlineColor       = ROLE_COLOR.Unknown
    hl.FillTransparency   = 0.55
    hl.OutlineTransparency= 0.05
    hl.DepthMode          = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Enabled            = espChams
    hl.Parent             = workspace
    h.hl = hl

    -- ── SelectionBox (3-D outline around character model) ────────────────
    local sb = Instance.new("SelectionBox")
    sb.Color3             = ROLE_COLOR.Unknown
    sb.SurfaceColor3      = ROLE_COLOR.Unknown
    sb.SurfaceTransparency= 0.80
    sb.LineThickness      = 0.042
    sb.Visible            = false
    sb.Parent             = workspace
    h.selBox = sb

    -- ── BillboardGui info card ────────────────────────────────────────────
    local bb = Instance.new("BillboardGui")
    bb.AlwaysOnTop    = true
    bb.Size           = UDim2.new(0,176,0,68)
    bb.StudsOffset    = Vector3.new(0,3.6,0)
    bb.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    bb.Enabled        = false

    -- frosted card
    local bg = Instance.new("Frame")
    bg.Size=UDim2.new(1,0,1,0)
    bg.BackgroundColor3=Color3.fromRGB(4,4,16)
    bg.BackgroundTransparency=0.18
    bg.BorderSizePixel=0; bg.ZIndex=1; bg.Parent=bb
    Instance.new("UICorner").CornerRadius=UDim.new(0,9); Instance.new("UICorner").Parent=bg

    local bgS = Instance.new("UIStroke")
    bgS.Color=ROLE_COLOR.Unknown; bgS.Thickness=1.6; bgS.Parent=bg; h.bgStroke=bgS

    -- name
    local nl = Instance.new("TextLabel")
    nl.Size=UDim2.new(1,-10,0,22); nl.Position=UDim2.new(0,8,0,4)
    nl.BackgroundTransparency=1; nl.Font=Enum.Font.GothamBold
    nl.TextSize=13; nl.TextColor3=Theme.TextPrimary
    nl.TextStrokeTransparency=0.3; nl.Text=p.Name
    nl.TextXAlignment=Enum.TextXAlignment.Left; nl.ZIndex=2; nl.Parent=bg

    -- role tag
    local rl = Instance.new("TextLabel")
    rl.Size=UDim2.new(1,-10,0,14); rl.Position=UDim2.new(0,8,0,25)
    rl.BackgroundTransparency=1; nl.Font=Enum.Font.GothamBold
    rl.TextSize=11; rl.TextColor3=ROLE_COLOR.Unknown; rl.Text="[?]"
    rl.TextXAlignment=Enum.TextXAlignment.Left; rl.ZIndex=2; rl.Parent=bg; h.roleLbl=rl

    -- health bar bg
    local hpBg = Instance.new("Frame")
    hpBg.Size=UDim2.new(1,-16,0,5); hpBg.Position=UDim2.new(0,8,0,44)
    hpBg.BackgroundColor3=Color3.fromRGB(18,18,35)
    hpBg.BorderSizePixel=0; hpBg.ZIndex=2; hpBg.Parent=bg
    Instance.new("UICorner").Parent=hpBg

    -- health bar fill
    local hpF = Instance.new("Frame")
    hpF.Size=UDim2.new(1,0,1,0); hpF.BackgroundColor3=Theme.Success
    hpF.BorderSizePixel=0; hpF.ZIndex=3; hpF.Parent=hpBg; h.hpFill=hpF
    Instance.new("UICorner").Parent=hpF

    -- distance
    local dl = Instance.new("TextLabel")
    dl.Size=UDim2.new(1,-10,0,12); dl.Position=UDim2.new(0,8,0,54)
    dl.BackgroundTransparency=1; dl.Font=Enum.Font.Gotham
    dl.TextSize=10; dl.TextColor3=Theme.TextSecondary; dl.Text="? m"
    dl.TextXAlignment=Enum.TextXAlignment.Left; dl.ZIndex=2; dl.Parent=bg; h.distLbl=dl

    h.bb = bb

    -- attach to character
    local function attach(char)
        local root = char:WaitForChild("HumanoidRootPart", 8)
        if not root then return end
        bb.Adornee  = root; bb.Parent=root
        sb.Adornee  = char
        hl.Adornee  = char
    end
    local cc = p.CharacterAdded:Connect(function(c) attach(c) end)
    if p.Character then task.spawn(attach, p.Character) end
    h.charConn = cc
    espObjs[p] = h
end

local function removeESP(p)
    local h = espObjs[p]; if not h then return end
    if h.charConn then h.charConn:Disconnect() end
    if h.hl      then h.hl:Destroy() end
    if h.selBox  then h.selBox:Destroy() end
    if h.bb      then h.bb:Destroy() end
    espObjs[p] = nil
end

local function refreshESP()
    for p in pairs(espObjs) do removeESP(p) end
    if not espOn then return end
    for _,p in ipairs(Players:GetPlayers()) do buildESP(p) end
end

-- ESP update loop (no 'continue' — Lua 5.1 compatible)
RS.RenderStepped:Connect(function(dt)
    if espRainbow then rainbowH=(rainbowH+dt*0.10)%1 end
    if not espOn then return end
    local myRoot = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")

    for p,h in pairs(espObjs) do
        local char  = p.Character
        local root  = char and char:FindFirstChild("HumanoidRootPart")
        local hum   = char and char:FindFirstChildOfClass("Humanoid")
        local near  = myRoot and root and
                      (root.Position-myRoot.Position).Magnitude <= espDist
        local ok    = root~=nil and hum~=nil and near

        h.hl.Enabled     = ok and espChams
        h.selBox.Visible = ok and espBoxes
        h.bb.Enabled     = ok and espNames

        if ok then
            local role = getRole(p)
            local col  = espRainbow and Color3.fromHSV(rainbowH,0.9,1)
                         or ROLE_COLOR[role] or ROLE_COLOR.Unknown

            h.bgStroke.Color       = col
            h.selBox.Color3        = col
            h.selBox.SurfaceColor3 = col
            h.hl.FillColor         = col
            h.hl.OutlineColor      = col
            h.roleLbl.TextColor3   = col
            h.roleLbl.Text         = "["..role.."]"

            local ratio = math.clamp(
                hum.Health / math.max(hum.MaxHealth,1), 0, 1)
            h.hpFill.Size = UDim2.new(ratio,0,1,0)
            h.hpFill.BackgroundColor3 =
                ratio>0.6 and Theme.Success or
                ratio>0.3 and Theme.Warning or Theme.Danger

            if myRoot then
                h.distLbl.Text =
                    math.floor((root.Position-myRoot.Position).Magnitude).." m"
            end
        end
    end
end)

Players.PlayerAdded:Connect(function(p)   if espOn   then buildESP(p)  end end)
Players.PlayerRemoving:Connect(removeESP)

-- ── ESP tab ──────────────────────────────────────────────────────────────────
local tESP = win:GetTab("ESP")
ui:CreateLabel(tESP,{Text="👁  PLAYER ESP",Color=Theme.TextAccent,Size=12})
ui:CreateSeparator(tESP)

local togESP=ui:CreateToggle(tESP,{Label="ESP Enabled",Default=espOn,
    OnChange=function(v) espOn=v;cfg:Set("espOn",v);refreshESP() end})

ui:CreateToggle(tESP,{Label="Names / Role / HP / Distance",Default=espNames,
    OnChange=function(v)
        espNames=v;cfg:Set("espNames",v)
        for _,h in pairs(espObjs) do h.bb.Enabled=v end end})

ui:CreateToggle(tESP,{Label="3-D Box Outline",Default=espBoxes,
    OnChange=function(v)
        espBoxes=v;cfg:Set("espBoxes",v)
        for _,h in pairs(espObjs) do h.selBox.Visible=v end end})

ui:CreateToggle(tESP,{Label="Chams (glow through walls)",Default=espChams,
    OnChange=function(v)
        espChams=v;cfg:Set("espChams",v)
        for _,h in pairs(espObjs) do h.hl.Enabled=v end end})

ui:CreateSlider(tESP,{Label="Render Distance",Min=50,Max=2000,Default=espDist,Suffix=" m",
    OnChange=function(v) espDist=v;cfg:Set("espDist",v) end})

ui:CreateToggle(tESP,{Label="Rainbow ESP",Default=espRainbow,
    OnChange=function(v) espRainbow=v;cfg:Set("espRainbow",v) end})

ui:CreateSeparator(tESP)
ui:CreateToggle(tESP,{Label="Role Alert Toast",Default=roleAlertOn,
    OnChange=function(v) roleAlertOn=v;cfg:Set("roleAlert",v) end})
ui:CreateButton(tESP,{Text="🔍 Scan All Roles Now",OnClick=function()
    alerted={}
    for _,p in ipairs(Players:GetPlayers()) do task.spawn(checkAlert,p) end
    showToast("🔍 Scanning","Checking all players…",Theme.Info,3)
end})
ui:CreateSeparator(tESP)
ui:CreateLabel(tESP,{Text="  🔴 Murderer  🔵 Sheriff  🟢 Innocent",Size=11})
refreshESP()

-- ─── 11. Aimbot ──────────────────────────────────────────────────────────────
local aimMode   = cfg:Get("aimMode",  "Lock")
local aimTarget = cfg:Get("aimTarget","Murder")
local aimSmooth = cfg:Get("aimSmooth", 7)
local aimFov    = cfg:Get("aimFov",   110)

local fovCircle; local hasDrawing=pcall(function()
    fovCircle=Drawing.new("Circle")
    fovCircle.Visible=false; fovCircle.Color=Color3.fromRGB(0,235,200)
    fovCircle.Thickness=1.4; fovCircle.Filled=false
end)

local function aimMatches(p)
    local r=getRole(p)
    if aimTarget=="Murder"  then return r=="Murderer" end
    if aimTarget=="Sheriff" then return r=="Sheriff"  end
    return r~="Unknown"
end

local function getAimTarget()
    local best,bestD=nil,math.huge
    local center=Vector2.new(vp.X/2,vp.Y/2)
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=lp and p.Character and aimMatches(p) then
            local root=p.Character:FindFirstChild("HumanoidRootPart")
            if root then
                local sp,on=cam:WorldToViewportPoint(root.Position)
                if on then
                    local d=(Vector2.new(sp.X,sp.Y)-center).Magnitude
                    if d<aimFov and d<bestD then best,bestD=p,d end
                end
            end
        end
    end
    return best
end

-- Silent aim hook (Synapse X / KRNL / similar)
local silentInstalled=false
local function installSilent()
    if silentInstalled then return end
    local ok,mt=pcall(getrawmetatable,game); if not ok then
        showToast("⚠ Silent Aim","Metatable hook unavailable",Theme.Warning,5); return end
    pcall(setreadonly,mt,false)
    local old=mt.__namecall
    mt.__namecall=(type(newcclosure)=="function" and newcclosure or function(f) return f end)(
    function(self,...)
        local method=(type(getnamecallmethod)=="function" and getnamecallmethod()) or ""
        if aimMode=="Silent" and method=="FireServer" and self:IsA("RemoteEvent") then
            local rn=self.Name:lower()
            if rn:find("knife") or rn:find("throw") or rn:find("shoot")
            or rn:find("gun")   or rn:find("hit")   or rn:find("kill") then
                local t=getAimTarget()
                if t then
                    local head=t.Character and t.Character:FindFirstChild("Head")
                    if head then
                        local args={...}
                        for i,v in ipairs(args) do
                            if typeof(v)=="Vector3" then args[i]=head.Position
                            elseif typeof(v)=="CFrame" then args[i]=CFrame.new(head.Position)
                            elseif typeof(v)=="Instance" and v:IsA("BasePart") then args[i]=head end
                        end
                        return old(self,table.unpack(args))
                    end
                end
            end
        end
        return old(self,...)
    end)
    pcall(setreadonly,mt,true); silentInstalled=true
    showToast("✅ Silent Aim","Hook installed.",Theme.Success,3)
end

RS.RenderStepped:Connect(function()
    if hasDrawing and fovCircle then
        fovCircle.Position=Vector2.new(vp.X/2,vp.Y/2)
        fovCircle.Radius  =aimFov
        fovCircle.Visible =aimMode~="Off"
    end
    if aimMode~="Lock" then return end
    local t=getAimTarget(); if not t or not t.Character then return end
    local head=t.Character:FindFirstChild("Head"); if not head then return end
    cam.CFrame=cam.CFrame:Lerp(
        CFrame.lookAt(cam.CFrame.Position,head.Position),
        1/math.max(aimSmooth,1))
end)

local tAim=win:GetTab("Aimbot")
ui:CreateLabel(tAim,{Text="🎯  AIM",Color=Theme.TextAccent,Size=12})
ui:CreateSeparator(tAim)
ui:CreateDropdown(tAim,{Label="Mode",Items={"Off","Lock","Silent"},Default=aimMode,
    OnSelect=function(v)
        aimMode=v;cfg:Set("aimMode",v)
        if v=="Silent" then installSilent() end
        showToast("🎯 Aim",v.." mode active",Theme.Accent,3)
    end})
ui:CreateDropdown(tAim,{Label="Target Filter",Items={"Murder","Sheriff","All"},Default=aimTarget,
    OnSelect=function(v) aimTarget=v;cfg:Set("aimTarget",v) end})
ui:CreateSlider(tAim,{Label="Smoothness",Min=1,Max=30,Default=aimSmooth,
    OnChange=function(v) aimSmooth=v;cfg:Set("aimSmooth",v) end})
ui:CreateSlider(tAim,{Label="FOV Radius",Min=20,Max=400,Default=aimFov,Suffix=" px",
    OnChange=function(v) aimFov=v;cfg:Set("aimFov",v) end})
ui:CreateSeparator(tAim)
ui:CreateLabel(tAim,{Text="  Lock=camera  ·  Silent=remote hook (exec only)",Size=11})

-- ─── 12. Farm ────────────────────────────────────────────────────────────────
local coinFarm  = cfg:Get("coinFarm", false)
local pickGunOn = cfg:Get("pickGun",  true)
local pickStarOn= cfg:Get("pickStar", true)

local farmThread = nil   -- controlled task thread (not Heartbeat)

local function doCoins()
    local root = getRoot()
    if not root then return end
    -- MM2 coins are BaseParts named "Coin" scattered inside the map model.
    -- We scan all workspace descendants and teleport directly onto each one.
    -- Y+0.5 (not Y+2!) so the character HumanoidRootPart actually overlaps
    -- the coin hitbox and the server-side Touched event fires.
    local count = 0
    for _, o in ipairs(workspace:GetDescendants()) do
        if o:IsA("BasePart") then
            local n = o.Name:lower()
            -- Match "Coin", "coin", "GoldCoin", "gold_coin" etc.
            -- Exclude UI / unrelated parts that contain the word.
            if (n == "coin" or n == "goldcoin" or n == "gold_coin"
               or (n:find("coin") and not n:find("coingui") and not n:find("coinui"))) then
                if o.Parent then   -- still exists
                    root.CFrame = CFrame.new(o.Position + Vector3.new(0, 0.5, 0))
                    task.wait(0.10)  -- 100 ms — enough for server touch to register
                    count = count + 1
                end
            end
        end
    end
    return count
end

-- Start the coin-farm loop as a managed task thread, NOT via Heartbeat.
-- Heartbeat would call doCoins (which yields) every frame, creating
-- thousands of concurrent coroutines and flooding the network.
local function startFarmLoop()
    if farmThread then task.cancel(farmThread);farmThread=nil end
    farmThread = task.spawn(function()
        while coinFarm do
            local n = doCoins()
            -- Brief pause between full sweeps
            task.wait(math.max(0.4, n and n*0.12 or 0.4))
        end
        farmThread = nil
    end)
end

local function stopFarmLoop()
    if farmThread then task.cancel(farmThread);farmThread=nil end
end

-- ── Auto Pick Gun — EVENT-BASED (workspace.ChildAdded) ──────────────────────
-- When the Sheriff is killed, MM2 drops the gun as a Tool directly in workspace.
-- We listen for that event and immediately teleport to it.
local function tryPickItem(child, forGun, forStar)
    if not child then return end
    task.wait(0.12)   -- let it fully parent
    if not child.Parent then return end
    local name = child.Name:lower()
    local isGun  = name:find("gun") or name:find("sheriff") or name:find("revolver")
    local isStar = name:find("star") or name:find("badge") or name:find("token")
    if (isGun and forGun) or (isStar and forStar) then
        local root = getRoot(); if not root then return end
        -- Find any BasePart to teleport to
        local handle = child:IsA("BasePart") and child
                    or child:FindFirstChild("Handle")
                    or child:FindFirstChildOfClass("BasePart")
        if not handle then return end
        local label = isGun and "🔫 Gun" or "⭐ Star"
        showToast(label.." detected!","Teleporting to pick up…",Theme.Info,4)
        for attempt = 1, 8 do
            if not child.Parent then break end   -- already picked up
            root.CFrame = CFrame.new(handle.Position+Vector3.new(0,2.5,0))
            task.wait(0.12)
        end
    end
end

-- Global workspace listener (fires immediately when gun/star drops)
workspace.ChildAdded:Connect(function(child)
    if pickGunOn  then task.spawn(tryPickItem, child, true,  false) end
    if pickStarOn then task.spawn(tryPickItem, child, false, true)  end
end)
-- Also scan descendants (some MM2 versions put the drop inside a model)
workspace.DescendantAdded:Connect(function(desc)
    if not (desc:IsA("Tool") or desc:IsA("BasePart")) then return end
    if pickGunOn  then task.spawn(tryPickItem, desc.Parent or desc, true,  false) end
    if pickStarOn then task.spawn(tryPickItem, desc.Parent or desc, false, true)  end
end)

-- Start coin loop if enabled at load time
if coinFarm then startFarmLoop() end

local safeConn
local function doSafes()
    local root=getRoot(); if not root then return end
    for _,o in ipairs(workspace:GetDescendants()) do
        if o:IsA("BasePart") and o.Name:lower():find("safe") then
            root.CFrame=CFrame.new(o.Position+Vector3.new(0,2,0))
            task.wait(0.08)
        end
    end
end

local tFarm=win:GetTab("Farm")
ui:CreateLabel(tFarm,{Text="💰  FARM",Color=Theme.TextAccent,Size=12})
ui:CreateSeparator(tFarm)

ui:CreateToggle(tFarm,{Label="Auto Coin Collect",Default=coinFarm,
    OnChange=function(v)
        coinFarm=v;cfg:Set("coinFarm",v)
        if v then startFarmLoop() else stopFarmLoop() end
    end})
ui:CreateButton(tFarm,{Text="⚡ Collect All Coins Once",Primary=false,
    OnClick=function() task.spawn(doCoins) end})

ui:CreateSeparator(tFarm)
ui:CreateLabel(tFarm,{Text="🔫  AUTO PICK-UP",Color=Theme.TextAccent,Size=12})
ui:CreateSeparator(tFarm)

ui:CreateToggle(tFarm,{Label="Auto Pick Dropped Sheriff Gun",Default=pickGunOn,
    OnChange=function(v) pickGunOn=v;cfg:Set("pickGun",v) end})
ui:CreateToggle(tFarm,{Label="Auto Collect Sheriff Star",Default=pickStarOn,
    OnChange=function(v) pickStarOn=v;cfg:Set("pickStar",v) end})

-- Manual search buttons
ui:CreateButton(tFarm,{Text="🔫 Grab Gun in Workspace Now",Primary=false,
    OnClick=function()
        local root=getRoot(); if not root then return end
        for _,o in ipairs(workspace:GetDescendants()) do
            if o:IsA("Tool") or (o:IsA("BasePart") and
               (o.Name:lower():find("gun") or o.Name:lower():find("sheriff"))) then
                task.spawn(tryPickItem, o:IsA("Tool") and o or o.Parent, true, false)
                return
            end
        end
        showToast("🔍 Not Found","No gun found in workspace.",Theme.Warning,3)
    end})

ui:CreateSeparator(tFarm)
ui:CreateLabel(tFarm,{Text="🔐  SAFES",Color=Theme.TextAccent,Size=12})
ui:CreateSeparator(tFarm)

ui:CreateToggle(tFarm,{Label="Auto Open Safes",Default=false,
    OnChange=function(v)
        if safeConn then safeConn:Disconnect();safeConn=nil end
        if not v then return end
        safeConn=RS.Heartbeat:Connect(function()
            task.spawn(doSafes); task.wait(1) end) end})

-- ─── 13. Combat ──────────────────────────────────────────────────────────────
local killAura  = cfg:Get("killAura",  false)
local auraRange = cfg:Get("auraRange",  12)
local knifeReach= cfg:Get("knifeReach",false)
local killCount = 0

local auraConn, reachConn

local function setKillAura(on)
    if auraConn then auraConn:Disconnect();auraConn=nil end
    if not on then return end
    auraConn=RS.Heartbeat:Connect(function()
        local root=getRoot(); if not root then return end
        local char=lp.Character; if not char then return end
        local hasTool=false
        for _,t in ipairs(char:GetChildren()) do
            if t:IsA("Tool") then hasTool=true;break end end
        if not hasTool then return end
        for _,p in ipairs(Players:GetPlayers()) do
            if p~=lp and p.Character then
                local pr=p.Character:FindFirstChild("HumanoidRootPart")
                if pr and (root.Position-pr.Position).Magnitude<=auraRange then
                    root.CFrame=CFrame.new(pr.Position+Vector3.new(0,1,0))
                    task.wait(0.05)
                end
            end
        end
    end)
end

local function setReach(on)
    if reachConn then reachConn:Disconnect();reachConn=nil end
    if not on then return end
    reachConn=RS.Heartbeat:Connect(function()
        local char=lp.Character; if not char then return end
        for _,t in ipairs(char:GetChildren()) do
            if t:IsA("Tool") and t.Name:lower():find("knife") then
                local rv=t:FindFirstChild("Range") or t:FindFirstChild("range")
                if rv and rv:IsA("NumberValue") then rv.Value=18 end
            end
        end
    end)
end

local tCombat=win:GetTab("Combat")
ui:CreateLabel(tCombat,{Text="⚔  COMBAT",Color=Theme.TextAccent,Size=12})
ui:CreateSeparator(tCombat)

ui:CreateToggle(tCombat,{Label="Kill Aura (TP onto targets)",Default=killAura,
    OnChange=function(v) killAura=v;cfg:Set("killAura",v);setKillAura(v) end})
ui:CreateSlider(tCombat,{Label="Aura Range",Min=4,Max=40,Default=auraRange,Suffix=" st",
    OnChange=function(v) auraRange=v;cfg:Set("auraRange",v) end})
ui:CreateToggle(tCombat,{Label="Knife Reach Extend (×3)",Default=knifeReach,
    OnChange=function(v) knifeReach=v;cfg:Set("knifeReach",v);setReach(v) end})

ui:CreateSeparator(tCombat)
ui:CreateLabel(tCombat,{Text="🎭  ROLE TOOLS",Color=Theme.TextAccent,Size=12})
ui:CreateSeparator(tCombat)

ui:CreateButton(tCombat,{Text="🔪 Equip Role Tool",OnClick=function()
    local char=lp.Character; if not char then return end
    local role=getRole(lp)
    local name=role=="Murderer" and "Knife" or role=="Sheriff" and "Sheriff's Gun" or nil
    if not name then showToast("⚠","You are Innocent.",Theme.Warning,3);return end
    local hum=char:FindFirstChildOfClass("Humanoid")
    local bp=lp:FindFirstChild("Backpack")
    local tool=(bp and bp:FindFirstChild(name)) or char:FindFirstChild(name)
    if tool and hum then
        hum:EquipTool(tool)
        showToast("✅ Equipped",name,Theme.Success,3)
    else
        showToast("⚠ Not Found","Tool '"..name.."' not in backpack.",Theme.Warning,4)
    end
end})

ui:CreateButton(tCombat,{Text="📍 TP to Murderer",Primary=false,OnClick=function()
    for _,p in ipairs(Players:GetPlayers()) do
        if getRole(p)=="Murderer" and p.Character then
            local pr=p.Character:FindFirstChild("HumanoidRootPart")
            local root=getRoot()
            if pr and root then
                root.CFrame=CFrame.new(pr.Position+Vector3.new(4,2,4))
                showToast("📍 TP","→ "..p.Name,Theme.Accent,3);return
            end
        end
    end
    showToast("⚠ Not found","No Murderer detected yet.",Theme.Warning,3)
end})
ui:CreateButton(tCombat,{Text="⭐ TP to Sheriff",Primary=false,OnClick=function()
    for _,p in ipairs(Players:GetPlayers()) do
        if getRole(p)=="Sheriff" and p.Character then
            local pr=p.Character:FindFirstChild("HumanoidRootPart")
            local root=getRoot()
            if pr and root then
                root.CFrame=CFrame.new(pr.Position+Vector3.new(4,2,4))
                showToast("⭐ TP","→ "..p.Name,Theme.Info,3);return
            end
        end
    end
    showToast("⚠ Not found","No Sheriff detected yet.",Theme.Warning,3)
end})

-- Kill counter (watch for other players dying near local player)
local killDisplay
ui:CreateSeparator(tCombat)
ui:CreateLabel(tCombat,{Text="📊  SESSION STATS",Color=Theme.TextAccent,Size=12})
ui:CreateSeparator(tCombat)
killDisplay=ui:CreateLabel(tCombat,{Text="  Kills this session: 0",Size=12})

local function trackKills()
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=lp and p.Character then
            local hum=p.Character:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.Died:Connect(function()
                    local root=getRoot();local pr=p.Character:FindFirstChild("HumanoidRootPart")
                    if root and pr and (root.Position-pr.Position).Magnitude<=20 then
                        killCount=killCount+1
                        if killDisplay then
                            killDisplay:Set("  Kills this session: "..killCount) end
                        showToast("💀 Kill","+"..killCount.." total",Theme.Danger,3)
                    end
                end)
            end
        end
    end
end
for _,p in ipairs(Players:GetPlayers()) do task.spawn(function()
    if p.Character then trackKills() end
    p.CharacterAdded:Connect(function() task.wait(1);trackKills() end)
end) end
Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function() task.wait(1);trackKills() end) end)

-- ─── 14. Player ──────────────────────────────────────────────────────────────
local setNoclip, setFly   -- forward declarations

local function applyStats()
    local h=getHum(); if not h then return end
    h.WalkSpeed=cfg:Get("walkSpeed",16)
    h.JumpPower=cfg:Get("jumpPower",50)
end
lp.CharacterAdded:Connect(function(c)
    local h=c:WaitForChild("Humanoid",8)
    if h then
        h.WalkSpeed=cfg:Get("walkSpeed",16)
        h.JumpPower=cfg:Get("jumpPower",50)
    end
    if cfg:Get("noclip",false) and setNoclip then setNoclip(true) end
    if cfg:Get("fly",false)    and setFly    then task.delay(0.5,function() setFly(true) end) end
end)
applyStats()

-- Noclip
local noclipConn
setNoclip = function(on)
    if noclipConn then noclipConn:Disconnect();noclipConn=nil end
    if on then
        noclipConn=RS.Stepped:Connect(function()
            local char=lp.Character; if not char then return end
            for _,p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide=false end end end)
    else
        local char=lp.Character
        if char then for _,p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide=true end end end
    end
end

-- Fly
local flyOn,flyBody,flyConn=false,nil,nil
setFly = function(on)
    flyOn=on
    if flyConn then flyConn:Disconnect();flyConn=nil end
    if flyBody and flyBody.Parent then flyBody:Destroy();flyBody=nil end
    local root=getRoot();local hum=getHum()
    if not(root and hum) then return end
    if on then
        hum.PlatformStand=true
        flyBody=Instance.new("BodyVelocity")
        flyBody.Velocity=Vector3.zero
        flyBody.MaxForce=Vector3.new(1e5,1e5,1e5)
        flyBody.Name="NexusFly"; flyBody.Parent=root
        flyConn=RS.Heartbeat:Connect(function()
            if not flyOn or not flyBody or not flyBody.Parent then
                if flyConn then flyConn:Disconnect();flyConn=nil end;return end
            local d=Vector3.zero;local cf=cam.CFrame
            if UIS:IsKeyDown(Enum.KeyCode.W) then d=d+cf.LookVector  end
            if UIS:IsKeyDown(Enum.KeyCode.S) then d=d-cf.LookVector  end
            if UIS:IsKeyDown(Enum.KeyCode.A) then d=d-cf.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.D) then d=d+cf.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.Space)     then d=d+Vector3.new(0,1,0) end
            if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then d=d-Vector3.new(0,1,0) end
            flyBody.Velocity=d.Magnitude>0 and d.Unit*42 or Vector3.zero
        end)
    else
        if hum then hum.PlatformStand=false end
    end
end

-- Infinite jump
local infJump=cfg:Get("infJump",false)
UIS.JumpRequest:Connect(function()
    if not infJump then return end
    local hum=getHum()
    if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
end)

-- Infinite stamina (keep WalkSpeed high so sprint never drains)
local infStamConn
local function setInfStam(on)
    if infStamConn then infStamConn:Disconnect();infStamConn=nil end
    if not on then return end
    infStamConn=RS.Heartbeat:Connect(function()
        local hum=getHum(); if not hum then return end
        -- MM2 uses a Stamina value; keep it at max
        local sv=hum:FindFirstChild("Stamina") or lp.Character:FindFirstChild("Stamina")
        if sv and sv:IsA("NumberValue") then sv.Value=sv.Value>=99 and sv.Value or 100 end
    end)
end

-- Anti-AFK
local afkConn
local function setAntiAfk(on)
    if afkConn then afkConn:Disconnect();afkConn=nil end
    if not on then return end
    local t=0
    afkConn=RS.Heartbeat:Connect(function(dt)
        t=t+dt
        if t>=55 then t=0
            local hum=getHum()
            if hum then hum:Move(Vector3.new(0,0,-1),true) end
            task.wait(0.1)
            if hum then hum:Move(Vector3.zero,true) end
        end
    end)
end

-- Anti-Void
local safePos=nil; local antiVoidOn=cfg:Get("antiVoid",true)
local savePosConn
local function startAntiVoid()
    if savePosConn then savePosConn:Disconnect();savePosConn=nil end
    if not antiVoidOn then return end
    savePosConn=RS.Heartbeat:Connect(function()
        local root=getRoot(); if not root then return end
        -- Save position if above the kill plane (Y > 0)
        if root.Position.Y>10 then
            safePos=root.CFrame
        elseif safePos and root.Position.Y<-60 then
            -- Fell into void — teleport back
            root.CFrame=safePos
            showToast("🛡 Anti-Void","Teleported back!",Theme.Warning,4)
        end
    end)
end
startAntiVoid()

-- Save / load position
local savedCF=nil
local function savePos()
    local root=getRoot(); if not root then return end
    savedCF=root.CFrame
    showToast("📌 Position Saved","CFrame stored.",Theme.Success,3)
end
local function loadPos()
    if not savedCF then showToast("⚠","No position saved.",Theme.Warning,3);return end
    local root=getRoot(); if not root then return end
    root.CFrame=savedCF
    showToast("📌 Position Loaded","Teleported to saved spot.",Theme.Info,3)
end

-- Player tab
local tPlayer=win:GetTab("Player")
ui:CreateLabel(tPlayer,{Text="🏃  MOVEMENT",Color=Theme.TextAccent,Size=12})
ui:CreateSeparator(tPlayer)

local slSpeed=ui:CreateSlider(tPlayer,{Label="Walk Speed",Min=4,Max=150,
    Default=cfg:Get("walkSpeed",16),
    OnChange=function(v) cfg:Set("walkSpeed",v);local h=getHum();if h then h.WalkSpeed=v end end})

local slJump=ui:CreateSlider(tPlayer,{Label="Jump Power",Min=7,Max=300,
    Default=cfg:Get("jumpPower",50),
    OnChange=function(v) cfg:Set("jumpPower",v);local h=getHum();if h then h.JumpPower=v end end})

ui:CreateSeparator(tPlayer)
ui:CreateLabel(tPlayer,{Text="✈  SPECIAL",Color=Theme.TextAccent,Size=12})
ui:CreateSeparator(tPlayer)

ui:CreateToggle(tPlayer,{Label="Noclip",Default=cfg:Get("noclip",false),
    OnChange=function(v) cfg:Set("noclip",v);setNoclip(v) end})
ui:CreateToggle(tPlayer,{Label="Fly  (WASD + Space / Shift)",Default=cfg:Get("fly",false),
    OnChange=function(v) cfg:Set("fly",v);setFly(v) end})
ui:CreateToggle(tPlayer,{Label="Infinite Jump",Default=infJump,
    OnChange=function(v) infJump=v;cfg:Set("infJump",v) end})
ui:CreateToggle(tPlayer,{Label="Infinite Stamina",Default=cfg:Get("infStamina",false),
    OnChange=function(v) cfg:Set("infStamina",v);setInfStam(v) end})
ui:CreateToggle(tPlayer,{Label="Anti-AFK",Default=cfg:Get("antiAfk",false),
    OnChange=function(v) cfg:Set("antiAfk",v);setAntiAfk(v) end})
ui:CreateToggle(tPlayer,{Label="Anti-Void",Default=antiVoidOn,
    OnChange=function(v) antiVoidOn=v;cfg:Set("antiVoid",v);startAntiVoid() end})

ui:CreateSeparator(tPlayer)
ui:CreateButton(tPlayer,{Text="📌 Save Position",  OnClick=savePos})
ui:CreateButton(tPlayer,{Text="📌 Load Position",Primary=false,OnClick=loadPos})
ui:CreateButton(tPlayer,{Text="🔄 Reset Character",Primary=false,
    OnClick=function() local h=getHum();if h then h.Health=0 end end})

-- ─── 15. Visual / Lighting tab ───────────────────────────────────────────────
local LIGHTING_BG = {}   -- store original lighting values
local nexusEffects={}    -- track inserted effects for cleanup

local function clearNexusEffects()
    for _,e in ipairs(nexusEffects) do pcall(function() e:Destroy() end) end
    nexusEffects={}
end

local function addEffect(class, props)
    local e=Instance.new(class)
    for k,v in pairs(props) do e[k]=v end
    e.Parent=Lighting; table.insert(nexusEffects,e); return e
end

local function applyPreset(name)
    clearNexusEffects()
    if name=="Aurora" then
        Lighting.ClockTime=0.5; Lighting.Brightness=0.28
        Lighting.FogEnd=1e6
        Lighting.Ambient=Color3.fromRGB(0,18,30)
        Lighting.OutdoorAmbient=Color3.fromRGB(0,12,22)
        addEffect("BloomEffect",{Name="NexusBloom",Intensity=1.4,Size=36,Threshold=0.82})
        addEffect("ColorCorrectionEffect",{
            Name="NexusCC",Saturation=0.45,Contrast=0.12,
            TintColor=Color3.fromRGB(0,210,175),Brightness=-0.04})
        showToast("🌌 Aurora Sky","Deep aurora lighting active",Theme.Accent,5)

    elseif name=="Night" then
        Lighting.ClockTime=0; Lighting.Brightness=0.45
        Lighting.FogEnd=1e6
        Lighting.Ambient=Color3.fromRGB(18,18,30)
        Lighting.OutdoorAmbient=Color3.fromRGB(12,12,22)
        addEffect("BloomEffect",{Name="NexusBloom",Intensity=0.6,Size=18,Threshold=0.9})
        showToast("🌙 Night","Night lighting applied.",Theme.Info,4)

    elseif name=="Day" then
        Lighting.ClockTime=14; Lighting.Brightness=2
        Lighting.FogEnd=1e6
        Lighting.Ambient=Color3.fromRGB(120,120,120)
        Lighting.OutdoorAmbient=Color3.fromRGB(120,120,120)
        showToast("☀ Day","Daytime lighting applied.",Theme.Warning,4)

    elseif name=="Sunset" then
        Lighting.ClockTime=19; Lighting.Brightness=1.5
        Lighting.FogEnd=600
        Lighting.FogColor=Color3.fromRGB(255,125,60)
        Lighting.Ambient=Color3.fromRGB(150,80,45)
        Lighting.OutdoorAmbient=Color3.fromRGB(130,65,35)
        addEffect("ColorCorrectionEffect",{
            Name="NexusCC",TintColor=Color3.fromRGB(255,160,80),Saturation=0.3})
        showToast("🌅 Sunset","Sunset lighting applied.",Color3.fromRGB(255,130,60),4)

    elseif name=="Horror" then
        Lighting.ClockTime=0; Lighting.Brightness=0.15
        Lighting.FogEnd=80; Lighting.FogColor=Color3.fromRGB(10,0,0)
        Lighting.Ambient=Color3.fromRGB(30,0,0)
        Lighting.OutdoorAmbient=Color3.fromRGB(20,0,0)
        addEffect("BlurEffect",{Name="NexusBlur",Size=4})
        addEffect("ColorCorrectionEffect",{
            Name="NexusCC",TintColor=Color3.fromRGB(180,0,0),Saturation=0.5,Contrast=0.2})
        showToast("👁 Horror","Horror mode enabled.",Theme.Danger,4)

    elseif name=="Default" then
        Lighting.ClockTime=14;  Lighting.Brightness=2
        Lighting.FogEnd=100000; Lighting.FogColor=Color3.fromRGB(191,197,203)
        Lighting.Ambient=Color3.fromRGB(0,0,0)
        Lighting.OutdoorAmbient=Color3.fromRGB(128,128,128)
        showToast("↺ Default","Lighting restored.",Theme.TextSecondary,3)
    end
end

-- Crosshair (Drawing API)
local crossLines={}
local function setCrosshair(on)
    for _,l in ipairs(crossLines) do pcall(function() l:Remove() end) end
    crossLines={}
    if not on then return end
    local ok=pcall(function()
        local cx,cy=vp.X/2,vp.Y/2
        local sz,gap=11,5
        local col=Color3.fromRGB(0,235,200)
        local function line(x1,y1,x2,y2)
            local l=Drawing.new("Line")
            l.From=Vector2.new(x1,y1);l.To=Vector2.new(x2,y2)
            l.Color=col;l.Thickness=1.6;l.Visible=true
            table.insert(crossLines,l)
        end
        line(cx-sz-gap,cy,cx-gap,cy); line(cx+gap,cy,cx+sz+gap,cy)
        line(cx,cy-sz-gap,cx,cy-gap); line(cx,cy+gap,cx,cy+sz+gap)
        local d=Drawing.new("Circle"); d.Position=Vector2.new(cx,cy)
        d.Radius=1.5; d.Color=col; d.Filled=true; d.Visible=true
        table.insert(crossLines,d)
    end)
    if not ok then showToast("⚠ Crosshair","Drawing API unavailable.",Theme.Warning,4) end
end

local tVis=win:GetTab("Visual")
ui:CreateLabel(tVis,{Text="🌌  AURORA SKY  ·  LIGHTING",Color=Theme.TextAccent,Size=12})
ui:CreateSeparator(tVis)
ui:CreateDropdown(tVis,{
    Label="Lighting Preset",
    Items={"Default","Aurora","Night","Day","Sunset","Horror"},
    Default=cfg:Get("lightPreset","Default"),
    OnSelect=function(v)
        cfg:Set("lightPreset",v);applyPreset(v) end})

ui:CreateSeparator(tVis)
ui:CreateLabel(tVis,{Text="💡  EFFECTS",Color=Theme.TextAccent,Size=12})
ui:CreateSeparator(tVis)

-- No fog
local noFogConn
ui:CreateToggle(tVis,{Label="No Fog (max render distance)",Default=cfg:Get("noFog",false),
    OnChange=function(v)
        cfg:Set("noFog",v)
        if noFogConn then noFogConn:Disconnect();noFogConn=nil end
        if v then
            Lighting.FogEnd=1e6
            noFogConn=RS.Heartbeat:Connect(function() Lighting.FogEnd=1e6 end)
        end
    end})

-- Bloom toggle
local bloomInst
ui:CreateToggle(tVis,{Label="Bloom Effect",Default=false,
    OnChange=function(v)
        if not v then
            if bloomInst then bloomInst:Destroy();bloomInst=nil end;return end
        bloomInst=Instance.new("BloomEffect")
        bloomInst.Name="NexusBloomManual"; bloomInst.Intensity=1.0
        bloomInst.Size=28; bloomInst.Threshold=0.85; bloomInst.Parent=Lighting
    end})

-- ColorCorrection saturation boost
local ccInst
ui:CreateToggle(tVis,{Label="Vivid Colours (+Saturation)",Default=false,
    OnChange=function(v)
        if not v then if ccInst then ccInst:Destroy();ccInst=nil end;return end
        ccInst=Instance.new("ColorCorrectionEffect")
        ccInst.Name="NexusCCManual"; ccInst.Saturation=0.35
        ccInst.Contrast=0.08; ccInst.Parent=Lighting
    end})

ui:CreateSeparator(tVis)
ui:CreateLabel(tVis,{Text="⚙  CAMERA",Color=Theme.TextAccent,Size=12})
ui:CreateSeparator(tVis)

-- Custom FOV
ui:CreateSlider(tVis,{Label="Field of View",Min=30,Max=120,
    Default=cfg:Get("customFov",70),Suffix="°",
    OnChange=function(v)
        cfg:Set("customFov",v)
        cam.FieldOfView=v
    end})

ui:CreateToggle(tVis,{Label="Custom Crosshair (aurora teal)",Default=cfg:Get("crosshair",false),
    OnChange=function(v) cfg:Set("crosshair",v);setCrosshair(v) end})

ui:CreateSeparator(tVis)
ui:CreateButton(tVis,{Text="🌌 Apply Aurora Now",
    OnClick=function() applyPreset("Aurora") end})
ui:CreateButton(tVis,{Text="↺ Reset Lighting",Primary=false,
    OnClick=function() clearNexusEffects();applyPreset("Default") end})

-- Apply saved preset on load
if cfg:Get("lightPreset","Default")~="Default" then
    task.delay(1,function() applyPreset(cfg:Get("lightPreset","Default")) end)
end

-- ─── 16. Settings ────────────────────────────────────────────────────────────
local tSet=win:GetTab("Settings")
ui:CreateLabel(tSet,{Text="⚙  CONFIG",Color=Theme.TextAccent,Size=12})
ui:CreateSeparator(tSet)

ui:CreateButton(tSet,{Text="💾 Save Config",OnClick=function()
    cfg:Save()
    showToast("💾 Saved","Config written to file.",Theme.Success,3)
end})
ui:CreateButton(tSet,{Text="📂 Load Config",Primary=false,OnClick=function()
    cfg:Load()
    showToast("📂 Loaded","Config read from file.",Theme.Info,3)
end})

ui:CreateSeparator(tSet)
ui:CreateLabel(tSet,{Text="💬  CHAT SPY",Color=Theme.TextAccent,Size=12})
ui:CreateSeparator(tSet)

local spyConns={}
ui:CreateToggle(tSet,{Label="Chat Spy (prints to console)",Default=cfg:Get("chatSpy",false),
    OnChange=function(v)
        for _,c in ipairs(spyConns) do c:Disconnect() end;spyConns={}
        cfg:Set("chatSpy",v); if not v then return end
        for _,p in ipairs(Players:GetPlayers()) do
            if p~=lp then
                local c=p.Chatted:Connect(function(msg)
                    print("[ChatSpy] "..p.Name..": "..msg) end)
                table.insert(spyConns,c)
            end
        end
        local ac=Players.PlayerAdded:Connect(function(p)
            if p==lp then return end
            local c=p.Chatted:Connect(function(msg)
                print("[ChatSpy] "..p.Name..": "..msg) end)
            table.insert(spyConns,c)
        end)
        table.insert(spyConns,ac)
    end})

ui:CreateSeparator(tSet)
ui:CreateLabel(tSet,{Text="🌐  SERVER",Color=Theme.TextAccent,Size=12})
ui:CreateSeparator(tSet)

local function srvStr()
    return ("Players: %d/%d  ·  Job: %s…"):format(
        #Players:GetPlayers(),Players.MaxPlayers,game.JobId:sub(1,8))
end
local srvLbl=ui:CreateLabel(tSet,{Text=srvStr(),Size=11})
ui:CreateButton(tSet,{Text="↺ Refresh",Primary=false,
    OnClick=function() srvLbl:Set(srvStr()) end})
ui:CreateButton(tSet,{Text="🔄 Rejoin Same Server",Primary=false,OnClick=function()
    pcall(function()
        game:GetService("TeleportService"):TeleportToPlaceInstance(
            game.PlaceId,game.JobId,lp)
    end)
end})
ui:CreateButton(tSet,{Text="🌍 New Server",Primary=false,OnClick=function()
    pcall(function()
        game:GetService("TeleportService"):Teleport(game.PlaceId,lp)
    end)
end})

ui:CreateSeparator(tSet)
if not isMobile then
    ui:CreateLabel(tSet,{Text="⌨  RightShift → toggle menu"})
else
    ui:CreateLabel(tSet,{Text="📱  Tap ☰ button → toggle menu"})
end
ui:CreateLabel(tSet,{Text="  NexusUI  Aurora Edition  v3.0",Size=10})

-- ─── 17. Mobile toggle button ────────────────────────────────────────────────
if isMobile then
    local btnGui=Instance.new("ScreenGui")
    btnGui.Name="NexusMM2ToggleV3"; btnGui.ResetOnSpawn=false
    btnGui.DisplayOrder=1000; btnGui.IgnoreGuiInset=true; btnGui.Parent=getSecure()
    local mb=Instance.new("TextButton")
    mb.Size=UDim2.new(0,56,0,56); mb.Position=UDim2.new(1,-68,1,-80)
    mb.BackgroundColor3=Theme.Accent; mb.BorderSizePixel=0
    mb.Font=Theme.FontBody; mb.TextSize=24; mb.Text="☰"
    mb.TextColor3=Color3.fromRGB(4,4,16); mb.AutoButtonColor=false
    mb.ZIndex=1; mb.Parent=btnGui
    local mbC=Instance.new("UICorner"); mbC.CornerRadius=UDim.new(1,0); mbC.Parent=mb
    local mbS=Instance.new("UIStroke"); mbS.Color=Theme.AccentLight; mbS.Thickness=1.5; mbS.Parent=mb
    Drag.makeDraggable(mb,mb)
    mb.MouseButton1Click:Connect(function()
        guiOpen=not guiOpen
        if guiOpen then
            win.Instance.Visible=true
            Tween.openWindow(win.Instance,UDim2.new(0,winW,0,winH)); mb.Text="✕"
        else
            Tween.closeWindow(win.Instance); mb.Text="☰"
        end
    end)
end

-- ─── 18. Desktop keybind ─────────────────────────────────────────────────────
if not isMobile then
    UIS.InputBegan:Connect(function(inp,gp)
        if gp then return end
        if inp.KeyCode==Enum.KeyCode.RightShift then
            guiOpen=not guiOpen
            if guiOpen then
                win.Instance.Visible=true
                Tween.openWindow(win.Instance,UDim2.new(0,winW,0,winH))
            else
                Tween.closeWindow(win.Instance)
            end
        end
    end)
end

-- ─── 19. Periodic save + cleanup ─────────────────────────────────────────────
cfg:StartPeriodicSave(60)
lp.CharacterRemoving:Connect(function() cfg:Save() end)

showToast("✦ NexusUI  Aurora v3.0","Loaded! "
    ..(isMobile and "Tap ☰ to toggle." or "RightShift to toggle."),
    Theme.Accent, 5)

print("╔═══════════════════════════════════╗")
print("║  NexusUI MM2  Aurora v3.0  ✓      ║")
print("║  RightShift / ☰  →  toggle        ║")
print("╚═══════════════════════════════════╝")
