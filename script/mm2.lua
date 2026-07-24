--[[
╔══════════════════════════════════════════════════════════════════════════════╗
║         NexusUI  ·  Murder Mystery 2  ·  v2.0                              ║
╠══════════════════════════════════════════════════════════════════════════════╣
║  TABS                                                                       ║
║  ESP     — SelectionBox glow, billboard (name/role/HP/dist), rainbow mode  ║
║  Aimbot  — Lock Aim (camera) + Silent Aim (remote hook) + FOV circle       ║
║  Farm    — Coin farm, safe farm, auto pick dropped gun                     ║
║  Combat  — Kill aura, knife reach extend, auto-equip role tool             ║
║  Player  — Speed, jump, noclip, fly, infinite jump, anti-afk, crosshair   ║
║  Settings— Config save/load, keybind info, reset                           ║
╠══════════════════════════════════════════════════════════════════════════════╣
║  ONE-LINER:                                                                 ║
║  loadstring(game:HttpGet(                                                   ║
║    "https://raw.githubusercontent.com/mikolaq1111/nexusui/main/script/mm2.lua" ║
║  ))()                                                                       ║
╚══════════════════════════════════════════════════════════════════════════════╝
--]]

-- ─── 1. Loader ───────────────────────────────────────────────────────────────
local RAW = "https://raw.githubusercontent.com/mikolaq1111/nexusui/main/"
local function loadMod(path)
    local ok, src = pcall(game.HttpGet, game, RAW..path, true)
    if not ok then error("[MM2] HTTP: "..path.."\n"..tostring(src)) end
    local fn, e = loadstring(src)
    if not fn then error("[MM2] Parse: "..path.."\n"..tostring(e)) end
    return fn()
end
print("[MM2] Loading NexusUI v2.0 …")
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
local lp         = Players.LocalPlayer
local cam        = workspace.CurrentCamera

-- ─── 3. Helpers ──────────────────────────────────────────────────────────────
local function getSecureParent()
    if type(gethui) == "function" then return gethui() end
    local ok, cg = pcall(function() return game:GetService("CoreGui") end)
    if ok then return cg end
    return lp.PlayerGui
end

local isMobile = UIS.TouchEnabled and not UIS.MouseEnabled
local vp       = cam and cam.ViewportSize or Vector2.new(800,600)
local winW     = math.min(math.floor(vp.X*0.96), 440)
local winH     = math.min(math.floor(vp.Y*0.90), 540)

local function getHum()
    local c = lp.Character; return c and c:FindFirstChildOfClass("Humanoid")
end
local function getRoot()
    local c = lp.Character; return c and c:FindFirstChild("HumanoidRootPart")
end

-- ─── 4. Inline Library ───────────────────────────────────────────────────────
local Library = {}; Library.__index = Library
function Library.new()
    local self = setmetatable({}, Library)
    self.Theme, self._plugins, self._windows = setmetatable({},{__index=Theme}), nil, {}
    local sg = Instance.new("ScreenGui")
    sg.Name="NexusMM2_"..math.random(1e3,9e3); sg.ResetOnSpawn=false
    sg.ZIndexBehavior=Enum.ZIndexBehavior.Sibling; sg.DisplayOrder=999
    sg.IgnoreGuiInset=true; sg.Parent=getSecureParent()
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

local cfg=Plugins.newConfig("nexus/mm2v2.json",{
    espOn=true,espNames=true,espBoxes=true,espDist=600,espRainbow=false,
    aimMode="Lock",     -- "Lock" | "Silent" | "Off"
    aimTarget="Murder", -- "Murder" | "Sheriff" | "All"
    aimSmooth=7,aimFov=100,
    coinFarm=false,pickGun=false,
    killAura=false,auraRange=12,knifeReach=false,
    walkSpeed=16,jumpPower=50,noclip=false,fly=false,
    infJump=false,antiAfk=false,crosshair=false,
    roleAlert=true,
})

-- ─── 6. UI window ────────────────────────────────────────────────────────────
local ui=Library.new(); ui:SetPlugins(Plugins)
local guiOpen=true

local win=ui:CreateWindow({
    Title="⚔  NexusUI  ·  MM2  v2.0",
    Size=UDim2.new(0,winW,0,winH),
    Position=UDim2.new(0.5,-winW/2,0.5,-winH/2),
    CanClose=true,CanMinimise=true,
    Tabs={"ESP","Aimbot","Farm","Combat","Player","Settings"},
})
cfg:RestoreWindowPosition("mm2v2",win.Instance)
local tb=win.Instance:FindFirstChild("TitleBar")
if tb then tb.InputEnded:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1
    or i.UserInputType==Enum.UserInputType.Touch then
        cfg:SaveWindowPosition("mm2v2",win.Instance) end end) end

-- ─── 7. Toast notification system ────────────────────────────────────────────
local toastGui=Instance.new("ScreenGui")
toastGui.Name="NexusToast"; toastGui.ResetOnSpawn=false
toastGui.DisplayOrder=2000; toastGui.IgnoreGuiInset=true
toastGui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
toastGui.Parent=getSecureParent()

local toastY=10   -- stacking offset
local function showToast(title,body,color,duration)
    color=color or Theme.Accent; duration=duration or 5
    local h=82
    local fr=Instance.new("Frame")
    fr.Size=UDim2.new(0,310,0,h)
    fr.Position=UDim2.new(1,10,0,toastY)   -- starts off-screen right
    fr.BackgroundColor3=Color3.fromRGB(10,10,22)
    fr.BackgroundTransparency=0.06
    fr.BorderSizePixel=0; fr.ZIndex=1; fr.Parent=toastGui
    toastY=toastY+h+6
    local cr=Instance.new("UICorner"); cr.CornerRadius=UDim.new(0,10); cr.Parent=fr
    local sk=Instance.new("UIStroke"); sk.Color=color; sk.Thickness=1.5; sk.Parent=fr
    -- colour bar
    local bar=Instance.new("Frame"); bar.Size=UDim2.new(0,4,1,0)
    bar.BackgroundColor3=color; bar.BorderSizePixel=0; bar.ZIndex=2; bar.Parent=fr
    local bc=Instance.new("UICorner"); bc.CornerRadius=UDim.new(0,4); bc.Parent=bar
    -- title
    local tl=Instance.new("TextLabel")
    tl.Size=UDim2.new(1,-18,0,24); tl.Position=UDim2.new(0,14,0,8)
    tl.BackgroundTransparency=1; tl.Font=Enum.Font.GothamBold
    tl.TextSize=13; tl.TextColor3=color; tl.Text=title
    tl.TextXAlignment=Enum.TextXAlignment.Left; tl.ZIndex=2; tl.Parent=fr
    -- body
    local bl=Instance.new("TextLabel")
    bl.Size=UDim2.new(1,-18,0,36); bl.Position=UDim2.new(0,14,0,32)
    bl.BackgroundTransparency=1; bl.Font=Enum.Font.Gotham
    bl.TextSize=12; bl.TextColor3=Theme.TextSecondary; bl.Text=body
    bl.TextXAlignment=Enum.TextXAlignment.Left; bl.TextWrapped=true
    bl.ZIndex=2; bl.Parent=fr
    -- slide in
    TweenSvc:Create(fr,TweenInfo.new(0.28,Enum.EasingStyle.Back,Enum.EasingDirection.Out),
        {Position=UDim2.new(1,-320,0,fr.Position.Y.Offset)}):Play()
    -- slide out
    task.delay(duration,function()
        TweenSvc:Create(fr,TweenInfo.new(0.22),{Position=UDim2.new(1,10,0,fr.Position.Y.Offset)}):Play()
        task.delay(0.25,function() fr:Destroy(); toastY=math.max(10,toastY-h-6) end)
    end)
end

-- ─── 8. Role detection (tool-based) ─────────────────────────────────────────
local ROLE_COLOR={
    Murderer=Color3.fromRGB(255,50,50),
    Sheriff =Color3.fromRGB(60,160,255),
    Innocent=Color3.fromRGB(50,220,90),
    Unknown =Color3.fromRGB(180,180,180),
}
local function getRole(p)
    local c=p.Character; if not c then return "Unknown" end
    local function has(n)
        if c:FindFirstChild(n) then return true end
        local bp=p:FindFirstChild("Backpack")
        return bp and bp:FindFirstChild(n)~=nil
    end
    if has("Knife") or has("MM2Knife") or has("Tool") and c:FindFirstChild("Tool") and
       c:FindFirstChild("Tool").Name:lower():find("knife") then return "Murderer" end
    if has("Sheriff's Gun") or has("ClassicSheriff") or has("Gun") then return "Sheriff" end
    return "Innocent"
end
local function getMyRole() return getRole(lp) end

-- ─── 9. Role reveal – watch for tool changes ─────────────────────────────────
local alerted={}   -- [player]=role  prevent spam
local roleAlertOn=cfg:Get("roleAlert",true)

local function checkRoleAlert(p)
    if not roleAlertOn then return end
    if p==lp then
        local r=getMyRole()
        if r~="Innocent" and r~="Unknown" and alerted[p]~=r then
            alerted[p]=r
            showToast("🎭 YOUR ROLE","You are the "..r.."!",ROLE_COLOR[r],7)
        end
        return
    end
    local r=getRole(p)
    if r~="Innocent" and r~="Unknown" and alerted[p]~=r then
        alerted[p]=r
        local icon=r=="Murderer" and "🔪" or "⭐"
        showToast(icon.." "..r.." FOUND",p.Name.." is the "..r.."!",ROLE_COLOR[r],8)
    end
end

local function watchChar(p,char)
    char.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then task.delay(0.6,function() checkRoleAlert(p) end) end
    end)
    -- initial check (some tools already in char)
    task.delay(1.2, function() checkRoleAlert(p) end)
end

for _,p in ipairs(Players:GetPlayers()) do
    p.CharacterAdded:Connect(function(c)
        alerted[p]=nil   -- reset on respawn
        watchChar(p,c)
    end)
    if p.Character then watchChar(p,p.Character) end
end
Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function(c)
        alerted[p]=nil; watchChar(p,c)
    end)
end)

-- ─── 10. ESP ─────────────────────────────────────────────────────────────────
local espOn    =cfg:Get("espOn",   true)
local espNames =cfg:Get("espNames",true)
local espBoxes =cfg:Get("espBoxes",true)
local espDist  =cfg:Get("espDist", 600)
local espRainbow=cfg:Get("espRainbow",false)
local rainbowHue=0

local espObjs={}   -- [player]={selBox,billboard,bgStroke,roleLbl,hpFill,distLbl,charConn}

local function buildESP(p)
    if p==lp or espObjs[p] then return end
    local h={}

    -- ── SelectionBox (3-D neon outline around whole character) ───────────
    local sb=Instance.new("SelectionBox")
    sb.Color3            = ROLE_COLOR.Unknown
    sb.SurfaceColor3     = ROLE_COLOR.Unknown
    sb.SurfaceTransparency=0.82
    sb.LineThickness     =0.045
    sb.Visible           =false
    sb.Parent            =workspace
    h.selBox=sb

    -- ── BillboardGui (always-on-top HUD tag) ─────────────────────────────
    local bb=Instance.new("BillboardGui")
    bb.AlwaysOnTop=true; bb.Size=UDim2.new(0,168,0,66)
    bb.StudsOffset=Vector3.new(0,3.4,0)
    bb.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
    bb.Enabled=false

    -- frosted card background
    local bg=Instance.new("Frame")
    bg.Size=UDim2.new(1,0,1,0)
    bg.BackgroundColor3=Color3.fromRGB(8,8,18)
    bg.BackgroundTransparency=0.22; bg.BorderSizePixel=0; bg.ZIndex=1; bg.Parent=bb
    local bgC=Instance.new("UICorner"); bgC.CornerRadius=UDim.new(0,8); bgC.Parent=bg
    local bgS=Instance.new("UIStroke"); bgS.Color=ROLE_COLOR.Unknown
    bgS.Thickness=1.5; bgS.Parent=bg; h.bgStroke=bgS

    -- name
    local nl=Instance.new("TextLabel")
    nl.Size=UDim2.new(1,-10,0,22); nl.Position=UDim2.new(0,8,0,4)
    nl.BackgroundTransparency=1; nl.Font=Enum.Font.GothamBold
    nl.TextSize=13; nl.TextColor3=Theme.TextPrimary
    nl.TextStrokeTransparency=0.35; nl.Text=p.Name
    nl.TextXAlignment=Enum.TextXAlignment.Left; nl.ZIndex=2; nl.Parent=bg

    -- role tag
    local rl=Instance.new("TextLabel")
    rl.Size=UDim2.new(1,-10,0,14); rl.Position=UDim2.new(0,8,0,25)
    rl.BackgroundTransparency=1; rl.Font=Enum.Font.GothamBold
    rl.TextSize=11; rl.TextColor3=ROLE_COLOR.Unknown; rl.Text="[?]"
    rl.TextXAlignment=Enum.TextXAlignment.Left; rl.ZIndex=2; rl.Parent=bg; h.roleLbl=rl

    -- health bar bg
    local hpBg=Instance.new("Frame")
    hpBg.Size=UDim2.new(1,-16,0,5); hpBg.Position=UDim2.new(0,8,0,43)
    hpBg.BackgroundColor3=Color3.fromRGB(25,25,45); hpBg.BorderSizePixel=0; hpBg.ZIndex=2; hpBg.Parent=bg
    local hpBgC=Instance.new("UICorner"); hpBgC.CornerRadius=UDim.new(1,0); hpBgC.Parent=hpBg

    -- health bar fill
    local hpF=Instance.new("Frame")
    hpF.Size=UDim2.new(1,0,1,0); hpF.BackgroundColor3=Theme.Success
    hpF.BorderSizePixel=0; hpF.ZIndex=3; hpF.Parent=hpBg; h.hpFill=hpF
    local hpFC=Instance.new("UICorner"); hpFC.CornerRadius=UDim.new(1,0); hpFC.Parent=hpF

    -- distance label
    local dl=Instance.new("TextLabel")
    dl.Size=UDim2.new(1,-10,0,12); dl.Position=UDim2.new(0,8,0,52)
    dl.BackgroundTransparency=1; dl.Font=Enum.Font.Gotham
    dl.TextSize=10; dl.TextColor3=Theme.TextSecondary; dl.Text="? m"
    dl.TextXAlignment=Enum.TextXAlignment.Left; dl.ZIndex=2; dl.Parent=bg; h.distLbl=dl

    -- attach on char load
    local function attach(char)
        local root=char:WaitForChild("HumanoidRootPart",8)
        if not root then return end
        bb.Adornee=root; bb.Parent=root   -- parent to root = auto-destroy on respawn
        sb.Adornee=char
    end
    local cc=p.CharacterAdded:Connect(function(c) attach(c) end)
    if p.Character then task.spawn(attach,p.Character) end
    h.charConn=cc; h.bb=bb; espObjs[p]=h
end

local function removeESP(p)
    local h=espObjs[p]; if not h then return end
    if h.charConn then h.charConn:Disconnect() end
    if h.selBox then h.selBox:Destroy() end
    if h.bb then h.bb:Destroy() end
    espObjs[p]=nil
end

local function refreshESP()
    for p in pairs(espObjs) do removeESP(p) end
    if not espOn then return end
    for _,p in ipairs(Players:GetPlayers()) do buildESP(p) end
end

RS.RenderStepped:Connect(function(dt)
    if espRainbow then rainbowHue=(rainbowHue+dt*0.12)%1 end
    if not espOn then return end

    local myRoot=lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    for p,h in pairs(espObjs) do
        local char=p.Character
        local root=char and char:FindFirstChild("HumanoidRootPart")
        local hum =char and char:FindFirstChildOfClass("Humanoid")
        local ok  =root~=nil and hum~=nil

        if ok and myRoot then
            ok=ok and (root.Position-myRoot.Position).Magnitude<=espDist
        end

        h.selBox.Visible=ok and espBoxes
        h.bb.Enabled    =ok and espNames

        if ok then
            local role=getRole(p)
            local col =ROLE_COLOR[role] or ROLE_COLOR.Unknown
            if espRainbow then col=Color3.fromHSV(rainbowHue,0.9,1) end

            h.bgStroke.Color     =col
            h.selBox.Color3      =col
            h.selBox.SurfaceColor3=col
            h.roleLbl.TextColor3 =col
            h.roleLbl.Text       ="["..role.."]"

            -- health bar
            local ratio=math.clamp(hum.Health/(hum.MaxHealth>0 and hum.MaxHealth or 100),0,1)
            h.hpFill.Size=UDim2.new(ratio,0,1,0)
            h.hpFill.BackgroundColor3=ratio>0.6 and Theme.Success
                                      or ratio>0.3 and Theme.Warning
                                      or Theme.Danger

            -- distance
            if myRoot then
                h.distLbl.Text=math.floor((root.Position-myRoot.Position).Magnitude).." m"
            end
        end
    end
end)

Players.PlayerAdded:Connect(function(p) if espOn then buildESP(p) end end)
Players.PlayerRemoving:Connect(removeESP)

-- ─── Build ESP tab ───────────────────────────────────────────────────────────
local tESP=win:GetTab("ESP")
ui:CreateLabel(tESP,{Text="👁  PLAYER ESP",Color=Theme.TextAccent,Size=12})
ui:CreateSeparator(tESP)

local togESP=ui:CreateToggle(tESP,{
    Label="ESP Enabled",Default=espOn,
    OnChange=function(v) espOn=v; cfg:Set("espOn",v); refreshESP() end})

ui:CreateToggle(tESP,{Label="Show Names / Roles / HP",Default=espNames,
    OnChange=function(v)
        espNames=v; cfg:Set("espNames",v)
        for _,h in pairs(espObjs) do h.bb.Enabled=v end end})

ui:CreateToggle(tESP,{Label="Show 3-D Box Outline",Default=espBoxes,
    OnChange=function(v)
        espBoxes=v; cfg:Set("espBoxes",v)
        for _,h in pairs(espObjs) do h.selBox.Visible=v end end})

ui:CreateSlider(tESP,{Label="Render Distance",Min=50,Max=1500,
    Default=espDist,Suffix=" m",
    OnChange=function(v) espDist=v; cfg:Set("espDist",v) end})

ui:CreateToggle(tESP,{Label="Rainbow ESP",Default=espRainbow,
    OnChange=function(v) espRainbow=v; cfg:Set("espRainbow",v) end})

ui:CreateSeparator(tESP)
ui:CreateButton(tESP,{Text="🔍 Scan Roles Now",OnClick=function()
    alerted={}
    for _,p in ipairs(Players:GetPlayers()) do
        task.spawn(checkRoleAlert,p)
    end
    showToast("🔍 Role Scan","Scanning all players…",Theme.Info,3)
end})

ui:CreateToggle(tESP,{Label="Role Alert Toast",Default=roleAlertOn,
    OnChange=function(v) roleAlertOn=v; cfg:Set("roleAlert",v) end})

ui:CreateSeparator(tESP)
ui:CreateLabel(tESP,{Text="  🔴 Murderer  🔵 Sheriff  🟢 Innocent",Size=11})

refreshESP()

-- ─── 11. Aimbot ──────────────────────────────────────────────────────────────
-- aimMode: "Off" | "Lock" | "Silent"
-- aimTarget: "Murder" | "Sheriff" | "All"
local aimMode   =cfg:Get("aimMode","Lock")
local aimTarget =cfg:Get("aimTarget","Murder")
local aimSmooth =cfg:Get("aimSmooth",7)
local aimFov    =cfg:Get("aimFov",100)

-- FOV circle
local fovCircle; local hasDrawing=pcall(function()
    fovCircle=Drawing.new("Circle")
    fovCircle.Visible=false; fovCircle.Color=Color3.fromRGB(255,60,80)
    fovCircle.Thickness=1.5; fovCircle.Filled=false
end)

local function isAimTarget(p)
    local r=getRole(p)
    if aimTarget=="Murder" then return r=="Murderer" end
    if aimTarget=="Sheriff" then return r=="Sheriff" end
    return r~="Unknown"
end

local function getAimPlayer()
    local best,bestDist=nil,math.huge
    local center=Vector2.new(vp.X/2,vp.Y/2)
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=lp and p.Character and isAimTarget(p) then
            local root=p.Character:FindFirstChild("HumanoidRootPart")
            if root then
                local sp,onScreen=cam:WorldToViewportPoint(root.Position)
                if onScreen then
                    local d=(Vector2.new(sp.X,sp.Y)-center).Magnitude
                    if d<aimFov and d<bestDist then best,bestDist=p,d end
                end
            end
        end
    end
    return best
end

-- Silent aim: hook __namecall to redirect FireServer positions to target head
local silentInstalled=false
local function installSilentAim()
    if silentInstalled then return end
    local ok,mt=pcall(getrawmetatable,game)
    if not ok then
        showToast("⚠ Silent Aim","Executor doesn't support metatable hooks",Theme.Warning,5)
        return
    end
    pcall(setreadonly,mt,false)
    local oldNC=mt.__namecall
    mt.__namecall=newcclosure and newcclosure(function(self,...)
        local method=getnamecallmethod and getnamecallmethod() or ""
        if aimMode=="Silent" and method=="FireServer" and self:IsA("RemoteEvent") then
            local rn=self.Name:lower()
            if rn:find("knife") or rn:find("throw") or rn:find("shoot")
            or rn:find("gun")   or rn:find("hit")   or rn:find("kill") then
                local target=getAimPlayer()
                if target then
                    local head=target.Character and target.Character:FindFirstChild("Head")
                    if head then
                        local args={...}
                        for i,v in ipairs(args) do
                            if typeof(v)=="Vector3" then args[i]=head.Position
                            elseif typeof(v)=="CFrame" then args[i]=CFrame.new(head.Position)
                            elseif typeof(v)=="Instance" and v:IsA("BasePart") then args[i]=head end
                        end
                        return oldNC(self,table.unpack(args))
                    end
                end
            end
        end
        return oldNC(self,...)
    end) or function(self,...)
        return oldNC(self,...)   -- fallback: no newcclosure available
    end
    pcall(setreadonly,mt,true)
    silentInstalled=true
end

-- Lock aim render loop
RS.RenderStepped:Connect(function()
    if hasDrawing and fovCircle then
        fovCircle.Position=Vector2.new(vp.X/2,vp.Y/2)
        fovCircle.Radius=aimFov
        fovCircle.Visible=aimMode~="Off"
    end
    if aimMode~="Lock" then return end
    local target=getAimPlayer(); if not target or not target.Character then return end
    local head=target.Character:FindFirstChild("Head"); if not head then return end
    local goal=CFrame.lookAt(cam.CFrame.Position,head.Position)
    cam.CFrame=cam.CFrame:Lerp(goal,1/math.max(aimSmooth,1))
end)

-- Build Aimbot tab
local tAim=win:GetTab("Aimbot")
ui:CreateLabel(tAim,{Text="🎯  AIM SETTINGS",Color=Theme.TextAccent,Size=12})
ui:CreateSeparator(tAim)

ui:CreateDropdown(tAim,{Label="Aim Mode",Items={"Off","Lock","Silent"},Default=aimMode,
    OnSelect=function(v)
        aimMode=v; cfg:Set("aimMode",v)
        if v=="Silent" then installSilentAim() end
        showToast("🎯 Aim Mode",v.." activated",Theme.Accent,3)
    end})

ui:CreateDropdown(tAim,{Label="Target Filter",Items={"Murder","Sheriff","All"},Default=aimTarget,
    OnSelect=function(v) aimTarget=v; cfg:Set("aimTarget",v) end})

ui:CreateSlider(tAim,{Label="Smoothness (lower=faster)",Min=1,Max=30,Default=aimSmooth,
    OnChange=function(v) aimSmooth=v; cfg:Set("aimSmooth",v) end})

ui:CreateSlider(tAim,{Label="FOV Radius",Min=20,Max=400,Default=aimFov,Suffix=" px",
    OnChange=function(v) aimFov=v; cfg:Set("aimFov",v) end})

ui:CreateSeparator(tAim)
ui:CreateLabel(tAim,{Text="  Lock = camera follows  ·  Silent = remote hook"})
ui:CreateLabel(tAim,{Text="  Silent Aim requires Synapse X / KRNL or similar.",Size=10})

-- ─── 12. Farm ────────────────────────────────────────────────────────────────
local coinOn=cfg:Get("coinFarm",false)
local pickGunOn=cfg:Get("pickGun",false)
local farmConn,pickGunConn

local function doCollectCoins()
    local root=getRoot(); if not root then return end
    for _,o in ipairs(workspace:GetDescendants()) do
        if o:IsA("BasePart") and o.Name=="Coin" then
            root.CFrame=CFrame.new(o.Position+Vector3.new(0,2,0))
            task.wait(0.04)
        end
    end
end

local function doPickGun()
    local root=getRoot(); if not root then return end
    -- Look for the Sheriff's Gun dropped in workspace (it becomes a Tool under workspace)
    for _,o in ipairs(workspace:GetDescendants()) do
        if o:IsA("Tool") and (o.Name=="Sheriff's Gun" or o.Name:lower():find("gun")
            or o.Name:lower():find("sheriff")) then
            local handle=o:FindFirstChild("Handle")
            if handle then
                root.CFrame=CFrame.new(handle.Position+Vector3.new(0,3,0))
                task.wait(0.15)
                return  -- picked up (touch event fires)
            end
        end
    end
end

if coinOn then farmConn=RS.Heartbeat:Connect(function() doCollectCoins() end) end
if pickGunOn then pickGunConn=RS.Heartbeat:Connect(function() task.spawn(doPickGun) end) end

local tFarm=win:GetTab("Farm")
ui:CreateLabel(tFarm,{Text="💰  FARM",Color=Theme.TextAccent,Size=12})
ui:CreateSeparator(tFarm)

ui:CreateToggle(tFarm,{Label="Auto Coin Collect",Default=coinOn,
    OnChange=function(v)
        coinOn=v; cfg:Set("coinFarm",v)
        if farmConn then farmConn:Disconnect(); farmConn=nil end
        if v then farmConn=RS.Heartbeat:Connect(function() doCollectCoins() end) end
    end})

ui:CreateButton(tFarm,{Text="⚡ Collect All Coins (once)",Primary=false,
    OnClick=function() task.spawn(doCollectCoins) end})

ui:CreateSeparator(tFarm)
ui:CreateLabel(tFarm,{Text="🔫  AUTO PICK GUN",Color=Theme.TextAccent,Size=12})
ui:CreateSeparator(tFarm)

ui:CreateToggle(tFarm,{Label="Auto Pick Dropped Sheriff Gun",Default=pickGunOn,
    OnChange=function(v)
        pickGunOn=v; cfg:Set("pickGun",v)
        if pickGunConn then pickGunConn:Disconnect(); pickGunConn=nil end
        if v then
            pickGunConn=RS.Heartbeat:Connect(function()
                if getMyRole()=="Innocent" or getMyRole()=="Sheriff" then
                    task.spawn(doPickGun)
                end
                task.wait(0.8)
            end)
        end
    end})

ui:CreateButton(tFarm,{Text="🔫 Grab Gun Now",Primary=false,
    OnClick=function() task.spawn(doPickGun) end})

ui:CreateSeparator(tFarm)
ui:CreateLabel(tFarm,{Text="🔐  SAFES",Color=Theme.TextAccent,Size=12})
ui:CreateSeparator(tFarm)

local safeConn
ui:CreateToggle(tFarm,{Label="Auto Open Safes",Default=false,
    OnChange=function(v)
        if safeConn then safeConn:Disconnect(); safeConn=nil end
        if not v then return end
        safeConn=RS.Heartbeat:Connect(function()
            local root=getRoot(); if not root then return end
            for _,o in ipairs(workspace:GetDescendants()) do
                if o:IsA("BasePart") and o.Name:lower():find("safe") then
                    root.CFrame=CFrame.new(o.Position+Vector3.new(0,2,0))
                    task.wait(0.08)
                end
            end
        end)
    end})

-- ─── 13. Combat ──────────────────────────────────────────────────────────────
local killAura=cfg:Get("killAura",false)
local auraRange=cfg:Get("auraRange",12)
local knifeReach=cfg:Get("knifeReach",false)
local ORIG_RANGE=6
local knifeReachConn

local function setKnifeReach(on)
    if knifeReachConn then knifeReachConn:Disconnect(); knifeReachConn=nil end
    if not on then return end
    knifeReachConn=RS.Heartbeat:Connect(function()
        local char=lp.Character; if not char then return end
        for _,tool in ipairs(char:GetChildren()) do
            if tool:IsA("Tool") and tool.Name:lower():find("knife") then
                local cfg2=tool:FindFirstChild("Configurations") or tool:FindFirstChild("Config")
                local rv=tool:FindFirstChild("Range") or tool:FindFirstChild("range")
                if rv and rv:IsA("NumberValue") then rv.Value=ORIG_RANGE*3 end
            end
        end
    end)
end

local auraConn
local function setKillAura(on)
    if auraConn then auraConn:Disconnect(); auraConn=nil end
    if not on then return end
    auraConn=RS.Heartbeat:Connect(function()
        local root=getRoot(); if not root then return end
        local char=lp.Character; if not char then return end
        local hasTool=false
        for _,t in ipairs(char:GetChildren()) do
            if t:IsA("Tool") then hasTool=true; break end
        end
        if not hasTool then return end
        for _,p in ipairs(Players:GetPlayers()) do
            if p~=lp and p.Character then
                local pr=p.Character:FindFirstChild("HumanoidRootPart")
                if pr and (root.Position-pr.Position).Magnitude<=auraRange then
                    -- Teleport onto them so the tool-touch fires on the server
                    root.CFrame=CFrame.new(pr.Position+Vector3.new(0,1,0))
                    task.wait(0.05)
                end
            end
        end
    end)
end

local tCombat=win:GetTab("Combat")
ui:CreateLabel(tCombat,{Text="⚔  COMBAT",Color=Theme.TextAccent,Size=12})
ui:CreateSeparator(tCombat)

ui:CreateToggle(tCombat,{Label="Kill Aura (teleport onto targets)",Default=killAura,
    OnChange=function(v) killAura=v; cfg:Set("killAura",v); setKillAura(v) end})

ui:CreateSlider(tCombat,{Label="Aura Range",Min=4,Max=40,Default=auraRange,Suffix=" st",
    OnChange=function(v) auraRange=v; cfg:Set("auraRange",v) end})

ui:CreateToggle(tCombat,{Label="Knife Reach Extend (×3)",Default=knifeReach,
    OnChange=function(v) knifeReach=v; cfg:Set("knifeReach",v); setKnifeReach(v) end})

ui:CreateSeparator(tCombat)
ui:CreateLabel(tCombat,{Text="🎭  ROLE TOOLS",Color=Theme.TextAccent,Size=12})
ui:CreateSeparator(tCombat)

-- Auto equip role tool (knife if murderer, gun if sheriff)
ui:CreateButton(tCombat,{Text="🔪 Equip Role Tool Now",
    OnClick=function()
        local char=lp.Character; if not char then return end
        local role=getMyRole()
        local toolName=role=="Murderer" and "Knife" or role=="Sheriff" and "Sheriff's Gun" or nil
        if not toolName then
            showToast("⚠ No Role","You are Innocent – no tool to equip.",Theme.Warning,3); return end
        local hum=char:FindFirstChildOfClass("Humanoid")
        local bp=lp:FindFirstChild("Backpack")
        local tool=bp and bp:FindFirstChild(toolName) or char:FindFirstChild(toolName)
        if tool and hum then
            hum:EquipTool(tool)
            showToast("✅ Equipped",toolName.." equipped.",Theme.Success,3)
        else
            showToast("⚠ Not found","Tool '"..toolName.."' not in backpack.",Theme.Warning,4)
        end
    end})

ui:CreateButton(tCombat,{Text="📍 Teleport to Murderer",Primary=false,
    OnClick=function()
        for _,p in ipairs(Players:GetPlayers()) do
            if getRole(p)=="Murderer" and p.Character then
                local pr=p.Character:FindFirstChild("HumanoidRootPart"); if not pr then return end
                local root=getRoot(); if not root then return end
                root.CFrame=CFrame.new(pr.Position+Vector3.new(4,2,4))
                showToast("📍 TP","Teleported to "..p.Name,Theme.Accent,3); return
            end
        end
        showToast("⚠ No Murderer","No murderer found yet.",Theme.Warning,3)
    end})

ui:CreateButton(tCombat,{Text="⭐ Teleport to Sheriff",Primary=false,
    OnClick=function()
        for _,p in ipairs(Players:GetPlayers()) do
            if getRole(p)=="Sheriff" and p.Character then
                local pr=p.Character:FindFirstChild("HumanoidRootPart"); if not pr then return end
                local root=getRoot(); if not root then return end
                root.CFrame=CFrame.new(pr.Position+Vector3.new(4,2,4))
                showToast("⭐ TP","Teleported to "..p.Name,Theme.Info,3); return
            end
        end
        showToast("⚠ No Sheriff","No sheriff found yet.",Theme.Warning,3)
    end})

-- ─── 14. Player ──────────────────────────────────────────────────────────────
-- FIX: forward-declare setNoclip / setFly so the CharacterAdded closure
-- captures the LOCAL variables rather than falling back to a nil global.
local setNoclip, setFly

local function applyStats()
    local h=getHum(); if not h then return end
    h.WalkSpeed=cfg:Get("walkSpeed",16)
    h.JumpPower=cfg:Get("jumpPower",50)
end
lp.CharacterAdded:Connect(function(c)
    local h=c:WaitForChild("Humanoid",8); if h then
        h.WalkSpeed=cfg:Get("walkSpeed",16)
        h.JumpPower=cfg:Get("jumpPower",50)
    end
    -- re-apply active toggles after respawn
    if cfg:Get("noclip",false) and setNoclip then setNoclip(true) end
    if cfg:Get("fly",false)    and setFly    then task.delay(0.5,function() setFly(true) end) end
end)
applyStats()

-- Noclip (assign to the forward-declared upvalue)
local noclipConn
setNoclip = function(on)
    if noclipConn then noclipConn:Disconnect(); noclipConn=nil end
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
-- Fly (assign to the forward-declared upvalue)
setFly = function(on)
    flyOn=on
    if flyConn then flyConn:Disconnect(); flyConn=nil end
    if flyBody and flyBody.Parent then flyBody:Destroy(); flyBody=nil end
    local root=getRoot(); local hum=getHum()
    if not (root and hum) then return end
    if on then
        hum.PlatformStand=true
        flyBody=Instance.new("BodyVelocity"); flyBody.Velocity=Vector3.zero
        flyBody.MaxForce=Vector3.new(1e5,1e5,1e5); flyBody.Name="NexusFly"; flyBody.Parent=root
        flyConn=RS.Heartbeat:Connect(function()
            if not flyOn or not flyBody or not flyBody.Parent then
                if flyConn then flyConn:Disconnect(); flyConn=nil end; return end
            local d=Vector3.zero; local cf=cam.CFrame
            if UIS:IsKeyDown(Enum.KeyCode.W) then d=d+cf.LookVector end
            if UIS:IsKeyDown(Enum.KeyCode.S) then d=d-cf.LookVector end
            if UIS:IsKeyDown(Enum.KeyCode.A) then d=d-cf.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.D) then d=d+cf.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.Space)     then d=d+Vector3.new(0,1,0) end
            if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then d=d-Vector3.new(0,1,0) end
            flyBody.Velocity=d.Magnitude>0 and d.Unit*38 or Vector3.zero
        end)
    else
        if hum then hum.PlatformStand=false end
    end
end

-- Infinite jump
local infJump=cfg:Get("infJump",false)
UIS.JumpRequest:Connect(function()
    if not infJump then return end
    local hum=getHum(); if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
end)

-- Anti-AFK
local afkConn
local function setAntiAfk(on)
    if afkConn then afkConn:Disconnect(); afkConn=nil end
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

-- Custom crosshair
local crossLines={}
local function setCrosshair(on)
    for _,l in ipairs(crossLines) do l:Remove() end; crossLines={}
    if not on then return end
    local ok=pcall(function()
        local cx,cy=vp.X/2,vp.Y/2; local sz=10; local gap=4; local col=Color3.new(1,1,1)
        local function line(x1,y1,x2,y2)
            local l=Drawing.new("Line"); l.From=Vector2.new(x1,y1); l.To=Vector2.new(x2,y2)
            l.Color=col; l.Thickness=1.5; l.Visible=true; table.insert(crossLines,l)
        end
        line(cx-sz-gap,cy,cx-gap,cy); line(cx+gap,cy,cx+sz+gap,cy)
        line(cx,cy-sz-gap,cx,cy-gap); line(cx,cy+gap,cx,cy+sz+gap)
        -- dot
        local d=Drawing.new("Circle"); d.Position=Vector2.new(cx,cy); d.Radius=1.5
        d.Color=col; d.Filled=true; d.Visible=true; table.insert(crossLines,d)
    end)
    if not ok then showToast("⚠ Crosshair","Drawing API not available.",Theme.Warning,4) end
end

local tPlayer=win:GetTab("Player")
ui:CreateLabel(tPlayer,{Text="🏃  MOVEMENT",Color=Theme.TextAccent,Size=12})
ui:CreateSeparator(tPlayer)

local slSpeed=ui:CreateSlider(tPlayer,{Label="Walk Speed",Min=4,Max=150,
    Default=cfg:Get("walkSpeed",16),
    OnChange=function(v) cfg:Set("walkSpeed",v); local h=getHum(); if h then h.WalkSpeed=v end end})

local slJump=ui:CreateSlider(tPlayer,{Label="Jump Power",Min=7,Max=300,
    Default=cfg:Get("jumpPower",50),
    OnChange=function(v) cfg:Set("jumpPower",v); local h=getHum(); if h then h.JumpPower=v end end})

ui:CreateSeparator(tPlayer)
ui:CreateLabel(tPlayer,{Text="✈  SPECIAL",Color=Theme.TextAccent,Size=12})
ui:CreateSeparator(tPlayer)

ui:CreateToggle(tPlayer,{Label="Noclip",Default=cfg:Get("noclip",false),
    OnChange=function(v) cfg:Set("noclip",v); setNoclip(v) end})

ui:CreateToggle(tPlayer,{Label="Fly  (WASD + Space/Shift)",Default=cfg:Get("fly",false),
    OnChange=function(v) cfg:Set("fly",v); setFly(v) end})

ui:CreateToggle(tPlayer,{Label="Infinite Jump",Default=infJump,
    OnChange=function(v) infJump=v; cfg:Set("infJump",v) end})

ui:CreateToggle(tPlayer,{Label="Anti-AFK",Default=cfg:Get("antiAfk",false),
    OnChange=function(v) cfg:Set("antiAfk",v); setAntiAfk(v) end})

ui:CreateToggle(tPlayer,{Label="Custom Crosshair",Default=cfg:Get("crosshair",false),
    OnChange=function(v) cfg:Set("crosshair",v); setCrosshair(v) end})

ui:CreateSeparator(tPlayer)
ui:CreateButton(tPlayer,{Text="Reset Character",Icon="↺",Primary=false,
    OnClick=function() local h=getHum(); if h then h.Health=0 end end})

ui:CreateButton(tPlayer,{Text="📍 Teleport to Map Center",Primary=false,
    OnClick=function()
        local root=getRoot(); if not root then return end
        -- Find the round map
        for _,o in ipairs(workspace:GetChildren()) do
            if o:IsA("Model") and o.Name:lower():find("map") then
                local mid=o:FindFirstChild("SpawnLocation") or o.PrimaryPart
                if mid then
                    root.CFrame=CFrame.new(mid.Position+Vector3.new(0,5,0))
                    showToast("📍 TP","Teleported to map.",Theme.Info,3); return
                end
            end
        end
        root.CFrame=CFrame.new(0,50,0)
        showToast("📍 TP","Teleported to 0,0.",Theme.Info,3)
    end})

-- ─── 15. Settings tab ────────────────────────────────────────────────────────
local tSet=win:GetTab("Settings")
ui:CreateLabel(tSet,{Text="⚙  CONFIG",Color=Theme.TextAccent,Size=12})
ui:CreateSeparator(tSet)

ui:CreateButton(tSet,{Text="💾 Save Config",OnClick=function()
    cfg:Save()
    showToast("💾 Saved","Config saved to file.",Theme.Success,3)
end})

ui:CreateButton(tSet,{Text="📂 Load Config",Primary=false,OnClick=function()
    cfg:Load()
    showToast("📂 Loaded","Config loaded from file.",Theme.Info,3)
end})

ui:CreateSeparator(tSet)
ui:CreateButton(tSet,{Text="🔄 Rejoin Same Server",Primary=false,OnClick=function()
    pcall(function()
        game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId,game.JobId,lp)
    end)
end})
ui:CreateButton(tSet,{Text="🌍 New Server",Primary=false,OnClick=function()
    pcall(function()
        game:GetService("TeleportService"):Teleport(game.PlaceId,lp)
    end)
end})

ui:CreateSeparator(tSet)
if not isMobile then
    ui:CreateLabel(tSet,{Text="⌨  RightShift → show / hide menu"})
else
    ui:CreateLabel(tSet,{Text="📱  Tap ☰ button → show / hide menu"})
end
ui:CreateLabel(tSet,{Text="  NexusUI MM2 v2.0  ·  github.com/mikolaq1111/nexusui",Size=10})

-- ─── 16. Mobile toggle button ────────────────────────────────────────────────
if isMobile then
    local btnGui=Instance.new("ScreenGui")
    btnGui.Name="NexusMM2ToggleGui"; btnGui.ResetOnSpawn=false
    btnGui.DisplayOrder=1000; btnGui.IgnoreGuiInset=true; btnGui.Parent=getSecureParent()
    local mb=Instance.new("TextButton")
    mb.Size=UDim2.new(0,56,0,56); mb.Position=UDim2.new(1,-68,1,-80)
    mb.BackgroundColor3=Theme.Accent; mb.BorderSizePixel=0
    mb.Font=Theme.FontBody; mb.TextSize=24; mb.Text="☰"
    mb.TextColor3=Theme.TextPrimary; mb.AutoButtonColor=false; mb.ZIndex=1; mb.Parent=btnGui
    local mbC=Instance.new("UICorner"); mbC.CornerRadius=UDim.new(1,0); mbC.Parent=mb
    Drag.makeDraggable(mb,mb)
    mb.MouseButton1Click:Connect(function()
        guiOpen=not guiOpen
        if guiOpen then
            win.Instance.Visible=true
            Tween.openWindow(win.Instance,UDim2.new(0,winW,0,winH)); mb.Text="✕"
        else Tween.closeWindow(win.Instance); mb.Text="☰" end
    end)
end

-- ─── 17. Desktop keybind (RightShift) ────────────────────────────────────────
if not isMobile then
    UIS.InputBegan:Connect(function(inp,gp)
        if gp then return end
        if inp.KeyCode==Enum.KeyCode.RightShift then
            guiOpen=not guiOpen
            if guiOpen then
                win.Instance.Visible=true
                Tween.openWindow(win.Instance,UDim2.new(0,winW,0,winH))
            else Tween.closeWindow(win.Instance) end
        end
    end)
end

-- ─── 18. Auto-save + cleanup ─────────────────────────────────────────────────
cfg:StartPeriodicSave(60)
lp.CharacterRemoving:Connect(function() cfg:Save() end)

showToast("✅ NexusUI MM2 v2.0","Loaded! "
    ..(isMobile and "Tap ☰ to toggle." or "RightShift to toggle."),Theme.Success,5)

print("╔═══════════════════════════════╗")
print("║  NexusUI MM2  v2.0  loaded ✓  ║")
print("║  RightShift → toggle menu     ║")
print("╚═══════════════════════════════╝")
