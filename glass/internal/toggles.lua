-- Shared by the toggle controls (checkbox, radio, switch, segmented control, stepper): signals from
-- plain values, the role set for glass, the focus ring, the pressed tint and the click wiring.
local theme = require("glass.theme")
local core = require("glass.core")

local M = {}

-- A signal of `x`, which may already be one.
function M.sig(x)
    return type(x) == "userdata" and x or theme.scheme:map(function() return x end)
end

-- `opts.on_glass` picks the kit's "Over-glass" colours: `n("fill")` names the role to read.
function M.role(opts)
    return function(name) return opts.on_glass and "vibrant_" .. name or name end
end

-- `role` at `alpha`, live: the pressed fill of an unchecked control (white on dark, black on light).
function M.tone(role, alpha)
    return theme.scheme:map(function(p) return theme.alpha(p[role], alpha) end)
end

-- Focus ring layers while `focused` is true.
function M.ring(focused)
    return computed({ focused, theme.c.accent }, function(f, accent) return f and core.focus_ring(accent) or {} end)
end

-- Wires press tracking, keyboard focus and the click into `props`; returns `held` and `focused`,
-- true only for keyboard focus. `activate` runs unless `opts.disabled`. The ring is drawn by the
-- caller from `focused`.
function M.interact(name, props, opts, activate)
    local held = core.pressable(name, props)
    local focused = focus_visible("glass_focus_" .. name)
    local disabled = M.sig(opts.disabled)
    props.focus_visible = focused
    props.focus_ring = false
    props.hittable = disabled:map(function(d) return not d end)
    props.on_click = function()
        if not disabled:get() then
            activate()
        end
    end
    return held, focused
end

-- The darker (light) or lighter (dark) wash of a pressed, filled shape; shown while `held` and `active`.
function M.pressed_tint(radius, held, active)
    return rect(core.shape {
        width = "fill",
        height = "fill",
        radius = radius,
        hittable = false,
        background = M.tone("label", 0.08),
        opacity = computed({ held, active }, function(h, a) return h and a and 1 or 0 end),
        animate = { opacity = { duration = 100 } },
    })
end

return M
