-- Liquid Glass popover: large glass with an arrow toward its anchor, from the kit.
-- Closes on an outside click and on Escape. The open popover is a Lua local, since nodes cannot
-- live in named state.
local theme = require("glass.theme")
local core = require("glass.core")
local material = require("glass.material")
local overlay = require("glass.overlay")

local M = {}

local POPOVER = {
    width = 230,
    radius = 20,
    arrow = { 46, 10.5 }, -- base, height
    gap = 2, -- not in the kit: arrow tip to anchor
    padding = 16, -- not in the kit: the kit's popovers are empty shells
    edge = 4, -- not in the kit: the least room left between a popover and the window's edge
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

-- A kit point (`kx` along the base, `ky` from the apex) on `side` of the body, centred on it and slid
-- `shift` along it. The
-- contour runs clockwise, so the bottom and left tails run against the kit's x and mirror it.
local function tip_point(side, kx, ky, shift)
    local h = POPOVER.arrow[2]
    if side == "bottom" or side == "left" then
        kx = POPOVER.arrow[1] - kx
    end
    local along = { from = "center", px = kx - POPOVER.arrow[1] / 2 + shift }
    if side == "top" then return { along, ky - h } end
    if side == "bottom" then return { along, { from = "bottom", px = h - ky } } end
    if side == "left" then return { ky - h, along } end
    return { { from = "right", px = h - ky }, along }
end

-- The body and its arrow on `side` as one clockwise contour with the kit's smoothed corners.
local function outline(side, shift)
    local r = POPOVER.radius
    local commands = { { op = "M", points = { 0, r } } }
    local function corner(x, y)
        commands[#commands + 1] = { op = "corner", points = { x, y }, radius = r, corner_smoothing = theme.SMOOTHING }
    end
    local function tail(edge)
        if edge ~= side then return end
        commands[#commands + 1] = { op = "L", points = tip_point(side, TIP[1][1], TIP[1][2], shift) }
        for k = 2, #TIP do
            local seg, points = TIP[k], {}
            for n = 1, 5, 2 do
                for _, v in ipairs(tip_point(side, seg[n], seg[n + 1], shift)) do points[#points + 1] = v end
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

local OPPOSITE = { bottom = "top", top = "bottom", left = "right", right = "left" }
local box = geometry("glass_popover_box")

-- Where the body sits: the wanted edge, or the opposite one if only that has room, then slid to stay
-- inside `b`; `shift` is how far the arrow slides off the body's centre to keep pointing at the anchor.
local function place(r, b, t)
    local w, h = t and t.width or spec.width or POPOVER.width, t and t.height or 0
    local reach = POPOVER.gap + POPOVER.arrow[2]
    local want = spec.edge or "bottom"
    local fits = {
        bottom = not b or r.y + r.height + reach + h <= b.y + b.height - POPOVER.edge,
        top = not b or r.y - reach - h >= b.y + POPOVER.edge,
        right = not b or r.x + r.width + reach + w <= b.x + b.width - POPOVER.edge,
        left = not b or r.x - reach - w >= b.x + POPOVER.edge,
    }
    local edge = (fits[want] or not fits[OPPOSITE[want]]) and want or OPPOSITE[want]
    local left, top
    if edge == "bottom" or edge == "top" then
        left, top = r.x + r.width / 2 - w / 2, edge == "bottom" and r.y + r.height + reach or r.y - reach - h
    else
        left, top = edge == "right" and r.x + r.width + reach or r.x - reach - w, r.y + r.height / 2 - h / 2
    end
    local x, y = left, top
    if b then
        left = math.max(b.x + POPOVER.edge, math.min(left, b.x + b.width - POPOVER.edge - w))
        top = math.max(b.y + POPOVER.edge, math.min(top, b.y + b.height - POPOVER.edge - h))
    end
    local vertical = edge == "bottom" or edge == "top"
    local slack = (vertical and w or h) / 2 - POPOVER.radius - POPOVER.arrow[1] / 2
    local shift = vertical and x - left or y - top
    return { edge = edge, left = left, top = top, shift = math.max(-slack, math.min(slack, shift)) }
end

overlay.layer("glass_popover", function()
    if not spec.anchor then
        return rect { hittable = false } -- a reload cleared the open popover
    end
    local bounds = overlay.bounds(spec.window or core.window)
    local where = computed({ spec.anchor, bounds, box }, place)
    local props = material.glass("large", {
        width = spec.width or POPOVER.width,
        padding = POPOVER.padding,
        geometry = box,
        margin = where:map(function(p) return { left = p.left, top = p.top } end),
        on_click = function() end,
        children = { type(spec.content) == "function" and spec.content() or spec.content },
    })
    -- One contour for body and arrow; its own smoothed corners stand in for radius and smoothing.
    props.corner_smoothing = nil
    props.outline = where:map(function(p) return outline(OPPOSITE[p.edge], p.shift) end)
    return rect {
        id = "glass_popover",
        width = "fill",
        height = "fill",
        on_click = function() overlay.close("glass_popover") end,
        animate = { exit = { duration = 120, opacity = 0 } },
        children = { column(props) },
    }
end)

-- Popover: large glass with an arrow toward its anchor.
---@class glass.PopoverOpts
---@field anchor Signal<table> A `geometry(name)` signal.
---@field content Node|fun(): Node
---@field edge? "bottom"|"top"|"left"|"right" Which side of the anchor it opens on, default "bottom"; it flips to the opposite side when only that fits in the window, and slides to stay inside it.
---@field width? number Default 230.
---@field window? string The window or panel it opens over; default `core.window`.
---@field [string] "no such property"

---@param opts glass.PopoverOpts
function M.open_popover(opts)
    spec = opts
    overlay.open("glass_popover", nil, opts.window)
end

return M
