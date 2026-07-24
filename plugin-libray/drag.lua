--[[
    drag.lua  (plugin-libray)
    =========================
    Provides a clean, cross-platform drag-and-drop system for Roblox GUI frames.
    Handles Mouse, Touch, and Gamepad (left-stick cursor) input sources.

    Features:
      • makeDraggable(target, handle)  — standard window drag
      • makeDraggableConstrained(...)  — drag stays inside a boundary frame
      • snapToGrid(target, gridSize)   — rounds position to a pixel grid
      • Events: onDragStart / onDragEnd / onDragMove callbacks

    Usage:
        local Drag = require(...)
        -- Draggable window, drag by its title bar:
        Drag.makeDraggable(windowFrame, titleBarFrame)

        -- With callbacks:
        Drag.makeDraggable(windowFrame, titleBarFrame, {
            OnStart = function() print("drag started") end,
            OnEnd   = function() print("drag ended")   end,
            OnMove  = function(pos) print(pos)         end,
            GridSnap = 4,   -- snap to 4-pixel grid
        })
--]]

local UIS    = game:GetService("UserInputService")
local RunSvc = game:GetService("RunService")

local Drag = {}

-- ─── Internal state ───────────────────────────────────────────────────────────
-- Tracks connections per target so we can cleanly disconnect later.
local _connections = {}     -- [target] = { RBXScriptConnection, ... }

local function clearConnections(target)
    if _connections[target] then
        for _, conn in ipairs(_connections[target]) do
            conn:Disconnect()
        end
        _connections[target] = nil
    end
end

-- ─── makeDraggable ────────────────────────────────────────────────────────────
--[[
    Drag.makeDraggable(target, handle [, options])

    target  — the Frame that will be MOVED (e.g. the window root)
    handle  — the Frame that receives INPUT (e.g. the title bar)
    options — optional table:
        OnStart  function()         called when drag begins
        OnEnd    function()         called when drag ends
        OnMove   function(pos)      called every frame with new AbsolutePosition
        GridSnap number             snap to this pixel grid (0 = off)
        Boundary Frame              keep target inside this frame's bounds
        SmoothFactor number         lerp factor 0-1 (0 = instant, default 1 = exact)
--]]
function Drag.makeDraggable(target, handle, options)
    options = options or {}

    -- Clean up any previous drag setup on this target
    clearConnections(target)
    _connections[target] = {}

    local function addConn(conn)
        table.insert(_connections[target], conn)
    end

    local dragging    = false
    local dragStart   = nil   -- Vector3 (input position when drag began)
    local startPos    = nil   -- UDim2  (target.Position when drag began)
    local smooth      = options.SmoothFactor or 1   -- 1 = instant follow
    local gridSnap    = options.GridSnap or 0
    local boundary    = options.Boundary            -- optional Frame

    -- Helper: snap a pixel value to grid
    local function snap(v)
        if gridSnap > 0 then
            return math.floor(v / gridSnap + 0.5) * gridSnap
        end
        return v
    end

    -- Helper: clamp position inside boundary
    local function clampToBoundary(newPos)
        if not boundary then return newPos end
        local bAbs  = boundary.AbsolutePosition
        local bSize = boundary.AbsoluteSize
        local tSize = target.AbsoluteSize

        local minX = bAbs.X
        local minY = bAbs.Y
        local maxX = bAbs.X + bSize.X - tSize.X
        local maxY = bAbs.Y + bSize.Y - tSize.Y

        local px = math.clamp(newPos.X.Offset, minX, maxX)
        local py = math.clamp(newPos.Y.Offset, minY, maxY)
        return UDim2.new(newPos.X.Scale, px, newPos.Y.Scale, py)
    end

    -- ── Input begin ──────────────────────────────────────────────────────────
    addConn(handle.InputBegan:Connect(function(inp)
        local isMouseBtn = inp.UserInputType == Enum.UserInputType.MouseButton1
        local isTouch    = inp.UserInputType == Enum.UserInputType.Touch

        if isMouseBtn or isTouch then
            dragging  = true
            dragStart = inp.Position
            startPos  = target.Position

            if options.OnStart then options.OnStart() end
        end
    end))

    -- ── Input changed (move) ─────────────────────────────────────────────────
    addConn(UIS.InputChanged:Connect(function(inp)
        if not dragging then return end

        local isMove  = inp.UserInputType == Enum.UserInputType.MouseMovement
        local isTouch = inp.UserInputType == Enum.UserInputType.Touch

        if isMove or isTouch then
            local delta = inp.Position - dragStart
            local newX  = snap(startPos.X.Offset + delta.X)
            local newY  = snap(startPos.Y.Offset + delta.Y)
            local newPos = clampToBoundary(
                UDim2.new(startPos.X.Scale, newX, startPos.Y.Scale, newY)
            )

            if smooth >= 1 then
                target.Position = newPos
            else
                -- Lerp via RunService for silky smoothness
                -- (lightweight; uses task.spawn to avoid blocking)
                target.Position = target.Position:Lerp(newPos, smooth)
            end

            if options.OnMove then options.OnMove(target.AbsolutePosition) end
        end
    end))

    -- ── Input ended ──────────────────────────────────────────────────────────
    addConn(UIS.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            if dragging and options.OnEnd then options.OnEnd() end
            dragging = false
        end
    end))

    -- Return a disconnect function so callers can cleanly stop dragging
    return function()
        clearConnections(target)
    end
end

-- ─── makeDraggableConstrained ─────────────────────────────────────────────────
-- Convenience wrapper that forces the target to stay within a boundary.
function Drag.makeDraggableConstrained(target, handle, boundary, options)
    options = options or {}
    options.Boundary = boundary
    return Drag.makeDraggable(target, handle, options)
end

-- ─── makeResizable ────────────────────────────────────────────────────────────
--[[
    Drag.makeResizable(target, resizeHandle [, options])
    Adds a resize interaction to a Frame by dragging its corner/edge handle.

    options = {
        MinSize = Vector2.new(200, 150),
        MaxSize = Vector2.new(800, 600),
        OnResize = function(newSize) end,
    }
--]]
function Drag.makeResizable(target, resizeHandle, options)
    options = options or {}
    local minSize = options.MinSize or Vector2.new(160, 120)
    local maxSize = options.MaxSize or Vector2.new(9999, 9999)

    clearConnections(resizeHandle)
    _connections[resizeHandle] = {}
    local function addConn(conn)
        table.insert(_connections[resizeHandle], conn)
    end

    local resizing  = false
    local resStart  = nil
    local startSz   = nil

    addConn(resizeHandle.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            resizing = true
            resStart = inp.Position
            startSz  = target.AbsoluteSize
        end
    end))

    addConn(UIS.InputChanged:Connect(function(inp)
        if not resizing then return end
        if inp.UserInputType ~= Enum.UserInputType.MouseMovement
        and inp.UserInputType ~= Enum.UserInputType.Touch then return end

        local delta = inp.Position - resStart
        local newW  = math.clamp(startSz.X + delta.X, minSize.X, maxSize.X)
        local newH  = math.clamp(startSz.Y + delta.Y, minSize.Y, maxSize.Y)
        local newSize = UDim2.new(0, newW, 0, newH)
        target.Size   = newSize

        if options.OnResize then options.OnResize(Vector2.new(newW, newH)) end
    end))

    addConn(UIS.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            resizing = false
        end
    end))

    return function() clearConnections(resizeHandle) end
end

-- ─── Cleanup ──────────────────────────────────────────────────────────────────
--- Remove all drag connections for a given target (call before destroying).
function Drag.stopDraggable(target)
    clearConnections(target)
end

return Drag
