-- Liquid Glass popover: large glass with an arrow toward its anchor, from docs/spec/overlays.md.
-- Closes on an outside click and on Escape. The open popover is a Lua local, since nodes cannot
-- live in named state.
local theme = require("glass.theme")
local material = require("glass.material")
local overlay = require("glass.overlay")

local M = {}

local POPOVER = {
    width = 230,
    radius = 20,
    arrow = { 46, 10.5 }, -- base, height
    gap = 2, -- not in the kit: arrow tip to anchor
    padding = 16, -- not in the kit: the kit's popovers are empty shells
}

-- The arrow in its own frame: base along x from 0 to 46 on the body's edge, apex 10.5 out at x 23,
-- as the kit's bezier segments from base start to base end.
local TIP = {
    { 0, 10.5 },
    { 8, 10.5, 12, 9, 16, 5.5 },
    { 20, 2, 21, 0, 23, 0 },
    { 25, 0, 26, 2, 30, 5.5 },
    { 34, 9, 38, 10.5, 46, 10.5 },
}

-- A kit point (`kx` along the base, `ky` from the apex) on `side` of the body, centred on it. The
-- contour runs clockwise, so the bottom and left tails run against the kit's x and mirror it.
local function tip_point(side, kx, ky)
    local h = POPOVER.arrow[2]
    if side == "bottom" or side == "left" then
        kx = POPOVER.arrow[1] - kx
    end
    local along = { from = "center", px = kx - POPOVER.arrow[1] / 2 }
    if side == "top" then return { along, ky - h } end
    if side == "bottom" then return { along, { from = "bottom", px = h - ky } } end
    if side == "left" then return { ky - h, along } end
    return { { from = "right", px = h - ky }, along }
end

---@return table
local function margin_on(side, px)
    local m = {}
    m[side] = px
    return m
end

-- The body and its arrow on `side` as one clockwise contour with the kit's smoothed corners.
local function outline(side)
    local r = POPOVER.radius
    local commands = { { op = "M", points = { 0, r } } }
    local function corner(x, y)
        commands[#commands + 1] = { op = "corner", points = { x, y }, radius = r, corner_smoothing = theme.SMOOTHING }
    end
    local function tail(edge)
        if edge ~= side then return end
        commands[#commands + 1] = { op = "L", points = tip_point(side, TIP[1][1], TIP[1][2]) }
        for k = 2, #TIP do
            local seg, points = TIP[k], {}
            for n = 1, 5, 2 do
                for _, v in ipairs(tip_point(side, seg[n], seg[n + 1])) do points[#points + 1] = v end
            end
            commands[#commands + 1] = { op = "C", points = points }
        end
    end
    corner(0, 0)
    tail("top")
    corner("100%", 0)
    tail("right")
    corner("100%", "100%")
    tail("bottom")
    corner(0, "100%")
    tail("left")
    commands[#commands + 1] = { op = "Z", points = {} }
    return { commands = commands }
end

---@type table
local spec = {}

overlay.layer("glass_popover", function()
    if not spec.anchor then
        return rect { hittable = false } -- a reload cleared the open popover
    end
    local edge = spec.edge or "bottom" -- where the popover sits relative to its anchor
    local at = spec.anchor
    local side = ({ bottom = "top", top = "bottom", left = "right", right = "left" })[edge]
    local props = material.glass("large", {
        width = spec.width or POPOVER.width,
        padding = POPOVER.padding,
        on_click = function() end,
        children = { type(spec.content) == "function" and spec.content() or spec.content },
    })
    -- One contour for body and arrow; its own smoothed corners stand in for radius and smoothing.
    props.corner_smoothing = nil
    props.outline = outline(side)
    local body = column(props)
    local stack = column {
        align_h = edge == "left" and "end" or "center",
        align_v = edge == "top" and "end" or "center",
        -- The arrow paints past the body's box; the margin leaves it room.
        children = { rect { margin = margin_on(side, POPOVER.arrow[2]), children = { body } } },
    }
    local g = POPOVER.gap
    -- The anchor's box, stretched or shifted so the popover centres on it.
    local host = ({
        bottom = function() return rect {
            width = at:map(function(r) return r.width end),
            margin = at:map(function(r) return { left = r.x, top = r.y + r.height + g } end),
            children = { stack },
        } end,
        top = function() return rect {
            width = at:map(function(r) return r.width end),
            height = at:map(function(r) return math.max(0, r.y - g) end),
            margin = at:map(function(r) return { left = r.x } end),
            children = { stack },
        } end,
        right = function() return rect {
            height = at:map(function(r) return r.height end),
            margin = at:map(function(r) return { left = r.x + r.width + g, top = r.y } end),
            children = { stack },
        } end,
        left = function() return rect {
            width = at:map(function(r) return math.max(0, r.x - g) end),
            height = at:map(function(r) return r.height end),
            margin = at:map(function(r) return { top = r.y } end),
            children = { stack },
        } end,
    })[edge]()
    return rect {
        id = "glass_popover",
        width = "fill",
        height = "fill",
        on_click = function() overlay.close("glass_popover") end,
        animate = { exit = { duration = 120, opacity = 0 } },
        children = { host },
    }
end)

-- Popover: large glass with an arrow toward its anchor.
---@class glass.PopoverOpts
---@field anchor Signal<table> A `geometry(name)` signal.
---@field content Node|fun(): Node
---@field edge? "bottom"|"top"|"left"|"right" Which side of the anchor it opens on; default "bottom".
---@field width? number Default 230.
---@field window? string The window or panel it opens over; default `core.window`.
---@field [string] "no such property"

---@param opts glass.PopoverOpts
function M.open_popover(opts)
    spec = opts
    overlay.open("glass_popover", nil, opts.window)
end

return M
