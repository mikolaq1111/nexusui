--[[
    theme.lua  (ui-library)  —  Aurora Borealis Edition
    ═══════════════════════════════════════════════════════════════
    Deep-space background · animated teal→purple→magenta accent
    All widgets inherit these tokens; nothing is hardcoded.
--]]

local TI = TweenInfo

local Theme = {

    -- ── Surfaces ── deep space / almost-black with teal hint ────────────────
    Surface        = Color3.fromRGB( 4,  4, 16),
    SurfaceRaised  = Color3.fromRGB( 8,  8, 24),
    SurfaceSunken  = Color3.fromRGB( 2,  2, 10),

    -- ── Aurora accent ── teal primary, gradient from teal→violet→magenta ───
    Accent       = Color3.fromRGB(  0, 235, 200),
    AccentLight  = Color3.fromRGB( 80, 255, 235),
    AccentDark   = Color3.fromRGB(  0, 148, 128),
    AccentGradient = ColorSequence.new({              -- static baseline
        ColorSequenceKeypoint.new(0,   Color3.fromRGB(  0, 235, 200)),
        ColorSequenceKeypoint.new(0.4, Color3.fromRGB(115,  50, 255)),
        ColorSequenceKeypoint.new(1,   Color3.fromRGB(255,   0, 155)),
    }),

    -- ── State ───────────────────────────────────────────────────────────────
    Success = Color3.fromRGB(  0, 230, 115),
    Warning = Color3.fromRGB(255, 185,   0),
    Danger  = Color3.fromRGB(255,  52,  85),
    Info    = Color3.fromRGB(  0, 200, 255),

    -- ── Text ── aurora-tinted whites ────────────────────────────────────────
    TextPrimary   = Color3.fromRGB(215, 255, 250),
    TextSecondary = Color3.fromRGB( 95, 155, 148),
    TextDisabled  = Color3.fromRGB( 38,  58,  55),
    TextAccent    = Color3.fromRGB(  0, 235, 200),
    TextMono      = Color3.fromRGB( 95, 255, 195),

    -- ── Toggle ──────────────────────────────────────────────────────────────
    ToggleOn   = Color3.fromRGB(  0, 235, 200),
    ToggleOff  = Color3.fromRGB( 12,  18,  32),
    ToggleKnob = Color3.fromRGB(215, 255, 250),

    -- ── Scroll / border ─────────────────────────────────────────────────────
    ScrollBar      = Color3.fromRGB( 0,  90,  80),
    Border         = Color3.fromRGB( 0,  45,  40),
    StrokeWeight   = 1,
    StrokeWeightFat= 2,

    -- ── Glow ────────────────────────────────────────────────────────────────
    GlowColor        = Color3.fromRGB(0, 235, 200),
    GlowTransparency = 0.60,

    -- ── Window defaults ─────────────────────────────────────────────────────
    WindowWidth        = 445,
    TitleBarHeight     = 52,
    WindowTransparency = 0.05,

    -- ── Spacing ─────────────────────────────────────────────────────────────
    ItemHeight  = 40,
    ItemSpacing =  5,
    Padding     = 12,

    -- ── Corners ─────────────────────────────────────────────────────────────
    CornerRadius = UDim.new(0, 14),
    CornerSmall  = UDim.new(0,  9),
    CornerPill   = UDim.new(1,  0),

    -- ── Fonts ───────────────────────────────────────────────────────────────
    FontTitle = Enum.Font.GothamBold,
    FontBody  = Enum.Font.Gotham,
    FontMono  = Enum.Font.Code,

    TextSizeTitle = 15,
    TextSizeBody  = 13,
    TextSizeSmall = 11,

    -- ── Tweens ──────────────────────────────────────────────────────────────
    TweenInfo = {
        Fast   = TI.new(0.10, Enum.EasingStyle.Quad,  Enum.EasingDirection.Out),
        Normal = TI.new(0.22, Enum.EasingStyle.Quad,  Enum.EasingDirection.Out),
        Spring = TI.new(0.42, Enum.EasingStyle.Back,  Enum.EasingDirection.Out),
        Slow   = TI.new(0.55, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out),
    },
}

return Theme
