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

-- The arrow in its own frame: base along x from 0 to 46, apex at y 0, as bezier segments.
local TIP = {
    { "M", 0, 10.5 },
    { "C", 8, 10.5, 12, 9, 16, 5.5 },
    { "C", 20, 2, 21, 0, 23, 0 },
    { "C", 25, 0, 26, 2, 30, 5.5 },
    { "C", 34, 9, 38, 10.5, 46, 10.5 },
    { "Z" },
}

-- `top` (#RRGGBBAA) laid over the opaque `base`.
local function flat_over(top, base)
    local a, out = tonumber(top:sub(8, 9), 16) / 255, "#"
    for i = 2, 6, 2 do
        local t, b = tonumber(top:sub(i, i + 1), 16), tonumber(base:sub(i, i + 1), 16)
        out = out .. string.format("%02X", math.floor(t * a + b * (1 - a) + 0.5))
    end
    return out
end

---@return table
local function margin_on(side, px)
    local m = {}
    m[side] = px
    return m
end

-- The arrow pointing at an anchor on `edge` of the popover ("top" means the anchor is above it).
local function arrow(edge, margin)
    local base, h = POPOVER.arrow[1], POPOVER.arrow[2]
    local commands = {}
    for i, seg in ipairs(TIP) do
        local points = {}
        for k = 2, #seg, 2 do
            local x, y = seg[k], seg[k + 1]
            if edge == "top" then
                points[#points + 1] = x
                points[#points + 1] = y
            elseif edge == "bottom" then
                points[#points + 1] = x
                points[#points + 1] = h - y
            elseif edge == "left" then
                points[#points + 1] = y
                points[#points + 1] = x
            else
                points[#points + 1] = h - y
                points[#points + 1] = x
            end
        end
        commands[i] = { op = seg[1], points = points }
    end
    local vertical = edge == "top" or edge == "bottom"
    return path {
        width = vertical and base or h,
        height = vertical and h or base,
        margin = margin,
        align_h = ({ left = "start", right = "end" })[edge] or "center",
        align_v = ({ top = "start", bottom = "end" })[edge] or "center",
        -- not in the kit: the arrow is flat, glass cannot be unioned into it. It is opaque, since
        -- the body's shadow darkens the window behind a translucent arrow into a visible notch.
        fill = computed({ theme.dark, theme.scheme }, function(d, p)
            return flat_over(material.STYLES.large[d and "dark" or "light"].flat, p.window_background)
        end),
        commands = commands,
    }
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
    local body = column(material.glass("large", {
        width = spec.width or POPOVER.width,
        radius = POPOVER.radius,
        padding = POPOVER.padding,
        on_click = function() end,
        children = { type(spec.content) == "function" and spec.content() or spec.content },
    }))
    -- The arrow paints after the body, which would otherwise shade it with its own shadow: it
    -- hangs outside the body's box, which leaves room for it with a margin.
    local tip = arrow(side, margin_on(side, -POPOVER.arrow[2]))
    local stack = column {
        align_h = edge == "left" and "end" or "center",
        align_v = edge == "top" and "end" or "center",
        children = { rect { margin = margin_on(side, POPOVER.arrow[2]), children = { body, tip } } },
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

-- opts: anchor (a `geometry(name)` signal), content (a node, or a function returning one),
-- edge ("bottom" default, "top", "left" or "right": which side of the anchor it opens on),
-- width (default 230).
function M.open_popover(opts)
    spec = opts
    overlay.open("glass_popover")
end

return M
