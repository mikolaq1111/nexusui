--[[
    tween.lua  (plugin-libray)
    ==========================
    Thin wrapper around TweenService that adds:
      • Preset TweenInfo constants (reuse theme values)
      • A chainable Sequence helper
      • Spring/Bounce helpers for open/close animations
      • A pulse loop for "breathing" glow effects

    Usage:
        local Tween = require(...)
        Tween.play(frame, Tween.Preset.Normal, { BackgroundTransparency = 0 })
        Tween.sequence({
            { inst = frame, preset = "Fast", props = { Size = UDim2.new(1,0,1,0) } },
            { inst = label, preset = "Normal", props = { TextTransparency = 0 } },
        })
--]]

local TweenService = game:GetService("TweenService")

local Tween = {}

-- ─── Built-in presets ────────────────────────────────────────────────────────
Tween.Preset = {
    -- 0.12 s  —  snappy response (button press, toggle flip)
    Fast   = TweenInfo.new(0.12, Enum.EasingStyle.Quad,  Enum.EasingDirection.Out),
    -- 0.25 s  —  standard transition (hover, property swap)
    Normal = TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
    -- 0.45 s  —  deliberate motion (panel slide, value update)
    Slow   = TweenInfo.new(0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
    -- 0.55 s Back  —  spring bounce (window open)
    Spring = TweenInfo.new(0.55, Enum.EasingStyle.Back,  Enum.EasingDirection.Out),
    -- 0.6 s Elastic  —  exaggerated pop (notification badge)
    Elastic= TweenInfo.new(0.60, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out),
    -- 0.30 s Sine loop-ready for pulse effects
    Pulse  = TweenInfo.new(0.80, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
}

-- ─── Core play function ───────────────────────────────────────────────────────
--[[
    Tween.play(instance, tweenInfoOrPresetName, properties [, callback])
        tweenInfoOrPresetName — a TweenInfo object OR a string key into Tween.Preset
        callback              — optional function called when the tween completes
    Returns the live Tween object.
--]]
function Tween.play(instance, tweenInfoOrPresetName, properties, callback)
    local info
    if type(tweenInfoOrPresetName) == "string" then
        info = Tween.Preset[tweenInfoOrPresetName]
        assert(info, "[Tween] Unknown preset: " .. tweenInfoOrPresetName)
    else
        info = tweenInfoOrPresetName
    end

    local t = TweenService:Create(instance, info, properties)
    if callback then
        t.Completed:Once(function(state)
            if state == Enum.PlaybackState.Completed then
                callback()
            end
        end)
    end
    t:Play()
    return t
end

-- ─── Sequence helper ──────────────────────────────────────────────────────────
--[[
    Tween.sequence(steps [, onAllDone])
    Plays a list of tweens sequentially, each starting after the previous ends.

    steps = {
        { inst = frame, preset = "Normal", props = { Size = ... } },
        { inst = label, info  = TweenInfo.new(...), props = { TextTransparency = 0 } },
        { wait = 0.2 },   -- plain delay step (no tween)
    }
--]]
function Tween.sequence(steps, onAllDone)
    local index = 0

    local function next()
        index = index + 1
        local step = steps[index]
        if not step then
            if onAllDone then onAllDone() end
            return
        end

        if step.wait then
            -- Pure delay step
            task.delay(step.wait, next)
            return
        end

        local info = step.info
                  or (step.preset and Tween.Preset[step.preset])
                  or Tween.Preset.Normal
        Tween.play(step.inst, info, step.props, next)
    end

    next()
end

-- ─── Open / Close helpers ─────────────────────────────────────────────────────
--[[
    Tween.openWindow(frame, targetSize)
        Spring-pops a frame from invisible to full size.
--]]
function Tween.openWindow(frame, targetSize)
    frame.Size = UDim2.new(0, 1, 0, 1)
    frame.BackgroundTransparency = 1
    frame.Visible = true
    Tween.play(frame, Tween.Preset.Spring, { Size = targetSize, BackgroundTransparency = 0 })
end

--[[
    Tween.closeWindow(frame [, callback])
        Shrinks a frame to a point then hides it.
--]]
function Tween.closeWindow(frame, callback)
    Tween.play(frame, Tween.Preset.Normal,
        { Size = UDim2.new(0,1,0,1), BackgroundTransparency = 1 },
        function()
            frame.Visible = false
            if callback then callback() end
        end
    )
end

-- ─── Pulse / Glow loop ────────────────────────────────────────────────────────
--[[
    Tween.startPulse(instance, propA, propB)
        Oscillates a property back and forth forever.
        Returns a stop function: local stop = Tween.startPulse(...)
                                 stop()

    Example:
        Tween.startPulse(glowFrame,
            { BackgroundTransparency = 0.7 },
            { BackgroundTransparency = 0.9 }
        )
--]]
function Tween.startPulse(instance, propA, propB)
    local running = true
    local function loop(propsNext)
        if not running then return end
        Tween.play(instance, Tween.Preset.Pulse, propsNext, function()
            loop(propsNext == propA and propB or propA)
        end)
    end
    loop(propB)

    return function()
        running = false
    end
end

-- ─── Shake helper (error / warning feedback) ─────────────────────────────────
--[[
    Tween.shake(instance, intensity, count)
        Rapidly shifts an element left/right to signal an error.
        intensity — pixel offset (default 6)
        count     — number of shakes (default 4)
--]]
function Tween.shake(instance, intensity, count)
    intensity = intensity or 6
    count     = count     or 4
    local origin = instance.Position
    local shakeInfo = TweenInfo.new(0.05, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut)

    local steps = {}
    for i = 1, count do
        local dir = (i % 2 == 0) and intensity or -intensity
        steps[#steps+1] = {
            inst  = instance,
            info  = shakeInfo,
            props = { Position = UDim2.new(
                origin.X.Scale, origin.X.Offset + dir,
                origin.Y.Scale, origin.Y.Offset
            )},
        }
    end
    -- Return to origin
    steps[#steps+1] = { inst = instance, info = shakeInfo, props = { Position = origin } }
    Tween.sequence(steps)
end

-- ─── Fade helpers ─────────────────────────────────────────────────────────────
function Tween.fadeIn(instance, duration)
    instance.BackgroundTransparency = 1
    instance.Visible = true
    local info = TweenInfo.new(duration or 0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    Tween.play(instance, info, { BackgroundTransparency = 0 })
end

function Tween.fadeOut(instance, duration, callback)
    local info = TweenInfo.new(duration or 0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
    Tween.play(instance, info, { BackgroundTransparency = 1 }, function()
        instance.Visible = false
        if callback then callback() end
    end)
end

return Tween
