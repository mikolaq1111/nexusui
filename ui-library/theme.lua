--[[
    theme.lua  (ui-library)
    ══════════════════════════════════════════════════════════
    Premium design token system – MM2 Crimson Edition
    ══════════════════════════════════════════════════════════
    All colours, spacing, typography and animation settings
    live here. Components read from this table; nothing is
    hardcoded inside the widget constructors.
--]]

local TI = TweenInfo   -- avoid shadowing in nested scopes

local Theme = {

    -- ── Surfaces ────────────────────────────────────────────────────────────
    Surface        = Color3.fromRGB(10,  10, 22),   -- window body
    SurfaceRaised  = Color3.fromRGB(16,  16, 34),   -- cards / rows
    SurfaceSunken  = Color3.fromRGB( 6,   6, 14),   -- inputs / scrollframes

    -- ── Accent ── Crimson ───────────────────────────────────────────────────
    Accent       = Color3.fromRGB(218, 28,  58),
    AccentLight  = Color3.fromRGB(255, 80, 108),
    AccentDark   = Color3.fromRGB(148, 18,  44),
    AccentGradient = ColorSequence.new({
        ColorSequenceKeypoint.new(0,   Color3.fromRGB(232, 32,  68)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(192, 24,  76)),
        ColorSequenceKeypoint.new(1,   Color3.fromRGB(144, 20,  92)),
    }),

    -- ── State colours ───────────────────────────────────────────────────────
    Success = Color3.fromRGB( 48, 218,  92),
    Warning = Color3.fromRGB(255, 178,  28),
    Danger  = Color3.fromRGB(255,  50,  82),   -- ← used as CLOSE BUTTON base
    Info    = Color3.fromRGB( 62, 158, 255),

    -- ── Text ────────────────────────────────────────────────────────────────
    TextPrimary   = Color3.fromRGB(242, 242, 255),
    TextSecondary = Color3.fromRGB(132, 132, 162),
    TextDisabled  = Color3.fromRGB( 62,  62,  88),
    TextAccent    = Color3.fromRGB(255, 102, 132),
    TextMono      = Color3.fromRGB(158, 220, 158),

    -- ── Toggle ──────────────────────────────────────────────────────────────
    ToggleOn   = Color3.fromRGB(218, 28,  58),
    ToggleOff  = Color3.fromRGB( 26, 26,  50),
    ToggleKnob = Color3.fromRGB(242, 242, 255),

    -- ── Scroll / border ─────────────────────────────────────────────────────
    ScrollBar      = Color3.fromRGB( 58, 58, 98),
    Border         = Color3.fromRGB( 36, 36, 66),
    StrokeWeight   = 1,
    StrokeWeightFat= 2,

    -- ── Glow ────────────────────────────────────────────────────────────────
    GlowColor        = Color3.fromRGB(218, 28, 58),
    GlowTransparency = 0.70,

    -- ── Window defaults ─────────────────────────────────────────────────────
    WindowWidth        = 430,
    TitleBarHeight     = 48,
    WindowTransparency = 0.04,

    -- ── Spacing ─────────────────────────────────────────────────────────────
    ItemHeight  = 40,
    ItemSpacing =  5,
    Padding     = 10,

    -- ── Corner radii ────────────────────────────────────────────────────────
    CornerRadius = UDim.new(0, 12),
    CornerSmall  = UDim.new(0,  8),
    CornerPill   = UDim.new(1,  0),

    -- ── Typography ──────────────────────────────────────────────────────────
    FontTitle = Enum.Font.GothamBold,
    FontBody  = Enum.Font.Gotham,
    FontMono  = Enum.Font.Code,

    TextSizeTitle = 15,
    TextSizeBody  = 13,
    TextSizeSmall = 11,

    -- ── Tween presets ───────────────────────────────────────────────────────
    TweenInfo = {
        Fast   = TI.new(0.10, Enum.EasingStyle.Quad,  Enum.EasingDirection.Out),
        Normal = TI.new(0.22, Enum.EasingStyle.Quad,  Enum.EasingDirection.Out),
        Spring = TI.new(0.42, Enum.EasingStyle.Back,  Enum.EasingDirection.Out),
        Slow   = TI.new(0.55, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out),
    },
}

return Theme
