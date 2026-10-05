-- Stepper: two stacked buttons, up and down, split by a hairline and clipped to one rounded shape.
-- A button dims at its limit.
local theme = require("glass.theme")
local core = require("glass.core")
local material = require("glass.material")
local tg = require("glass.internal.toggles")

local c, FADE = theme.c, theme.motion.fade

-- Per size: width, height, radius, hairline inset, glyph size.
local SIZES = {
    mini = { w = 13, h = 16, radius = 4, inset = 2, glyph = 9 },
    small = { w = 17, h = 20, radius = 5, inset = 3, glyph = 11 },
    regular = { w = 20, h = 24, radius = 6, inset = 3, glyph = 13 },
    large = { w = 23, h = 28, radius = 7, inset = 4, glyph = 13 },
    xl = { w = 30, h = 36, radius = 9, inset = 5, glyph = 13 },
}

local M = {}

-- opts: value (state number), min, max, step (default 1), size, disabled, on_glass, on_change(value).
function M.stepper(id, opts)
    opts = opts or {}
    local s = SIZES[opts.size or "regular"]
    local n = tg.role(opts)
    local lo, hi, step = opts.min or -math.huge, opts.max or math.huge, opts.step or 1
    ---@type StateSignal<number>
    local value = opts.value or state("glass_step_" .. id, math.max(lo, 0))
    local idle = opts.on_glass and "vibrant_fill" or "secondary_fill"
    local rings = {}
    local function button(icon, dir)
        local limit = value:map(function(v) return dir > 0 and v >= hi or dir < 0 and v <= lo end)
        local disabled = computed({ tg.sig(opts.disabled), limit }, function(a, b) return a or b end)
        local props = { accessible_name = icon, width = s.w, height = s.h / 2 }
        local held, focused = tg.interact("step_" .. id .. icon, props, { disabled = disabled }, function()
            value:set(math.max(lo, math.min(hi, value:get() + dir * step)))
            if opts.on_change then
                opts.on_change(value:get())
            end
        end)
        rings[#rings + 1] = focused
        props.background = computed({ held, disabled, theme.scheme }, function(h, d, p)
            return h and theme.alpha(p.label, 0.16) or p[d and n("tertiary_fill") or idle]
        end)
        props.animate = { background = FADE }
        props.children = {
            core.icon(icon, computed({ disabled, theme.scheme }, function(d, p)
                return p[d and n("tertiary_label") or "vibrant_label"]
            end), s.glyph, material.vibrant({ align_h = "center" })),
        }
        return rect(props)
    end
    local up, down = button("chevron-up", 1), button("chevron-down", -1)
    return rect(core.shape {
        width = s.w,
        height = s.h,
        radius = s.radius,
        clip = "rounded",
        shadows = tg.ring(computed(rings, function(a, b) return a or b end)),
        children = {
            column { children = { up, down } },
            rect {
                width = s.w - 2 * s.inset,
                height = 1,
                margin = { left = s.inset, top = s.h / 2 - 0.5 },
                background = c.vibrant_quaternary_label,
            },
        },
    })
end

return M
