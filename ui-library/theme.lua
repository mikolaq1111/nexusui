--[[
    theme.lua
    =========
    Central design-token file for NexusUI.
    All colors, fonts, sizes, and animation durations live here so that
    every component stays visually consistent.  To create a custom theme,
    clone this table, change what you need, and pass it into Library.new().

    Usage:
        local Theme = require(script.Parent.theme)
        -- or, when loaded via loadstring:
        local Theme = NexusUI.Theme
--]]

local Theme = {}

-- ─── Palette ────────────────────────────────────────────────────────────────
-- Primary accent colours (purple/indigo gradient family)
Theme.Accent          = Color3.fromRGB(120,  87, 255)   -- vivid violet
Theme.AccentDark      = Color3.fromRGB( 79,  54, 200)   -- deeper violet (pressed states)
Theme.AccentLight     = Color3.fromRGB(160, 132, 255)   -- lighter violet (hover glow)

-- Backgrounds — layered dark glassmorphism surface
Theme.Background      = Color3.fromRGB( 13,  13,  20)   -- near-black base
Theme.Surface         = Color3.fromRGB( 20,  20,  33)   -- card / window surface
Theme.SurfaceRaised   = Color3.fromRGB( 28,  28,  45)   -- elevated element (button bg)
Theme.SurfaceSunken   = Color3.fromRGB( 10,  10,  17)   -- input / inner wells

-- Stroke / dividers
Theme.Border          = Color3.fromRGB( 55,  55,  80)   -- subtle border
Theme.BorderAccent    = Color3.fromRGB(120,  87, 255)   -- accent-coloured border

-- Text hierarchy
Theme.TextPrimary     = Color3.fromRGB(240, 240, 255)   -- main readable text
Theme.TextSecondary   = Color3.fromRGB(150, 150, 180)   -- muted / label text
Theme.TextDisabled    = Color3.fromRGB( 80,  80, 100)   -- disabled elements
Theme.TextAccent      = Color3.fromRGB(160, 132, 255)   -- accent-coloured text

-- Semantic colours
Theme.Success         = Color3.fromRGB( 72, 213, 151)
Theme.Warning         = Color3.fromRGB(255, 193,  69)
Theme.Danger          = Color3.fromRGB(255,  72,  98)
Theme.Info            = Color3.fromRGB( 87, 190, 255)

-- Toggle / checkbox
Theme.ToggleOff       = Color3.fromRGB( 55,  55,  80)
Theme.ToggleOn        = Color3.fromRGB(120,  87, 255)
Theme.ToggleKnob      = Color3.fromRGB(240, 240, 255)

-- Scrollbar
Theme.ScrollBar       = Color3.fromRGB( 80,  80, 120)

-- Shadow / glow — used as UIStroke or drop-shadow colour
Theme.GlowColor       = Color3.fromRGB(120,  87, 255)
Theme.ShadowColor     = Color3.fromRGB(  0,   0,   0)

-- ─── Typography ─────────────────────────────────────────────────────────────
Theme.FontTitle       = Enum.Font.GothamBold          -- window / section titles
Theme.FontBody        = Enum.Font.Gotham              -- regular body copy
Theme.FontMono        = Enum.Font.Code                -- monospaced (values, keybinds)

Theme.TextSizeTitle   = 15
Theme.TextSizeBody    = 13
Theme.TextSizeSmall   = 11

-- ─── Geometry ────────────────────────────────────────────────────────────────
Theme.CornerRadius    = UDim.new(0, 10)   -- general roundness
Theme.CornerSmall     = UDim.new(0,  6)   -- buttons, toggles
Theme.CornerPill      = UDim.new(1,  0)   -- full pill shape (sliders, badges)

Theme.StrokeWeight    = 1                 -- UIStroke thickness (px)
Theme.StrokeWeightFat = 2                 -- highlighted / focused strokes

-- ─── Spacing / Layout ────────────────────────────────────────────────────────
Theme.Padding         = 10   -- inner padding for containers (px)
Theme.PaddingSmall    =  6
Theme.ItemSpacing     =  6   -- gap between list items
Theme.WindowWidth     = 380  -- default window width  (px)
Theme.WindowMinHeight = 260  -- minimum window height (px)
Theme.TitleBarHeight  = 38   -- header strip height   (px)
Theme.ItemHeight      = 34   -- standard row height   (px)

-- ─── Animation ───────────────────────────────────────────────────────────────
Theme.TweenInfo = {
    -- Quick snap (button press / toggle)
    Fast   = TweenInfo.new(0.12, Enum.EasingStyle.Quad,   Enum.EasingDirection.Out),
    -- Standard UI transition (open/close/hover)
    Normal = TweenInfo.new(0.25, Enum.EasingStyle.Quart,  Enum.EasingDirection.Out),
    -- Slow, dramatic entrance
    Slow   = TweenInfo.new(0.45, Enum.EasingStyle.Quint,  Enum.EasingDirection.Out),
    -- Spring-like bounce for opening windows
    Spring = TweenInfo.new(0.55, Enum.EasingStyle.Back,   Enum.EasingDirection.Out),
}

-- ─── Transparency / Glassmorphism ────────────────────────────────────────────
Theme.WindowTransparency  = 0.06   -- BackgroundTransparency for window frame
Theme.SurfaceTransparency = 0.10   -- slightly see-through surface panels
Theme.GlowTransparency    = 0.82   -- ambient glow ImageLabel transparency

-- ─── Gradient helpers ────────────────────────────────────────────────────────
-- Returns a ColorSequence for a two-stop gradient (left→right or top→bottom)
function Theme.Gradient(colorA, colorB)
    return ColorSequence.new({
        ColorSequenceKeypoint.new(0, colorA),
        ColorSequenceKeypoint.new(1, colorB),
    })
end

-- Accent gradient used on title bars and focus rings
Theme.AccentGradient = Theme.Gradient(
    Color3.fromRGB(120, 87, 255),
    Color3.fromRGB(200, 90, 255)
)

return Theme
