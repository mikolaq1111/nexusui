--[[
    components.lua  (ui-library)
    ============================
    All individual UI widget constructors.  Each function receives:
        • parent  — the Frame or ScrollingFrame to attach this widget to
        • options — a table with widget-specific settings (see each section)
        • theme   — the shared Theme table from theme.lua
        • plugins — the Plugin table from plugin-libray (tween, drag helpers)

    Every function returns a "handle" table that exposes:
        • Instance  — the root GuiObject
        • Set(...)  — programmatic state setter
        • Get(...)  — programmatic state getter
        • Destroy() — clean removal

    ────────────────────────────────────────────────────────────────────────────
    COMPONENT LIST
        CreateWindow   — draggable floating window with title / close / tab strip
        CreateTab      — named section inside a window
        CreateButton   — animated press-feedback button
        CreateToggle   — pill-style on/off switch
        CreateSlider   — ranged numeric slider with value label
        CreateTextBox  — labelled input field
        CreateDropdown — animated dropdown selector
        CreateLabel    — static text block
        CreateSeparator— thin horizontal rule
        CreateBadge    — small inline status chip
    ────────────────────────────────────────────────────────────────────────────
--]]

local Components = {}

-- ─── Internal helpers ────────────────────────────────────────────────────────

-- Quickly apply a tween and optionally call a callback on completion.
local function tween(instance, tweenInfo, props, callback)
    local ts = game:GetService("TweenService")
    local t  = ts:Create(instance, tweenInfo, props)
    if callback then t.Completed:Once(callback) end
    t:Play()
    return t
end

-- Add a UICorner to an instance.
local function corner(inst, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = radius or UDim.new(0, 8)
    c.Parent = inst
    return c
end

-- Add a UIStroke to an instance.
local function stroke(inst, color, thickness, transparency)
    local s = Instance.new("UIStroke")
    s.Color        = color or Color3.fromRGB(60, 60, 90)
    s.Thickness    = thickness or 1
    s.Transparency = transparency or 0
    s.Parent       = inst
    return s
end

-- Add a UIGradient to an instance's background.
local function gradient(inst, colorSeq, rotation)
    local g = Instance.new("UIGradient")
    g.Color    = colorSeq
    g.Rotation = rotation or 0
    g.Parent   = inst
    return g
end

-- Helper: make ambient glow beneath/around a frame.
local function makeGlow(parent, glowColor, transparency)
    local glow = Instance.new("Frame")
    glow.Name              = "GlowEffect"
    glow.Size              = UDim2.new(1, 30, 1, 30)
    glow.Position          = UDim2.new(0, -15, 0, -15)
    glow.BackgroundColor3  = glowColor
    glow.BackgroundTransparency = transparency or 0.82
    glow.ZIndex            = parent.ZIndex - 1
    glow.BorderSizePixel   = 0
    corner(glow, UDim.new(0, 18))
    glow.Parent            = parent
    return glow
end

-- ─── CreateWindow ─────────────────────────────────────────────────────────────
--[[
    options = {
        Title       = "My Window",
        Size        = UDim2.new(0, 380, 0, 480),   -- optional
        Position    = UDim2.new(0.5,-190,0.5,-240), -- optional centre
        CanClose    = true,                          -- show X button
        CanMinimise = true,                          -- show _ button
        Tabs        = {"Main","Settings","About"},   -- tab names
    }
--]]
function Components.CreateWindow(parent, options, theme, plugins)
    options = options or {}

    local title      = options.Title       or "NexusUI"
    local winSize    = options.Size        or UDim2.new(0, theme.WindowWidth, 0, 480)
    local winPos     = options.Position    or UDim2.new(0.5, -theme.WindowWidth/2, 0.5, -240)
    local canClose   = options.CanClose    ~= false
    local canMin     = options.CanMinimise ~= false
    local tabNames   = options.Tabs        or {"Main"}

    -- ── Root frame ──────────────────────────────────────────────────────────
    local window = Instance.new("Frame")
    window.Name                  = "NexusWindow_" .. title
    window.Size                  = UDim2.new(0, 1, 0, 1)   -- starts tiny → springs open
    window.Position              = winPos
    window.AnchorPoint           = Vector2.new(0, 0)
    window.BackgroundColor3      = theme.Surface
    window.BackgroundTransparency = theme.WindowTransparency
    window.BorderSizePixel       = 0
    window.ClipsDescendants      = true
    window.ZIndex                = 10
    window.Parent                = parent
    corner(window, theme.CornerRadius)
    stroke(window, theme.Border, theme.StrokeWeight)
    makeGlow(window, theme.GlowColor, theme.GlowTransparency)

    -- Entrance spring animation
    tween(window, theme.TweenInfo.Spring, { Size = winSize })

    -- ── Title bar ────────────────────────────────────────────────────────────
    local titleBar = Instance.new("Frame")
    titleBar.Name             = "TitleBar"
    titleBar.Size             = UDim2.new(1, 0, 0, theme.TitleBarHeight)
    titleBar.BackgroundColor3 = theme.AccentDark
    titleBar.BorderSizePixel  = 0
    titleBar.ZIndex           = 11
    titleBar.Parent           = window
    corner(titleBar, theme.CornerRadius)
    -- Only round top corners: cover lower corners with an opaque strip
    local titleCover = Instance.new("Frame")
    titleCover.Size             = UDim2.new(1, 0, 0, theme.CornerRadius.Offset)
    titleCover.Position         = UDim2.new(0, 0, 1, -theme.CornerRadius.Offset)
    titleCover.BackgroundColor3 = theme.AccentDark
    titleCover.BorderSizePixel  = 0
    titleCover.ZIndex           = 11
    titleCover.Parent           = titleBar
    gradient(titleBar, theme.AccentGradient, 90)

    -- Window icon (decorative dot strip)
    local dots = Instance.new("Frame")
    dots.Name            = "Dots"
    dots.Size            = UDim2.new(0, 48, 0, 10)
    dots.Position        = UDim2.new(0, 12, 0.5, -5)
    dots.BackgroundTransparency = 1
    dots.ZIndex          = 12
    dots.Parent          = titleBar
    for i, col in ipairs({theme.Danger, theme.Warning, theme.Success}) do
        local dot = Instance.new("Frame")
        dot.Size                 = UDim2.new(0, 10, 0, 10)
        dot.Position             = UDim2.new(0, (i-1)*16, 0, 0)
        dot.BackgroundColor3     = col
        dot.BorderSizePixel      = 0
        dot.ZIndex               = 12
        dot.Parent               = dots
        corner(dot, UDim.new(1, 0))
    end

    -- Title label
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name              = "Title"
    titleLabel.Size              = UDim2.new(1, -120, 1, 0)
    titleLabel.Position          = UDim2.new(0, 60, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Font              = theme.FontTitle
    titleLabel.TextSize          = theme.TextSizeTitle
    titleLabel.TextColor3        = theme.TextPrimary
    titleLabel.Text              = title
    titleLabel.TextXAlignment    = Enum.TextXAlignment.Left
    titleLabel.ZIndex            = 12
    titleLabel.Parent            = titleBar

    -- Close / Minimise buttons (right side)
    local btnX = theme.TitleBarHeight - 10  -- button size
    local function makeTitleBtn(icon, xOffset, bgColor, hoverColor, onClick)
        local btn = Instance.new("TextButton")
        btn.Size                 = UDim2.new(0, btnX, 0, btnX)
        btn.Position             = UDim2.new(1, xOffset, 0.5, -btnX/2)
        btn.BackgroundColor3     = bgColor
        btn.Font                 = theme.FontBody
        btn.TextSize             = 12
        btn.Text                 = icon
        btn.TextColor3           = theme.TextPrimary
        btn.BorderSizePixel      = 0
        btn.ZIndex               = 13
        btn.Parent               = titleBar
        corner(btn, UDim.new(1, 0))
        btn.MouseEnter:Connect(function()
            tween(btn, theme.TweenInfo.Fast, { BackgroundColor3 = hoverColor })
        end)
        btn.MouseLeave:Connect(function()
            tween(btn, theme.TweenInfo.Fast, { BackgroundColor3 = bgColor })
        end)
        btn.MouseButton1Click:Connect(onClick)
        return btn
    end

    local minimised = false
    if canClose then
        makeTitleBtn("✕", -10, Color3.fromRGB(60,30,40), theme.Danger, function()
            -- Shrink then destroy
            tween(window, theme.TweenInfo.Normal, { Size = UDim2.new(0,1,0,1), BackgroundTransparency = 1 }, function()
                window:Destroy()
            end)
        end)
    end
    if canMin then
        local minOffset = canClose and -(10 + btnX + 6) or -10
        makeTitleBtn("–", minOffset, Color3.fromRGB(40,50,30), theme.Success, function()
            minimised = not minimised
            if minimised then
                tween(window, theme.TweenInfo.Normal, { Size = UDim2.new(0, winSize.X.Offset, 0, theme.TitleBarHeight) })
            else
                tween(window, theme.TweenInfo.Spring, { Size = winSize })
            end
        end)
    end

    -- ── Drag via plugin helper ────────────────────────────────────────────────
    if plugins and plugins.Drag then
        plugins.Drag.makeDraggable(window, titleBar)
    end

    -- ── Tab strip ────────────────────────────────────────────────────────────
    local tabStrip = Instance.new("Frame")
    tabStrip.Name             = "TabStrip"
    tabStrip.Size             = UDim2.new(1, 0, 0, 32)
    tabStrip.Position         = UDim2.new(0, 0, 0, theme.TitleBarHeight)
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

    -- ── Content area (scrollable) ─────────────────────────────────────────────
    local contentFrames = {}   -- tab name → ScrollingFrame
    local activeTab     = nil
    local tabButtons    = {}

    local function switchTab(name)
        if activeTab == name then return end
        activeTab = name
        for tname, frame in pairs(contentFrames) do
            tween(frame, theme.TweenInfo.Fast, {
                BackgroundTransparency = 1,
                Position = (tname == name)
                    and UDim2.new(0,0,0,0)
                    or  UDim2.new(0.05,0,0,0),
            })
            frame.Visible = (tname == name)
        end
        for tname, tbtn in pairs(tabButtons) do
            local active = (tname == name)
            tween(tbtn, theme.TweenInfo.Fast, {
                BackgroundColor3 = active and theme.Accent or Color3.fromRGB(0,0,0),
                BackgroundTransparency = active and 0 or 1,
                TextColor3 = active and theme.TextPrimary or theme.TextSecondary,
            })
        end
    end

    for i, tabName in ipairs(tabNames) do
        -- Button in tab strip
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

        -- Scrollable content frame for this tab
        local content = Instance.new("ScrollingFrame")
        content.Name                    = "Content_" .. tabName
        content.Size                    = UDim2.new(1, 0, 1, -(theme.TitleBarHeight + 32))
        content.Position                = UDim2.new(0, 0, 0, theme.TitleBarHeight + 32)
        content.BackgroundTransparency  = 1
        content.BorderSizePixel         = 0
        content.ScrollBarThickness      = 4
        content.ScrollBarImageColor3    = theme.ScrollBar
        content.CanvasSize              = UDim2.new(0, 0, 0, 0)
        content.AutomaticCanvasSize     = Enum.AutomaticSize.Y
        content.Visible                 = (i == 1)
        content.ZIndex                  = 11
        content.Parent                  = window
        contentFrames[tabName]          = content

        local listLayout = Instance.new("UIListLayout")
        listLayout.SortOrder  = Enum.SortOrder.LayoutOrder
        listLayout.Padding    = UDim.new(0, theme.ItemSpacing)
        listLayout.Parent     = content
        local pad = Instance.new("UIPadding")
        pad.PaddingLeft   = UDim.new(0, theme.Padding)
        pad.PaddingRight  = UDim.new(0, theme.Padding)
        pad.PaddingTop    = UDim.new(0, theme.Padding)
        pad.PaddingBottom = UDim.new(0, theme.Padding)
        pad.Parent        = content

        tbtn.MouseButton1Click:Connect(function()
            switchTab(tabName)
        end)
    end

    activeTab = tabNames[1]

    -- ── Public handle ─────────────────────────────────────────────────────────
    local handle = {}
    handle.Instance = window

    --- Returns the ScrollingFrame for the given tab name.
    function handle:GetTab(name)
        return contentFrames[name]
    end

    --- Returns the first (or only) content frame for quick single-tab windows.
    function handle:GetContent()
        return contentFrames[tabNames[1]]
    end

    function handle:Destroy()
        window:Destroy()
    end

    return handle
end

-- ─── CreateButton ─────────────────────────────────────────────────────────────
--[[
    options = {
        Text      = "Click Me",
        Icon      = "🚀",           -- optional leading emoji / character
        OnClick   = function() end,
        Danger    = false,          -- red variant
        Primary   = true,          -- solid accent background (default)
    }
--]]
function Components.CreateButton(parent, options, theme, _plugins)
    options = options or {}

    local btnText  = options.Text    or "Button"
    local icon     = options.Icon    or ""
    local onClick  = options.OnClick or function() end
    local isDanger = options.Danger  or false
    local isPrimary = options.Primary ~= false

    local baseBg   = isDanger  and theme.Danger
                   or isPrimary and theme.Accent
                   or theme.SurfaceRaised
    local hoverBg  = isDanger  and Color3.fromRGB(255, 100, 120)
                   or isPrimary and theme.AccentLight
                   or theme.Border

    local btn = Instance.new("TextButton")
    btn.Name                   = "NexusBtn_" .. btnText
    btn.Size                   = UDim2.new(1, 0, 0, theme.ItemHeight)
    btn.BackgroundColor3       = baseBg
    btn.BorderSizePixel        = 0
    btn.Font                   = theme.FontBody
    btn.TextSize               = theme.TextSizeBody
    btn.TextColor3             = theme.TextPrimary
    btn.Text                   = (icon ~= "" and icon .. "  " or "") .. btnText
    btn.AutoButtonColor        = false
    btn.ZIndex                 = 12
    btn.Parent                 = parent
    corner(btn, theme.CornerSmall)

    -- Gradient shimmer on primary buttons
    if isPrimary and not isDanger then
        gradient(btn, theme.AccentGradient, 90)
    end

    -- Hover / press animations
    btn.MouseEnter:Connect(function()
        tween(btn, theme.TweenInfo.Fast, { BackgroundColor3 = hoverBg, Size = UDim2.new(1, 0, 0, theme.ItemHeight + 2) })
    end)
    btn.MouseLeave:Connect(function()
        tween(btn, theme.TweenInfo.Fast, { BackgroundColor3 = baseBg, Size = UDim2.new(1, 0, 0, theme.ItemHeight) })
    end)
    btn.MouseButton1Down:Connect(function()
        tween(btn, theme.TweenInfo.Fast, { Size = UDim2.new(1, -4, 0, theme.ItemHeight - 3), BackgroundTransparency = 0.15 })
    end)
    btn.MouseButton1Up:Connect(function()
        tween(btn, theme.TweenInfo.Fast, { Size = UDim2.new(1, 0, 0, theme.ItemHeight), BackgroundTransparency = 0 })
        onClick()
    end)
    -- Also fire on plain click for touch devices
    btn.MouseButton1Click:Connect(function() end)  -- already handled above

    local handle = {}
    handle.Instance = btn
    function handle:SetText(t) btn.Text = (icon ~= "" and icon .. "  " or "") .. t end
    function handle:SetEnabled(v)
        btn.Active        = v
        btn.TextColor3    = v and theme.TextPrimary or theme.TextDisabled
        btn.BackgroundTransparency = v and 0 or 0.5
    end
    function handle:Destroy() btn:Destroy() end
    return handle
end

-- ─── CreateToggle ─────────────────────────────────────────────────────────────
--[[
    options = {
        Label     = "Enable Feature",
        Default   = false,
        OnChange  = function(newValue) end,
    }
--]]
function Components.CreateToggle(parent, options, theme, _plugins)
    options = options or {}

    local label    = options.Label    or "Toggle"
    local state    = options.Default  or false
    local onChange = options.OnChange or function(_v) end

    -- Row container
    local row = Instance.new("Frame")
    row.Name                  = "NexusToggle_" .. label
    row.Size                  = UDim2.new(1, 0, 0, theme.ItemHeight)
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

    -- Label text
    local lbl = Instance.new("TextLabel")
    lbl.Size                  = UDim2.new(1, -54, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font                  = theme.FontBody
    lbl.TextSize              = theme.TextSizeBody
    lbl.TextColor3            = theme.TextPrimary
    lbl.Text                  = label
    lbl.TextXAlignment        = Enum.TextXAlignment.Left
    lbl.ZIndex                = 13
    lbl.Parent                = row

    -- Pill track
    local trackW, trackH = 44, 24
    local track = Instance.new("Frame")
    track.Size              = UDim2.new(0, trackW, 0, trackH)
    track.Position          = UDim2.new(1, -trackW, 0.5, -trackH/2)
    track.BackgroundColor3  = state and theme.ToggleOn or theme.ToggleOff
    track.BorderSizePixel   = 0
    track.ZIndex            = 13
    track.Parent            = row
    corner(track, theme.CornerPill)

    -- Knob
    local knobSz = trackH - 6
    local knob = Instance.new("Frame")
    knob.Size              = UDim2.new(0, knobSz, 0, knobSz)
    knob.Position          = state
                             and UDim2.new(1, -(knobSz + 3), 0.5, -knobSz/2)
                             or  UDim2.new(0, 3, 0.5, -knobSz/2)
    knob.BackgroundColor3  = theme.ToggleKnob
    knob.BorderSizePixel   = 0
    knob.ZIndex            = 14
    knob.Parent            = track
    corner(knob, theme.CornerPill)

    local function applyState(newState)
        state = newState
        tween(track, theme.TweenInfo.Fast, {
            BackgroundColor3 = state and theme.ToggleOn or theme.ToggleOff
        })
        tween(knob, theme.TweenInfo.Fast, {
            Position = state
                and UDim2.new(1, -(knobSz + 3), 0.5, -knobSz/2)
                or  UDim2.new(0, 3, 0.5, -knobSz/2)
        })
        onChange(state)
    end

    -- Clickable overlay
    local btn = Instance.new("TextButton")
    btn.Size               = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text               = ""
    btn.ZIndex             = 15
    btn.Parent             = row
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
        Min      = 0,
        Max      = 100,
        Default  = 50,
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

    local rowH = theme.ItemHeight + 14   -- slightly taller row for the track

    local row = Instance.new("Frame")
    row.Name                  = "NexusSlider_" .. label
    row.Size                  = UDim2.new(1, 0, 0, rowH)
    row.BackgroundColor3      = theme.SurfaceRaised
    row.BorderSizePixel       = 0
    row.ZIndex                = 12
    row.Parent                = parent
    corner(row, theme.CornerSmall)
    stroke(row, theme.Border)

    local pad = Instance.new("UIPadding")
    pad.PaddingLeft   = UDim.new(0, 10)
    pad.PaddingRight  = UDim.new(0, 10)
    pad.PaddingTop    = UDim.new(0, 6)
    pad.PaddingBottom = UDim.new(0, 6)
    pad.Parent        = row

    -- Top row: label + value
    local topRow = Instance.new("Frame")
    topRow.Size               = UDim2.new(1, 0, 0, 18)
    topRow.BackgroundTransparency = 1
    topRow.ZIndex             = 13
    topRow.Parent             = row
    local topLayout = Instance.new("UIListLayout")
    topLayout.FillDirection   = Enum.FillDirection.Horizontal
    topLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    topLayout.VerticalAlignment   = Enum.VerticalAlignment.Center
    topLayout.Parent          = topRow

    local lbl = Instance.new("TextLabel")
    lbl.Size                  = UDim2.new(1, -60, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font                  = theme.FontBody
    lbl.TextSize              = theme.TextSizeBody
    lbl.TextColor3            = theme.TextPrimary
    lbl.Text                  = label
    lbl.TextXAlignment        = Enum.TextXAlignment.Left
    lbl.ZIndex                = 13
    lbl.Parent                = topRow

    local valLbl = Instance.new("TextLabel")
    valLbl.Size               = UDim2.new(0, 60, 1, 0)
    valLbl.BackgroundTransparency = 1
    valLbl.Font               = theme.FontMono
    valLbl.TextSize           = theme.TextSizeSmall
    valLbl.TextColor3         = theme.TextAccent
    valLbl.Text               = tostring(current) .. suffix
    valLbl.TextXAlignment     = Enum.TextXAlignment.Right
    valLbl.ZIndex             = 13
    valLbl.Parent             = topRow

    -- Track background
    local trackH = 6
    local track = Instance.new("Frame")
    track.Name                = "Track"
    track.Size                = UDim2.new(1, 0, 0, trackH)
    track.Position            = UDim2.new(0, 0, 1, -trackH - 2)
    track.BackgroundColor3    = theme.SurfaceSunken
    track.BorderSizePixel     = 0
    track.ZIndex              = 13
    track.Parent              = row
    corner(track, theme.CornerPill)
    stroke(track, theme.Border)

    -- Filled portion
    local fill = Instance.new("Frame")
    fill.Name                 = "Fill"
    fill.Size                 = UDim2.new((current - minVal)/(maxVal - minVal), 0, 1, 0)
    fill.BackgroundColor3     = theme.Accent
    fill.BorderSizePixel      = 0
    fill.ZIndex               = 14
    fill.Parent               = track
    corner(fill, theme.CornerPill)
    gradient(fill, theme.AccentGradient, 0)

    -- Thumb knob
    local thumbSz = 14
    local thumb = Instance.new("Frame")
    thumb.Size               = UDim2.new(0, thumbSz, 0, thumbSz)
    thumb.Position           = UDim2.new((current-minVal)/(maxVal-minVal), -thumbSz/2, 0.5, -thumbSz/2)
    thumb.BackgroundColor3   = theme.TextPrimary
    thumb.ZIndex             = 15
    thumb.BorderSizePixel    = 0
    thumb.Parent             = track
    corner(thumb, theme.CornerPill)
    stroke(thumb, theme.Accent, 2)

    -- ── Drag logic ───────────────────────────────────────────────────────────
    local UIS = game:GetService("UserInputService")
    local dragging = false

    local function updateFromAbsoluteX(absX)
        local trackAbs = track.AbsolutePosition.X
        local trackSz  = track.AbsoluteSize.X
        local ratio    = math.clamp((absX - trackAbs) / trackSz, 0, 1)
        local val      = math.floor(minVal + ratio * (maxVal - minVal) + 0.5)
        current        = val
        local fillRatio = (val - minVal) / (maxVal - minVal)
        fill.Size     = UDim2.new(fillRatio, 0, 1, 0)
        thumb.Position = UDim2.new(fillRatio, -thumbSz/2, 0.5, -thumbSz/2)
        valLbl.Text   = tostring(val) .. suffix
        onChange(val)
    end

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

    local label    = options.Label       or "Input"
    local placeholder = options.Placeholder or "Type here..."
    local default  = options.Default     or ""
    local onChange = options.OnChange    or function(_t) end
    local onSubmit = options.OnSubmit    or function(_t) end

    local rowH = theme.ItemHeight + 14

    local row = Instance.new("Frame")
    row.Name                  = "NexusTextBox_" .. label
    row.Size                  = UDim2.new(1, 0, 0, rowH)
    row.BackgroundColor3      = theme.SurfaceRaised
    row.BorderSizePixel       = 0
    row.ZIndex                = 12
    row.Parent                = parent
    corner(row, theme.CornerSmall)
    stroke(row, theme.Border)

    local lbl = Instance.new("TextLabel")
    lbl.Size                  = UDim2.new(1, -12, 0, 16)
    lbl.Position              = UDim2.new(0, 10, 0, 6)
    lbl.BackgroundTransparency = 1
    lbl.Font                  = theme.FontBody
    lbl.TextSize              = theme.TextSizeSmall
    lbl.TextColor3            = theme.TextSecondary
    lbl.Text                  = label
    lbl.TextXAlignment        = Enum.TextXAlignment.Left
    lbl.ZIndex                = 13
    lbl.Parent                = row

    local box = Instance.new("TextBox")
    box.Size                  = UDim2.new(1, -20, 0, theme.ItemHeight - 10)
    box.Position              = UDim2.new(0, 10, 0, 22)
    box.BackgroundColor3      = theme.SurfaceSunken
    box.BorderSizePixel       = 0
    box.Font                  = theme.FontBody
    box.TextSize              = theme.TextSizeBody
    box.TextColor3            = theme.TextPrimary
    box.PlaceholderColor3     = theme.TextDisabled
    box.PlaceholderText       = placeholder
    box.Text                  = default
    box.ClearTextOnFocus      = false
    box.ZIndex                = 13
    box.Parent                = row
    corner(box, UDim.new(0, 6))
    local boxStroke = stroke(box, theme.Border)

    box.Focused:Connect(function()
        tween(boxStroke, theme.TweenInfo.Fast, { Color = theme.Accent, Thickness = theme.StrokeWeightFat })
    end)
    box.FocusLost:Connect(function(enterPressed)
        tween(boxStroke, theme.TweenInfo.Fast, { Color = theme.Border, Thickness = theme.StrokeWeight })
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

    -- Header row (always visible)
    local header = Instance.new("Frame")
    header.Name                 = "NexusDD_" .. label
    header.Size                 = UDim2.new(1, 0, 0, theme.ItemHeight)
    header.BackgroundColor3     = theme.SurfaceRaised
    header.BorderSizePixel      = 0
    header.ZIndex               = 12
    header.Parent               = parent
    corner(header, theme.CornerSmall)
    stroke(header, theme.Border)

    local lbl = Instance.new("TextLabel")
    lbl.Size                  = UDim2.new(0.5, 0, 1, 0)
    lbl.Position              = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font                  = theme.FontBody
    lbl.TextSize              = theme.TextSizeBody
    lbl.TextColor3            = theme.TextSecondary
    lbl.Text                  = label
    lbl.TextXAlignment        = Enum.TextXAlignment.Left
    lbl.ZIndex                = 13
    lbl.Parent                = header

    local selLbl = Instance.new("TextLabel")
    selLbl.Size               = UDim2.new(0.5, -30, 1, 0)
    selLbl.Position           = UDim2.new(0.5, 0, 0, 0)
    selLbl.BackgroundTransparency = 1
    selLbl.Font               = theme.FontBody
    selLbl.TextSize           = theme.TextSizeBody
    selLbl.TextColor3         = theme.TextPrimary
    selLbl.Text               = selected
    selLbl.TextXAlignment     = Enum.TextXAlignment.Right
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

    -- Drop panel
    local itemH   = 28
    local panelH  = #items * (itemH + 2) + 8
    local panel   = Instance.new("Frame")
    panel.Name                = "DDPanel"
    panel.Size                = UDim2.new(1, 0, 0, 0)   -- collapsed
    panel.Position            = UDim2.new(0, 0, 1, 2)
    panel.BackgroundColor3    = theme.SurfaceSunken
    panel.BorderSizePixel     = 0
    panel.ClipsDescendants    = true
    panel.ZIndex              = 20
    panel.Visible             = false
    panel.Parent              = header
    corner(panel, theme.CornerSmall)
    stroke(panel, theme.Border)

    local panelLayout = Instance.new("UIListLayout")
    panelLayout.SortOrder   = Enum.SortOrder.LayoutOrder
    panelLayout.Padding     = UDim.new(0, 2)
    panelLayout.Parent      = panel
    local panelPad = Instance.new("UIPadding")
    panelPad.PaddingTop    = UDim.new(0, 4)
    panelPad.PaddingBottom = UDim.new(0, 4)
    panelPad.PaddingLeft   = UDim.new(0, 4)
    panelPad.PaddingRight  = UDim.new(0, 4)
    panelPad.Parent        = panel

    for _, item in ipairs(items) do
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
        itm.ZIndex             = 21
        itm.Parent             = panel
        corner(itm, UDim.new(0, 6))
        itm.MouseEnter:Connect(function()
            tween(itm, theme.TweenInfo.Fast, { BackgroundTransparency = 0, BackgroundColor3 = theme.Accent })
        end)
        itm.MouseLeave:Connect(function()
            tween(itm, theme.TweenInfo.Fast, {
                BackgroundTransparency = (item == selected) and 0 or 0.6,
                BackgroundColor3 = (item == selected) and theme.Accent or theme.SurfaceRaised,
            })
        end)
        itm.MouseButton1Click:Connect(function()
            selected     = item
            selLbl.Text  = item
            -- Collapse
            panel.Visible = false
            tween(panel, theme.TweenInfo.Normal, { Size = UDim2.new(1, 0, 0, 0) }, function()
                panel.Visible = false
            end)
            tween(arrow, theme.TweenInfo.Fast, { Rotation = 0 })
            onSelect(item)
        end)
    end

    local open = false
    local toggle = Instance.new("TextButton")
    toggle.Size               = UDim2.new(1, 0, 1, 0)
    toggle.BackgroundTransparency = 1
    toggle.Text               = ""
    toggle.ZIndex             = 14
    toggle.Parent             = header
    toggle.MouseButton1Click:Connect(function()
        open = not open
        if open then
            panel.Size    = UDim2.new(1, 0, 0, 0)
            panel.Visible = true
            tween(panel, theme.TweenInfo.Normal, { Size = UDim2.new(1, 0, 0, panelH) })
            tween(arrow, theme.TweenInfo.Fast, { Rotation = 180 })
        else
            tween(panel, theme.TweenInfo.Normal, { Size = UDim2.new(1, 0, 0, 0) }, function()
                panel.Visible = false
            end)
            tween(arrow, theme.TweenInfo.Fast, { Rotation = 0 })
        end
    end)

    local handle = {}
    handle.Instance = header
    function handle:Set(item) selLbl.Text = item; selected = item end
    function handle:Get() return selected end
    function handle:Destroy() header:Destroy() end
    return handle
end

-- ─── CreateLabel ──────────────────────────────────────────────────────────────
--[[
    options = {
        Text   = "Section Header",
        Color  = nil,   -- defaults to theme.TextSecondary
        Size   = nil,   -- font size override
    }
--]]
function Components.CreateLabel(parent, options, theme, _plugins)
    options = options or {}

    local lbl = Instance.new("TextLabel")
    lbl.Name                  = "NexusLabel"
    lbl.Size                  = UDim2.new(1, 0, 0, 22)
    lbl.BackgroundTransparency = 1
    lbl.Font                  = theme.FontBody
    lbl.TextSize              = options.Size or theme.TextSizeSmall
    lbl.TextColor3            = options.Color or theme.TextSecondary
    lbl.Text                  = options.Text or ""
    lbl.TextXAlignment        = Enum.TextXAlignment.Left
    lbl.ZIndex                = 12
    lbl.Parent                = parent

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
    sep.Name                  = "NexusSeparator"
    sep.Size                  = UDim2.new(1, 0, 0, 1)
    sep.BackgroundColor3      = theme.Border
    sep.BorderSizePixel       = 0
    sep.ZIndex                = 12
    sep.Parent                = parent

    local handle = {}
    handle.Instance = sep
    function handle:Destroy() sep:Destroy() end
    return handle
end

-- ─── CreateBadge ──────────────────────────────────────────────────────────────
--[[
    options = {
        Text  = "NEW",
        Color = theme.Success,   -- background pill colour
    }
--]]
function Components.CreateBadge(parent, options, theme, _plugins)
    options = options or {}

    local badge = Instance.new("TextLabel")
    badge.Name                  = "NexusBadge"
    badge.Size                  = UDim2.new(0, 0, 0, 18)
    badge.AutomaticSize         = Enum.AutomaticSize.X
    badge.BackgroundColor3      = options.Color or theme.Accent
    badge.BorderSizePixel       = 0
    badge.Font                  = theme.FontBody
    badge.TextSize              = theme.TextSizeSmall
    badge.TextColor3            = theme.TextPrimary
    badge.Text                  = "  " .. (options.Text or "BADGE") .. "  "
    badge.ZIndex                = 12
    badge.Parent                = parent
    corner(badge, theme.CornerPill)

    local handle = {}
    handle.Instance = badge
    function handle:Set(t) badge.Text = "  " .. t .. "  " end
    function handle:Destroy() badge:Destroy() end
    return handle
end

return Components
