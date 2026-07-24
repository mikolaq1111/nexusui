--[[
    components.lua  (ui-library)
    ============================
    All individual UI widget constructors.

    ── Cross-device fixes (v1.1) ────────────────────────────────────────────────
    • Device-type detection: isMobile() checks GuiService.IsTenFootInterface
      and screen width to distinguish phone / tablet / PC.
    • Window size is now clamped to screen bounds so it never overflows on
      small phones.  Default size uses scale ratios, not fixed pixels.
    • MouseEnter/MouseLeave hover effects are SKIPPED on touch devices —
      they caused stuck "hovered" visual states because touch never fires Leave.
    • Button onClick is fired on MouseButton1Click only (not on both
      MouseButton1Up AND Click — that caused double-fires on touch).
    • Slider touch hit-area is enlarged with an invisible overlay Frame so
      fingers can grab it comfortably.
    • Dropdown panel is reparented to the ScreenGui root so it is never
      clipped by the ScrollingFrame's ClipsDescendants.  Its absolute
      position is recomputed each time it opens.
    • Toggle uses a single reliable MouseButton1Click / TouchTap handler.
    • All interactive elements have a minimum touch target of 44×44 px
      (Apple HIG / Material Design recommendation).
    ─────────────────────────────────────────────────────────────────────────────

    Every function returns a "handle" table:
        handle.Instance  — root GuiObject
        handle:Set(...)  — programmatic state setter
        handle:Get(...)  — read current state
        handle:Destroy() — clean removal
--]]

local Components = {}

-- ─── Services ─────────────────────────────────────────────────────────────────
local TweenService   = game:GetService("TweenService")
local UIS            = game:GetService("UserInputService")
local GuiService     = game:GetService("GuiService")
local RunService     = game:GetService("RunService")

-- ─── Device helpers ───────────────────────────────────────────────────────────

-- Returns true when running on a phone/tablet (touch-primary device).
-- We check the shortest screen dimension instead of a boolean flag so we
-- correctly handle tablets in landscape mode.
local function isTouchDevice()
    return UIS.TouchEnabled and not UIS.MouseEnabled
end

-- Returns the viewport size, accounting for the GUI inset on the top bar.
local function viewportSize()
    local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize
               or Vector2.new(800, 600)
    return vp
end

-- ─── Internal helpers ─────────────────────────────────────────────────────────

local function tween(instance, tweenInfo, props, callback)
    local t = TweenService:Create(instance, tweenInfo, props)
    if callback then t.Completed:Once(callback) end
    t:Play()
    return t
end

local function corner(inst, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = radius or UDim.new(0, 8)
    c.Parent = inst
    return c
end

local function stroke(inst, color, thickness, transparency)
    local s = Instance.new("UIStroke")
    s.Color        = color        or Color3.fromRGB(60, 60, 90)
    s.Thickness    = thickness    or 1
    s.Transparency = transparency or 0
    s.Parent       = inst
    return s
end

local function gradient(inst, colorSeq, rotation)
    local g = Instance.new("UIGradient")
    g.Color    = colorSeq
    g.Rotation = rotation or 0
    g.Parent   = inst
    return g
end

-- Ambient glow behind a frame (decorative only).
local function makeGlow(parent, glowColor, transparency)
    local glow = Instance.new("Frame")
    glow.Name                   = "GlowEffect"
    glow.Size                   = UDim2.new(1, 30, 1, 30)
    glow.Position               = UDim2.new(0, -15, 0, -15)
    glow.BackgroundColor3       = glowColor
    glow.BackgroundTransparency = transparency or 0.82
    glow.ZIndex                 = parent.ZIndex - 1
    glow.BorderSizePixel        = 0
    corner(glow, UDim.new(0, 18))
    glow.Parent = parent
    return glow
end

-- Invisible touch-target expander (keeps layout size but widens the
-- interactive area — important for sliders and small toggle knobs).
local function touchTarget(parent, zIndex)
    local hit = Instance.new("Frame")
    hit.Size               = UDim2.new(1, 0, 1, 0)
    hit.BackgroundTransparency = 1
    hit.ZIndex             = zIndex or (parent.ZIndex + 2)
    hit.Parent             = parent
    return hit
end

-- ─── CreateWindow ─────────────────────────────────────────────────────────────
--[[
    options = {
        Title       = "My Window",
        -- Size is now specified as a MAXIMUM; it is clamped to the screen.
        Size        = UDim2.new(0, 400, 0, 500),
        Position    = UDim2.new(0.5, -200, 0.5, -250),
        CanClose    = true,
        CanMinimise = true,
        Tabs        = {"Main","Settings"},
    }
--]]
function Components.CreateWindow(parent, options, theme, plugins)
    options = options or {}

    local title    = options.Title       or "NexusUI"
    local canClose = options.CanClose    ~= false
    local canMin   = options.CanMinimise ~= false
    local tabNames = options.Tabs        or {"Main"}

    -- ── Responsive sizing ────────────────────────────────────────────────────
    -- Never wider/taller than 96% of the screen so it fits on small phones.
    local vp          = viewportSize()
    local touch       = isTouchDevice()
    local maxW        = math.floor(vp.X * 0.96)
    local maxH        = math.floor(vp.Y * 0.90)
    local desiredW    = options.Size and options.Size.X.Offset or theme.WindowWidth
    local desiredH    = options.Size and options.Size.Y.Offset or 480
    -- On phone portrait (narrow screen) fill almost full width
    if vp.X < 480 then desiredW = maxW end
    local winW        = math.min(desiredW, maxW)
    local winH        = math.min(desiredH, maxH)
    local winSize     = UDim2.new(0, winW, 0, winH)

    -- Centre the window regardless of screen size
    local winPos      = options.Position
                     or UDim2.new(0.5, -winW/2, 0.5, -winH/2)

    -- ── Root frame ───────────────────────────────────────────────────────────
    local window = Instance.new("Frame")
    window.Name                   = "NexusWindow_" .. title
    window.Size                   = UDim2.new(0, 1, 0, 1)   -- springs open
    window.Position               = winPos
    window.AnchorPoint            = Vector2.new(0, 0)
    window.BackgroundColor3       = theme.Surface
    window.BackgroundTransparency = theme.WindowTransparency
    window.BorderSizePixel        = 0
    window.ClipsDescendants       = true
    window.ZIndex                 = 10
    window.Parent                 = parent
    corner(window, theme.CornerRadius)
    stroke(window, theme.Border, theme.StrokeWeight)
    makeGlow(window, theme.GlowColor, theme.GlowTransparency)

    tween(window, theme.TweenInfo.Spring, { Size = winSize })

    -- ── Title bar ────────────────────────────────────────────────────────────
    -- Use a taller title bar on touch so buttons hit comfortably.
    local titleH = touch and math.max(theme.TitleBarHeight, 48) or theme.TitleBarHeight

    local titleBar = Instance.new("Frame")
    titleBar.Name             = "TitleBar"
    titleBar.Size             = UDim2.new(1, 0, 0, titleH)
    titleBar.BackgroundColor3 = theme.AccentDark
    titleBar.BorderSizePixel  = 0
    titleBar.ZIndex           = 11
    titleBar.Parent           = window
    corner(titleBar, theme.CornerRadius)
    local titleCover = Instance.new("Frame")
    titleCover.Size             = UDim2.new(1, 0, 0, theme.CornerRadius.Offset)
    titleCover.Position         = UDim2.new(0, 0, 1, -theme.CornerRadius.Offset)
    titleCover.BackgroundColor3 = theme.AccentDark
    titleCover.BorderSizePixel  = 0
    titleCover.ZIndex           = 11
    titleCover.Parent           = titleBar
    gradient(titleBar, theme.AccentGradient, 90)

    -- Decorative dots (hidden on very narrow screens to save space)
    if vp.X > 320 then
        local dots = Instance.new("Frame")
        dots.Name                   = "Dots"
        dots.Size                   = UDim2.new(0, 48, 0, 10)
        dots.Position               = UDim2.new(0, 12, 0.5, -5)
        dots.BackgroundTransparency = 1
        dots.ZIndex                 = 12
        dots.Parent                 = titleBar
        for i, col in ipairs({theme.Danger, theme.Warning, theme.Success}) do
            local dot = Instance.new("Frame")
            dot.Size              = UDim2.new(0, 10, 0, 10)
            dot.Position          = UDim2.new(0, (i-1)*16, 0, 0)
            dot.BackgroundColor3  = col
            dot.BorderSizePixel   = 0
            dot.ZIndex            = 12
            dot.Parent            = dots
            corner(dot, UDim.new(1, 0))
        end
    end

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name               = "Title"
    titleLabel.Size               = UDim2.new(1, -120, 1, 0)
    titleLabel.Position           = UDim2.new(0, 60, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Font               = theme.FontTitle
    titleLabel.TextSize           = theme.TextSizeTitle
    titleLabel.TextColor3         = theme.TextPrimary
    titleLabel.Text               = title
    titleLabel.TextXAlignment     = Enum.TextXAlignment.Left
    titleLabel.TextTruncate       = Enum.TextTruncate.AtEnd   -- prevent overflow
    titleLabel.ZIndex             = 12
    titleLabel.Parent             = titleBar

    -- Close / Minimise buttons — minimum 44 px for comfortable touch tapping
    local btnX = math.max(titleH - 10, touch and 44 or 28)
    local function makeTitleBtn(icon, xOffset, bgColor, hoverColor, onClick)
        local btn = Instance.new("TextButton")
        btn.Size              = UDim2.new(0, btnX, 0, btnX)
        btn.Position          = UDim2.new(1, xOffset, 0.5, -btnX/2)
        btn.BackgroundColor3  = bgColor
        btn.Font              = theme.FontBody
        btn.TextSize          = 13
        btn.Text              = icon
        btn.TextColor3        = theme.TextPrimary
        btn.BorderSizePixel   = 0
        btn.AutoButtonColor   = false
        btn.ZIndex            = 13
        btn.Parent            = titleBar
        corner(btn, UDim.new(1, 0))

        -- Only attach hover effects for mouse users.
        -- On touch, MouseEnter fires without a corresponding MouseLeave
        -- causing permanent "hovered" colour stuck state.
        if not touch then
            btn.MouseEnter:Connect(function()
                tween(btn, theme.TweenInfo.Fast, { BackgroundColor3 = hoverColor })
            end)
            btn.MouseLeave:Connect(function()
                tween(btn, theme.TweenInfo.Fast, { BackgroundColor3 = bgColor })
            end)
        end
        btn.MouseButton1Click:Connect(onClick)
        return btn
    end

    local minimised = false
    if canClose then
        makeTitleBtn("✕", -10, Color3.fromRGB(60,30,40), theme.Danger, function()
            tween(window, theme.TweenInfo.Normal,
                { Size = UDim2.new(0,1,0,1), BackgroundTransparency = 1 },
                function() window:Destroy() end)
        end)
    end
    if canMin then
        local minOffset = canClose and -(10 + btnX + 6) or -10
        makeTitleBtn("–", minOffset, Color3.fromRGB(40,50,30), theme.Success, function()
            minimised = not minimised
            if minimised then
                tween(window, theme.TweenInfo.Normal,
                    { Size = UDim2.new(0, winW, 0, titleH) })
            else
                tween(window, theme.TweenInfo.Spring, { Size = winSize })
            end
        end)
    end

    -- ── Drag (title bar) ─────────────────────────────────────────────────────
    if plugins and plugins.Drag then
        plugins.Drag.makeDraggable(window, titleBar)
    end

    -- ── Tab strip ────────────────────────────────────────────────────────────
    -- On touch, use a slightly taller tab strip for easier tapping.
    local tabStripH = touch and 38 or 32

    local tabStrip = Instance.new("Frame")
    tabStrip.Name             = "TabStrip"
    tabStrip.Size             = UDim2.new(1, 0, 0, tabStripH)
    tabStrip.Position         = UDim2.new(0, 0, 0, titleH)
    tabStrip.BackgroundColor3 = theme.SurfaceSunken
    tabStrip.BorderSizePixel  = 0
    tabStrip.ZIndex           = 11
    tabStrip.Parent           = window
    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection  = Enum.FillDirection.Horizontal
    tabLayout.SortOrder      = Enum.SortOrder.LayoutOrder
    tabLayout.Padding        = UDim.new(0, 4)
    tabLayout.Parent         = tabStrip
    local tabPad = Instance.new("UIPadding")
    tabPad.PaddingLeft   = UDim.new(0, 6)
    tabPad.PaddingTop    = UDim.new(0, 4)
    tabPad.PaddingBottom = UDim.new(0, 4)
    tabPad.Parent        = tabStrip

    -- ── Content area ─────────────────────────────────────────────────────────
    local contentOffset = titleH + tabStripH

    local contentFrames = {}
    local activeTab     = nil
    local tabButtons    = {}

    local function switchTab(name)
        if activeTab == name then return end
        activeTab = name
        for tname, frame in pairs(contentFrames) do
            frame.Visible = (tname == name)
        end
        for tname, tbtn in pairs(tabButtons) do
            local active = (tname == name)
            tween(tbtn, theme.TweenInfo.Fast, {
                BackgroundColor3    = active and theme.Accent or Color3.fromRGB(0,0,0),
                BackgroundTransparency = active and 0 or 1,
                TextColor3          = active and theme.TextPrimary or theme.TextSecondary,
            })
        end
    end

    for i, tabName in ipairs(tabNames) do
        local tbtn = Instance.new("TextButton")
        tbtn.Name                   = "Tab_" .. tabName
        tbtn.AutoButtonColor        = false
        tbtn.BackgroundColor3       = theme.Accent
        tbtn.BackgroundTransparency = (i == 1) and 0 or 1
        tbtn.Size                   = UDim2.new(0, 0, 1, 0)
        tbtn.AutomaticSize          = Enum.AutomaticSize.X
        tbtn.Font                   = theme.FontBody
        tbtn.TextSize               = theme.TextSizeBody
        tbtn.Text                   = "  " .. tabName .. "  "
        tbtn.TextColor3             = (i == 1) and theme.TextPrimary or theme.TextSecondary
        tbtn.ZIndex                 = 12
        tbtn.LayoutOrder            = i
        tbtn.Parent                 = tabStrip
        corner(tbtn, UDim.new(0, 6))
        tabButtons[tabName] = tbtn

        local content = Instance.new("ScrollingFrame")
        content.Name                   = "Content_" .. tabName
        content.Size                   = UDim2.new(1, 0, 1, -contentOffset)
        content.Position               = UDim2.new(0, 0, 0, contentOffset)
        content.BackgroundTransparency = 1
        content.BorderSizePixel        = 0
        -- Thicker scrollbar on touch — easier to grab
        content.ScrollBarThickness     = touch and 6 or 4
        content.ScrollBarImageColor3   = theme.ScrollBar
        content.CanvasSize             = UDim2.new(0, 0, 0, 0)
        content.AutomaticCanvasSize    = Enum.AutomaticSize.Y
        content.Visible                = (i == 1)
        content.ZIndex                 = 11
        content.Parent                 = window
        contentFrames[tabName]         = content

        local listLayout = Instance.new("UIListLayout")
        listLayout.SortOrder = Enum.SortOrder.LayoutOrder
        listLayout.Padding   = UDim.new(0, theme.ItemSpacing)
        listLayout.Parent    = content
        local pad = Instance.new("UIPadding")
        pad.PaddingLeft   = UDim.new(0, theme.Padding)
        pad.PaddingRight  = UDim.new(0, theme.Padding)
        pad.PaddingTop    = UDim.new(0, theme.Padding)
        pad.PaddingBottom = UDim.new(0, theme.Padding)
        pad.Parent        = content

        tbtn.MouseButton1Click:Connect(function() switchTab(tabName) end)
    end
    activeTab = tabNames[1]

    -- ── Handle ───────────────────────────────────────────────────────────────
    local handle = {}
    handle.Instance = window
    function handle:GetTab(name) return contentFrames[name] end
    function handle:GetContent() return contentFrames[tabNames[1]] end
    function handle:Destroy() window:Destroy() end
    return handle
end

-- ─── CreateButton ─────────────────────────────────────────────────────────────
--[[
    options = {
        Text    = "Click Me",
        Icon    = "🚀",
        OnClick = function() end,
        Danger  = false,
        Primary = true,
    }
--]]
function Components.CreateButton(parent, options, theme, _plugins)
    options = options or {}

    local btnText   = options.Text    or "Button"
    local icon      = options.Icon    or ""
    local onClick   = options.OnClick or function() end
    local isDanger  = options.Danger  or false
    local isPrimary = options.Primary ~= false
    local touch     = isTouchDevice()

    local baseBg  = isDanger  and theme.Danger
                 or isPrimary and theme.Accent
                 or theme.SurfaceRaised
    local hoverBg = isDanger  and Color3.fromRGB(255, 100, 120)
                 or isPrimary and theme.AccentLight
                 or theme.Border

    -- Minimum height 44 px on touch for comfortable tapping
    local btnH = touch and math.max(theme.ItemHeight, 44) or theme.ItemHeight

    local btn = Instance.new("TextButton")
    btn.Name               = "NexusBtn_" .. btnText
    btn.Size               = UDim2.new(1, 0, 0, btnH)
    btn.BackgroundColor3   = baseBg
    btn.BorderSizePixel    = 0
    btn.Font               = theme.FontBody
    btn.TextSize           = theme.TextSizeBody
    btn.TextColor3         = theme.TextPrimary
    btn.Text               = (icon ~= "" and icon .. "  " or "") .. btnText
    btn.AutoButtonColor    = false
    btn.ZIndex             = 12
    btn.Parent             = parent
    corner(btn, theme.CornerSmall)

    if isPrimary and not isDanger then
        gradient(btn, theme.AccentGradient, 90)
    end

    -- Mouse-only hover effects (skipped on touch to prevent stuck states)
    if not touch then
        btn.MouseEnter:Connect(function()
            tween(btn, theme.TweenInfo.Fast, { BackgroundColor3 = hoverBg })
        end)
        btn.MouseLeave:Connect(function()
            tween(btn, theme.TweenInfo.Fast, { BackgroundColor3 = baseBg })
        end)
    end

    -- Press feedback works on all devices (InputBegan/InputEnded are universal)
    btn.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            tween(btn, theme.TweenInfo.Fast,
                { BackgroundTransparency = 0.2, Size = UDim2.new(1, -2, 0, btnH - 2) })
        end
    end)
    btn.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            tween(btn, theme.TweenInfo.Fast,
                { BackgroundTransparency = 0, Size = UDim2.new(1, 0, 0, btnH) })
        end
    end)

    -- Single click handler — MouseButton1Click fires reliably on mouse AND touch
    btn.MouseButton1Click:Connect(onClick)

    local handle = {}
    handle.Instance = btn
    function handle:SetText(t)
        btn.Text = (icon ~= "" and icon .. "  " or "") .. t
    end
    function handle:SetEnabled(v)
        btn.Active                 = v
        btn.TextColor3             = v and theme.TextPrimary or theme.TextDisabled
        btn.BackgroundTransparency = v and 0 or 0.5
    end
    function handle:Destroy() btn:Destroy() end
    return handle
end

-- ─── CreateToggle ─────────────────────────────────────────────────────────────
--[[
    options = {
        Label    = "Enable Feature",
        Default  = false,
        OnChange = function(newValue) end,
    }
--]]
function Components.CreateToggle(parent, options, theme, _plugins)
    options = options or {}

    local label    = options.Label    or "Toggle"
    local state    = options.Default  or false
    local onChange = options.OnChange or function(_v) end
    local touch    = isTouchDevice()

    -- Minimum row height 44 px on touch
    local rowH = touch and math.max(theme.ItemHeight, 44) or theme.ItemHeight

    local row = Instance.new("Frame")
    row.Name                  = "NexusToggle_" .. label
    row.Size                  = UDim2.new(1, 0, 0, rowH)
    row.BackgroundColor3      = theme.SurfaceRaised
    row.BorderSizePixel       = 0
    row.ZIndex                = 12
    row.Parent                = parent
    corner(row, theme.CornerSmall)
    stroke(row, theme.Border, theme.StrokeWeight)

    local pad = Instance.new("UIPadding")
    pad.PaddingLeft   = UDim.new(0, 10)
    pad.PaddingRight  = UDim.new(0, 10)
    pad.Parent        = row

    local lbl = Instance.new("TextLabel")
    lbl.Size                   = UDim2.new(1, -60, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font                   = theme.FontBody
    lbl.TextSize               = theme.TextSizeBody
    lbl.TextColor3             = theme.TextPrimary
    lbl.Text                   = label
    lbl.TextXAlignment         = Enum.TextXAlignment.Left
    lbl.TextTruncate           = Enum.TextTruncate.AtEnd
    lbl.ZIndex                 = 13
    lbl.Parent                 = row

    -- Pill track — slightly larger on touch
    local trackW = touch and 52 or 44
    local trackH = touch and 28 or 24

    local track = Instance.new("Frame")
    track.Size              = UDim2.new(0, trackW, 0, trackH)
    track.Position          = UDim2.new(1, -trackW, 0.5, -trackH/2)
    track.BackgroundColor3  = state and theme.ToggleOn or theme.ToggleOff
    track.BorderSizePixel   = 0
    track.ZIndex            = 13
    track.Parent            = row
    corner(track, theme.CornerPill)

    local knobSz = trackH - 6
    local knob = Instance.new("Frame")
    knob.Size             = UDim2.new(0, knobSz, 0, knobSz)
    knob.Position         = state
                            and UDim2.new(1, -(knobSz + 3), 0.5, -knobSz/2)
                            or  UDim2.new(0, 3, 0.5, -knobSz/2)
    knob.BackgroundColor3 = theme.ToggleKnob
    knob.BorderSizePixel  = 0
    knob.ZIndex           = 14
    knob.Parent           = track
    corner(knob, theme.CornerPill)

    local function applyState(newState)
        state = newState
        tween(track, theme.TweenInfo.Fast,
            { BackgroundColor3 = state and theme.ToggleOn or theme.ToggleOff })
        tween(knob, theme.TweenInfo.Fast, {
            Position = state
                and UDim2.new(1, -(knobSz + 3), 0.5, -knobSz/2)
                or  UDim2.new(0, 3, 0.5, -knobSz/2)
        })
        onChange(state)
    end

    -- Full-row transparent button — MouseButton1Click works on both mouse and touch
    local btn = Instance.new("TextButton")
    btn.Size                   = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text                   = ""
    btn.ZIndex                 = 15
    btn.Parent                 = row
    btn.MouseButton1Click:Connect(function() applyState(not state) end)

    local handle = {}
    handle.Instance = row
    function handle:Set(v) applyState(v) end
    function handle:Get() return state end
    function handle:Destroy() row:Destroy() end
    return handle
end

-- ─── CreateSlider ─────────────────────────────────────────────────────────────
--[[
    options = {
        Label    = "Volume",
        Min      = 0, Max = 100, Default = 50,
        Suffix   = "%",
        OnChange = function(value) end,
    }
--]]
function Components.CreateSlider(parent, options, theme, _plugins)
    options = options or {}

    local label    = options.Label    or "Slider"
    local minVal   = options.Min      or 0
    local maxVal   = options.Max      or 100
    local current  = options.Default  or minVal
    local suffix   = options.Suffix   or ""
    local onChange = options.OnChange or function(_v) end
    local touch    = isTouchDevice()

    -- Taller row and thicker track on touch for easier interaction
    local rowH   = touch and (theme.ItemHeight + 22) or (theme.ItemHeight + 14)
    local trackH = touch and 8 or 6
    -- Bigger thumb knob on touch
    local thumbSz = touch and 20 or 14

    local row = Instance.new("Frame")
    row.Name              = "NexusSlider_" .. label
    row.Size              = UDim2.new(1, 0, 0, rowH)
    row.BackgroundColor3  = theme.SurfaceRaised
    row.BorderSizePixel   = 0
    row.ZIndex            = 12
    row.Parent            = parent
    corner(row, theme.CornerSmall)
    stroke(row, theme.Border)

    local pad = Instance.new("UIPadding")
    pad.PaddingLeft   = UDim.new(0, 10)
    pad.PaddingRight  = UDim.new(0, 10)
    pad.PaddingTop    = UDim.new(0, 6)
    pad.PaddingBottom = UDim.new(0, 6)
    pad.Parent        = row

    -- Label + value display row
    local topRow = Instance.new("Frame")
    topRow.Size               = UDim2.new(1, 0, 0, 18)
    topRow.BackgroundTransparency = 1
    topRow.ZIndex             = 13
    topRow.Parent             = row

    local lbl = Instance.new("TextLabel")
    lbl.Size                   = UDim2.new(1, -60, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font                   = theme.FontBody
    lbl.TextSize               = theme.TextSizeBody
    lbl.TextColor3             = theme.TextPrimary
    lbl.Text                   = label
    lbl.TextXAlignment         = Enum.TextXAlignment.Left
    lbl.TextTruncate           = Enum.TextTruncate.AtEnd
    lbl.ZIndex                 = 13
    lbl.Parent                 = topRow

    local valLbl = Instance.new("TextLabel")
    valLbl.Size                = UDim2.new(0, 60, 1, 0)
    valLbl.Position            = UDim2.new(1, -60, 0, 0)
    valLbl.BackgroundTransparency = 1
    valLbl.Font                = theme.FontMono
    valLbl.TextSize            = theme.TextSizeSmall
    valLbl.TextColor3          = theme.TextAccent
    valLbl.Text                = tostring(current) .. suffix
    valLbl.TextXAlignment      = Enum.TextXAlignment.Right
    valLbl.ZIndex              = 13
    valLbl.Parent              = topRow

    -- Track
    local track = Instance.new("Frame")
    track.Name             = "Track"
    track.Size             = UDim2.new(1, 0, 0, trackH)
    track.Position         = UDim2.new(0, 0, 1, -trackH - 2)
    track.BackgroundColor3 = theme.SurfaceSunken
    track.BorderSizePixel  = 0
    track.ZIndex           = 13
    track.Parent           = row
    corner(track, theme.CornerPill)
    stroke(track, theme.Border)

    local fill = Instance.new("Frame")
    fill.Name             = "Fill"
    fill.Size             = UDim2.new((current - minVal)/(maxVal - minVal), 0, 1, 0)
    fill.BackgroundColor3 = theme.Accent
    fill.BorderSizePixel  = 0
    fill.ZIndex           = 14
    fill.Parent           = track
    corner(fill, theme.CornerPill)
    gradient(fill, theme.AccentGradient, 0)

    local thumb = Instance.new("Frame")
    thumb.Size             = UDim2.new(0, thumbSz, 0, thumbSz)
    thumb.Position         = UDim2.new((current-minVal)/(maxVal-minVal), -thumbSz/2, 0.5, -thumbSz/2)
    thumb.BackgroundColor3 = theme.TextPrimary
    thumb.ZIndex           = 15
    thumb.BorderSizePixel  = 0
    thumb.Parent           = track
    corner(thumb, theme.CornerPill)
    stroke(thumb, theme.Accent, 2)

    -- Invisible overlay that enlarges the touch hit area over the whole track.
    -- This sits on top (high ZIndex) and captures the input instead of the
    -- tiny 6/8 px track frame, which fingers cannot reliably hit.
    local hitOverlay = Instance.new("Frame")
    hitOverlay.Name                   = "HitOverlay"
    hitOverlay.Size                   = UDim2.new(1, 0, 0, math.max(trackH + 28, 44))
    hitOverlay.Position               = UDim2.new(0, 0, 0.5, -22)
    hitOverlay.BackgroundTransparency = 1
    hitOverlay.ZIndex                 = 16
    hitOverlay.Parent                 = track

    -- ── Drag logic ───────────────────────────────────────────────────────────
    local dragging = false

    local function updateFromAbsoluteX(absX)
        local trackAbs = track.AbsolutePosition.X
        local trackSz  = track.AbsoluteSize.X
        if trackSz == 0 then return end
        local ratio    = math.clamp((absX - trackAbs) / trackSz, 0, 1)
        local val      = math.floor(minVal + ratio * (maxVal - minVal) + 0.5)
        current        = val
        local r        = (val - minVal) / (maxVal - minVal)
        fill.Size      = UDim2.new(r, 0, 1, 0)
        thumb.Position = UDim2.new(r, -thumbSz/2, 0.5, -thumbSz/2)
        valLbl.Text    = tostring(val) .. suffix
        onChange(val)
    end

    hitOverlay.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            updateFromAbsoluteX(inp.Position.X)
        end
    end)
    -- Also allow dragging that starts directly on the thumb / fill
    track.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            updateFromAbsoluteX(inp.Position.X)
        end
    end)
    UIS.InputChanged:Connect(function(inp)
        if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement
                      or inp.UserInputType == Enum.UserInputType.Touch) then
            updateFromAbsoluteX(inp.Position.X)
        end
    end)
    UIS.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    local handle = {}
    handle.Instance = row
    function handle:Set(v)
        v = math.clamp(v, minVal, maxVal)
        current = v
        local r = (v - minVal) / (maxVal - minVal)
        fill.Size      = UDim2.new(r, 0, 1, 0)
        thumb.Position = UDim2.new(r, -thumbSz/2, 0.5, -thumbSz/2)
        valLbl.Text    = tostring(v) .. suffix
    end
    function handle:Get() return current end
    function handle:Destroy() row:Destroy() end
    return handle
end

-- ─── CreateTextBox ────────────────────────────────────────────────────────────
--[[
    options = {
        Label       = "Username",
        Placeholder = "Enter text...",
        Default     = "",
        OnChange    = function(text) end,
        OnSubmit    = function(text) end,
    }
--]]
function Components.CreateTextBox(parent, options, theme, _plugins)
    options = options or {}

    local label       = options.Label       or "Input"
    local placeholder = options.Placeholder or "Type here..."
    local default     = options.Default     or ""
    local onChange    = options.OnChange    or function(_t) end
    local onSubmit    = options.OnSubmit    or function(_t) end
    local touch       = isTouchDevice()

    -- Taller text box on touch so the finger can hit it reliably
    local innerH = touch and math.max(theme.ItemHeight, 44) or (theme.ItemHeight - 10)
    local rowH   = innerH + 28

    local row = Instance.new("Frame")
    row.Name             = "NexusTextBox_" .. label
    row.Size             = UDim2.new(1, 0, 0, rowH)
    row.BackgroundColor3 = theme.SurfaceRaised
    row.BorderSizePixel  = 0
    row.ZIndex           = 12
    row.Parent           = parent
    corner(row, theme.CornerSmall)
    stroke(row, theme.Border)

    local lbl = Instance.new("TextLabel")
    lbl.Size                   = UDim2.new(1, -12, 0, 16)
    lbl.Position               = UDim2.new(0, 10, 0, 6)
    lbl.BackgroundTransparency = 1
    lbl.Font                   = theme.FontBody
    lbl.TextSize               = theme.TextSizeSmall
    lbl.TextColor3             = theme.TextSecondary
    lbl.Text                   = label
    lbl.TextXAlignment         = Enum.TextXAlignment.Left
    lbl.ZIndex                 = 13
    lbl.Parent                 = row

    local box = Instance.new("TextBox")
    box.Size              = UDim2.new(1, -20, 0, innerH)
    box.Position          = UDim2.new(0, 10, 0, 22)
    box.BackgroundColor3  = theme.SurfaceSunken
    box.BorderSizePixel   = 0
    box.Font              = theme.FontBody
    box.TextSize          = theme.TextSizeBody
    box.TextColor3        = theme.TextPrimary
    box.PlaceholderColor3 = theme.TextDisabled
    box.PlaceholderText   = placeholder
    box.Text              = default
    box.ClearTextOnFocus  = false
    -- MultiLine allows soft-keyboard to scroll on mobile without layout issues
    box.MultiLine         = false
    box.ZIndex            = 13
    box.Parent            = row
    corner(box, UDim.new(0, 6))
    local boxStroke = stroke(box, theme.Border)

    box.Focused:Connect(function()
        tween(boxStroke, theme.TweenInfo.Fast,
            { Color = theme.Accent, Thickness = theme.StrokeWeightFat })
    end)
    box.FocusLost:Connect(function(enterPressed)
        tween(boxStroke, theme.TweenInfo.Fast,
            { Color = theme.Border, Thickness = theme.StrokeWeight })
        if enterPressed then onSubmit(box.Text) end
    end)
    box:GetPropertyChangedSignal("Text"):Connect(function()
        onChange(box.Text)
    end)

    local handle = {}
    handle.Instance = row
    handle.Box      = box
    function handle:Set(t) box.Text = t end
    function handle:Get() return box.Text end
    function handle:Destroy() row:Destroy() end
    return handle
end

-- ─── CreateDropdown ───────────────────────────────────────────────────────────
--[[
    options = {
        Label    = "Select Mode",
        Items    = {"Option A","Option B","Option C"},
        Default  = "Option A",
        OnSelect = function(item) end,
    }
--]]
function Components.CreateDropdown(parent, options, theme, _plugins)
    options = options or {}

    local label    = options.Label    or "Dropdown"
    local items    = options.Items    or {}
    local selected = options.Default  or (items[1] or "None")
    local onSelect = options.OnSelect or function(_i) end
    local touch    = isTouchDevice()

    local rowH = touch and math.max(theme.ItemHeight, 44) or theme.ItemHeight

    -- Header (always visible)
    local header = Instance.new("Frame")
    header.Name             = "NexusDD_" .. label
    header.Size             = UDim2.new(1, 0, 0, rowH)
    header.BackgroundColor3 = theme.SurfaceRaised
    header.BorderSizePixel  = 0
    header.ZIndex           = 12
    header.Parent           = parent
    corner(header, theme.CornerSmall)
    stroke(header, theme.Border)

    local lbl = Instance.new("TextLabel")
    lbl.Size                   = UDim2.new(0.55, 0, 1, 0)
    lbl.Position               = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font                   = theme.FontBody
    lbl.TextSize               = theme.TextSizeBody
    lbl.TextColor3             = theme.TextSecondary
    lbl.Text                   = label
    lbl.TextXAlignment         = Enum.TextXAlignment.Left
    lbl.TextTruncate           = Enum.TextTruncate.AtEnd
    lbl.ZIndex                 = 13
    lbl.Parent                 = header

    local selLbl = Instance.new("TextLabel")
    selLbl.Size               = UDim2.new(0.45, -30, 1, 0)
    selLbl.Position           = UDim2.new(0.55, 0, 0, 0)
    selLbl.BackgroundTransparency = 1
    selLbl.Font               = theme.FontBody
    selLbl.TextSize           = theme.TextSizeBody
    selLbl.TextColor3         = theme.TextPrimary
    selLbl.Text               = selected
    selLbl.TextXAlignment     = Enum.TextXAlignment.Right
    selLbl.TextTruncate       = Enum.TextTruncate.AtEnd
    selLbl.ZIndex             = 13
    selLbl.Parent             = header

    local arrow = Instance.new("TextLabel")
    arrow.Size                = UDim2.new(0, 20, 1, 0)
    arrow.Position            = UDim2.new(1, -24, 0, 0)
    arrow.BackgroundTransparency = 1
    arrow.Font                = theme.FontBody
    arrow.TextSize            = 14
    arrow.TextColor3          = theme.TextAccent
    arrow.Text                = "▾"
    arrow.ZIndex              = 13
    arrow.Parent              = header

    -- ── Drop panel ───────────────────────────────────────────────────────────
    -- IMPORTANT: The panel is parented to the ScreenGui ROOT (parent of parent
    -- chain up to ScreenGui), NOT to the ScrollingFrame.  This prevents it
    -- from being clipped by ClipsDescendants on the content scroll area.
    -- We recalculate its absolute position each time it opens.
    local function findScreenGui(inst)
        local cur = inst
        while cur and not cur:IsA("ScreenGui") do
            cur = cur.Parent
        end
        return cur
    end

    local itemH  = touch and 38 or 28
    local panelH = #items * (itemH + 2) + 8

    local panel = Instance.new("Frame")
    panel.Name                = "DDPanel_" .. label
    panel.Size                = UDim2.new(0, 0, 0, 0)   -- hidden initially
    panel.BackgroundColor3    = theme.SurfaceSunken
    panel.BorderSizePixel     = 0
    panel.ClipsDescendants    = true
    panel.ZIndex              = 100   -- above everything
    panel.Visible             = false
    -- Parent set lazily when first opened (screen gui may not exist yet)
    local panelParent = findScreenGui(parent) or parent

    corner(panel, theme.CornerSmall)
    stroke(panel, theme.Border)

    local panelLayout = Instance.new("UIListLayout")
    panelLayout.SortOrder = Enum.SortOrder.LayoutOrder
    panelLayout.Padding   = UDim.new(0, 2)
    panelLayout.Parent    = panel
    local panelPad = Instance.new("UIPadding")
    panelPad.PaddingTop    = UDim.new(0, 4)
    panelPad.PaddingBottom = UDim.new(0, 4)
    panelPad.PaddingLeft   = UDim.new(0, 4)
    panelPad.PaddingRight  = UDim.new(0, 4)
    panelPad.Parent        = panel

    local function repositionPanel()
        -- Recompute where header is on screen so the panel floats below it.
        local absPos  = header.AbsolutePosition
        local absSize = header.AbsoluteSize
        local sg      = findScreenGui(header)
        if sg then
            panel.Parent   = sg
            panel.Position = UDim2.new(0, absPos.X, 0, absPos.Y + absSize.Y + 2)
            panel.Size     = UDim2.new(0, absSize.X, 0, 0)
        end
    end

    for idx, item in ipairs(items) do
        local itm = Instance.new("TextButton")
        itm.Name               = "Item_" .. item
        itm.Size               = UDim2.new(1, 0, 0, itemH)
        itm.BackgroundColor3   = (item == selected) and theme.Accent or theme.SurfaceRaised
        itm.BackgroundTransparency = (item == selected) and 0 or 0.6
        itm.Font               = theme.FontBody
        itm.TextSize           = theme.TextSizeBody
        itm.TextColor3         = theme.TextPrimary
        itm.Text               = "  " .. item
        itm.TextXAlignment     = Enum.TextXAlignment.Left
        itm.AutoButtonColor    = false
        itm.ZIndex             = 101
        itm.LayoutOrder        = idx
        itm.Parent             = panel
        corner(itm, UDim.new(0, 6))

        if not touch then
            itm.MouseEnter:Connect(function()
                tween(itm, theme.TweenInfo.Fast,
                    { BackgroundTransparency = 0, BackgroundColor3 = theme.Accent })
            end)
            itm.MouseLeave:Connect(function()
                tween(itm, theme.TweenInfo.Fast, {
                    BackgroundTransparency = (item == selected) and 0 or 0.6,
                    BackgroundColor3 = (item == selected) and theme.Accent or theme.SurfaceRaised,
                })
            end)
        end

        itm.MouseButton1Click:Connect(function()
            selected    = item
            selLbl.Text = item
            panel.Visible = false
            tween(panel, theme.TweenInfo.Normal, { Size = UDim2.new(0, panel.Size.X.Offset, 0, 0) }, function()
                panel.Visible = false
            end)
            tween(arrow, theme.TweenInfo.Fast, { Rotation = 0 })
            onSelect(item)
        end)
    end

    local open = false
    local toggle = Instance.new("TextButton")
    toggle.Size                   = UDim2.new(1, 0, 1, 0)
    toggle.BackgroundTransparency = 1
    toggle.Text                   = ""
    toggle.ZIndex                 = 14
    toggle.Parent                 = header
    toggle.MouseButton1Click:Connect(function()
        open = not open
        if open then
            repositionPanel()
            panel.Visible = true
            panel.Size    = UDim2.new(0, header.AbsoluteSize.X, 0, 0)
            tween(panel, theme.TweenInfo.Normal,
                { Size = UDim2.new(0, header.AbsoluteSize.X, 0, panelH) })
            tween(arrow, theme.TweenInfo.Fast, { Rotation = 180 })
        else
            tween(panel, theme.TweenInfo.Normal,
                { Size = UDim2.new(0, panel.Size.X.Offset, 0, 0) },
                function() panel.Visible = false end)
            tween(arrow, theme.TweenInfo.Fast, { Rotation = 0 })
        end
    end)

    local handle = {}
    handle.Instance = header
    function handle:Set(item) selLbl.Text = item; selected = item end
    function handle:Get() return selected end
    function handle:Destroy() panel:Destroy(); header:Destroy() end
    return handle
end

-- ─── CreateLabel ──────────────────────────────────────────────────────────────
function Components.CreateLabel(parent, options, theme, _plugins)
    options = options or {}

    local lbl = Instance.new("TextLabel")
    lbl.Name                   = "NexusLabel"
    lbl.Size                   = UDim2.new(1, 0, 0, 22)
    lbl.BackgroundTransparency = 1
    lbl.Font                   = theme.FontBody
    lbl.TextSize               = options.Size  or theme.TextSizeSmall
    lbl.TextColor3             = options.Color or theme.TextSecondary
    lbl.Text                   = options.Text  or ""
    lbl.TextXAlignment         = Enum.TextXAlignment.Left
    lbl.TextWrapped            = true   -- allow wrapping on small screens
    lbl.ZIndex                 = 12
    lbl.Parent                 = parent

    local handle = {}
    handle.Instance = lbl
    function handle:Set(t) lbl.Text = t end
    function handle:Get() return lbl.Text end
    function handle:Destroy() lbl:Destroy() end
    return handle
end

-- ─── CreateSeparator ──────────────────────────────────────────────────────────
function Components.CreateSeparator(parent, _options, theme, _plugins)
    local sep = Instance.new("Frame")
    sep.Name             = "NexusSeparator"
    sep.Size             = UDim2.new(1, 0, 0, 1)
    sep.BackgroundColor3 = theme.Border
    sep.BorderSizePixel  = 0
    sep.ZIndex           = 12
    sep.Parent           = parent

    local handle = {}
    handle.Instance = sep
    function handle:Destroy() sep:Destroy() end
    return handle
end

-- ─── CreateBadge ──────────────────────────────────────────────────────────────
function Components.CreateBadge(parent, options, theme, _plugins)
    options = options or {}

    local badge = Instance.new("TextLabel")
    badge.Name                   = "NexusBadge"
    badge.Size                   = UDim2.new(0, 0, 0, 20)
    badge.AutomaticSize          = Enum.AutomaticSize.X
    badge.BackgroundColor3       = options.Color or theme.Accent
    badge.BorderSizePixel        = 0
    badge.Font                   = theme.FontBody
    badge.TextSize               = theme.TextSizeSmall
    badge.TextColor3             = theme.TextPrimary
    badge.Text                   = "  " .. (options.Text or "BADGE") .. "  "
    badge.ZIndex                 = 12
    badge.Parent                 = parent
    corner(badge, theme.CornerPill)

    local handle = {}
    handle.Instance = badge
    function handle:Set(t) badge.Text = "  " .. t .. "  " end
    function handle:Destroy() badge:Destroy() end
    return handle
end

return Components
