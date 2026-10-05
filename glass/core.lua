-- Building blocks every component uses: text in the native type styles, Lucide icons, press
-- tracking and the keyboard focus ring.
local theme = require("glass.theme")
local icons = require("glass.icons")

local FADE = theme.motion.fade

local M = {}

-- Copies `from`'s fields onto `into`; components use it to let `opts` override their defaults.
function M.merge(into, from)
    for k, v in pairs(from or {}) do
        into[k] = v
    end
    return into
end
local merge = M.merge

function M.text(content, color, style, props)
    local t = theme.type[style or "body"]
    return text(merge({
        content = content,
        font = theme.FONT,
        foreground = color,
        font_size = t[1],
        font_weight = t[2],
        line_height = t[3] / t[1],
        letter_spacing = t[4],
        align_v = "center",
        animate = { foreground = FADE },
    }, props))
end

-- Marks a rounded shape with the kit's continuous corners.
function M.shape(props)
    props.corner_smoothing = theme.SMOOTHING
    return props
end

-- Lucide glyphs ink ~1.4x smaller than SF Symbols at the same size (24 px box, thin stroke).
local LUCIDE_SCALE = 1.4

-- A Lucide icon by name (lucide.dev/icons), e.g. "search", at the SF Symbol point size `size`.
function M.icon(name, color, size, props)
    local function glyph(n)
        return assert(icons[n], "glass: no Lucide icon named " .. tostring(n))
    end
    return text(merge({
        content = type(name) == "string" and glyph(name) or name:map(glyph),
        font = "lucide",
        font_size = (size or 16) * LUCIDE_SCALE,
        foreground = color,
        align_v = "center",
        animate = { foreground = FADE },
    }, props))
end

-- Press tracking: returns `held`, true while the pointer is down on the box `props` describes.
-- native controls have no hover state; they change only while clicked.
function M.pressable(name, props)
    ---@type StateSignal<boolean>
    local held = state("glass_held_" .. name, false)
    props.on_drag = function(_, _, phase)
        if phase == "start" then
            held:set(true)
        elseif phase == "end" then
            held:set(false)
        end
    end
    return held
end

-- The keyboard focus ring: a 3.5 px accent ring at 25% outside the shape, as `shadows` layers
-- to add while `focused` is true.
function M.focus_ring(accent)
    return { { color = theme.alpha(accent, 0.25), spread = 3.5 } }
end

-- Swaps the engine's black and white outline on a Tab stop (a node with `on_click` and an
-- `accessible_name`) for the accent ring; `props` must not set `shadows`.
function M.focusable(name, props)
    local on = focused("glass_focus_" .. name)
    props.focused = on
    props.focus_ring = false
    props.shadows = computed({ on, theme.scheme }, function(f, p) return f and M.focus_ring(p.accent) or {} end)
end

return M
