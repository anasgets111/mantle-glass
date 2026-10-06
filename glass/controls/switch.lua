-- Switch: a pill track and a knob that slides on a spring. While pressed the knob grows into a
-- glass knob that overhangs the track.
local theme = require("glass.theme")
local core = require("glass.core")
local material = require("glass.material")
local tg = require("glass.internal.toggles")

local c, FADE = theme.c, theme.motion.fade

-- Per size, all from the kit: track, knob, inset, and the pressed glass knob's size and x (off, on), y.
local SIZES = {
    xs = { tw = 36, th = 16, kw = 21, kh = 13, inset = 1.5, gw = 33, gh = 20, gx = { -5, 8 }, gy = -2 },
    s = { tw = 44, th = 20, kw = 26, kh = 16, inset = 2, gw = 40, gh = 26, gx = { -5, 9 }, gy = -3 },
    m = { tw = 54, th = 24, kw = 32, kh = 20, inset = 2, gw = 50, gh = 31, gx = { -7, 11 }, gy = -3.5 },
    l = { tw = 64, th = 28, kw = 38, kh = 24, inset = 2, gw = 59, gh = 37, gx = { -8.5, 13.5 }, gy = -4.5 },
    xl = { tw = 80, th = 36, kw = 47, kh = 30, inset = 3, gw = 73, gh = 46, gx = { -9, 16 }, gy = -5 },
}
-- not in the kit: the spring that moves and grows the knob (SwiftUI's snappy)
local MOVE = theme.motion.snappy

local M = {}

-- Switch.
---@class glass.SwitchOpts: glass.ControlOpts
---@field value? StateSignal<boolean>
---@field label? string|Signal<string> Text beside the switch.
---@field name? string Accessible name; default the label.
---@field on_change? fun(on: boolean)
---@field [string] "no such property"

---@param id string
---@param opts? glass.SwitchOpts
---@return Node
function M.switch(id, opts)
    opts = opts or {}
    local s = SIZES[opts.size or "m"]
    local n = tg.role(opts)
    local active = core.active(opts.window)
    local disabled = tg.sig(opts.disabled)
    ---@type StateSignal<boolean>
    local value = opts.value or state("glass_switch_" .. id, false)
    local props = { accessible_name = opts.name or type(opts.label) == "string" and opts.label or id, width = s.tw, height = s.th, radius = theme.CAPSULE }
    local held, focused = tg.interact("sw_" .. id, props, opts, function()
        value:set(not value:get())
        if opts.on_change then
            opts.on_change(value:get())
        end
    end)
    local geo = computed({ value, held }, function(on, down)
        if down then
            return { w = s.gw, h = s.gh, x = s.gx[on and 2 or 1], y = s.gy }
        end
        return { w = s.kw, h = s.kh, x = on and s.tw - s.inset - s.kw or s.inset, y = s.inset }
    end)
    local function knob(extra)
        return rect(core.shape(core.merge({
            width = geo:map(function(g) return g.w end),
            height = geo:map(function(g) return g.h end),
            radius = theme.CAPSULE,
            hittable = false,
            translate = geo:map(function(g) return { x = g.x, y = g.y } end),
            animate = { width = MOVE, height = MOVE, translate = MOVE, opacity = FADE },
        }, extra)))
    end
    local idle_fill = opts.on_glass and c.on_accent
        or computed({ theme.dark, theme.scheme }, function(dark, p) return dark and theme.alpha(p.on_accent, 0.85) or p.on_accent end)
    props.shadows = tg.ring(focused)
    props.background = computed({ value, held, active, disabled, theme.scheme }, function(on, h, a, d, p)
        if on then
            if a then
                return p[n("accent")]
            end
            return p[opts.on_glass and (d and "vibrant_inactive_disabled_fill" or "vibrant_inactive_fill") or d and "tertiary_fill" or "fill"]
        end
        return h and theme.alpha(p.label, 0.19) or p[n("fill")]
    end)
    props.animate = { background = FADE }
    props.children = {
        tg.pressed_tint(theme.CAPSULE, held, value),
        knob {
            background = idle_fill,
            opacity = held:map(function(h) return h and 0 or 1 end),
            shadows = { { color = theme.alpha(theme.CLEAR, 0.05), offset = { y = 3 }, blur = 36 } },
        },
        knob(material.glass("knob", { opacity = held:map(function(h) return h and 1 or 0 end) })),
    }
    return tg.labelled(rect(core.shape(props)), opts)
end

return M
