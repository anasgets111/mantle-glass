-- Sliders: a horizontal slider (standard or center-biased, optionally ticked) and the circular
-- slider (dial). The knob is flat until it is pressed, then grows into a glass knob.
local theme = require("glass.theme")
local core = require("glass.core")
local material = require("glass.material")
local tg = require("glass.internal.toggles")

local c = theme.c

-- Per size, from the kit: master height, track height and y, knob w x h, ticked knob w x h and
-- radius, tick row y; dial diameter and grabber y, w, h.
local SIZES = {
    mini = { h = 16, th = 4, ty = 6, kw = 16, kh = 12, tw = 8, tkh = 16, tkr = 6, tick = 12, dial = 16, gy = 2, gw = 2, gh = 4 },
    small = { h = 20, th = 4, ty = 8, kw = 18, kh = 14, tw = 10, tkh = 18, tkr = 7, tick = 15, dial = 20, gy = 2.5, gw = 2, gh = 5 },
    regular = { h = 24, th = 6, ty = 9, kw = 20, kh = 16, tw = 20, tkh = 16, tkr = 7, tick = 18, dial = 24, gy = 3, gw = 2, gh = 6 },
    large = { h = 28, th = 6, ty = 11, kw = 24, kh = 20, tw = 24, tkh = 20, tkr = 7, tick = 20, dial = 28, gy = 3, gw = 2, gh = 6 },
    xl = { h = 36, th = 6, ty = 15, kw = 24, kh = 20, tw = 24, tkh = 20, tkr = 7, tick = 25, dial = 36, gy = 3, gw = 2, gh = 7 },
}
local INSET = 10 -- the track starts 10 px in: room for the knob to overhang
local GROW = 1.25 -- the pressed knob is the idle knob x 1.25
-- not in the kit: the dial turns over 270 degrees
local SWEEP = 270
-- not in the kit: the springs that move and grow the knob (SwiftUI's snappy and press)
local MOVE, GROW_SPRING = theme.motion.snappy, theme.motion.press

local M = {}

-- `props` with the vibrant blend when over glass.
local function vibrant(opts, props) return opts.on_glass and material.vibrant(props) or props end
local function clamp01(x) return math.max(0, math.min(1, x)) end
local function round(x) return math.floor(x + 0.5) end

-- Props every slider shares: the held state, the disabled signal and the drag handler, which
-- calls `seek(pointer)` while dragging.
local function draggable(id, opts, props, seek)
    ---@type StateSignal<boolean>
    local held = state("glass_held_sl_" .. id, false)
    local disabled = tg.sig(opts.disabled)
    props.accessible_name = opts.label or id
    props.hittable = disabled:map(function(d) return not d end)
    props.on_drag = function(_, pointer, phase)
        held:set(phase ~= "end")
        seek(pointer)
    end
    return held, disabled
end

-- The value `frac` (0..1) as a value in min..max, rounded to `opts.step`; stores it and reports it.
local function store(opts, value, lo, hi, frac)
    local v = lo + frac * (hi - lo)
    if opts.step then
        v = math.max(lo, math.min(hi, lo + round((v - lo) / opts.step) * opts.step))
    end
    if v ~= value:get() then
        value:set(v)
        if opts.on_change then
            opts.on_change(v)
        end
    end
end

-- Slider. While dragging the knob grows and turns to glass.
---@class glass.SliderOpts: glass.ControlOpts
---@field value? StateSignal<number> Default `neutral` or `min`.
---@field min? number Default 0.
---@field max? number Default 1.
---@field step? number
---@field width? number Default 140; the track is 20 px shorter.
---@field neutral? number Centre-biased: the fill grows from this value.
---@field ticks? integer Evenly spaced count.
---@field snap? boolean Snap the value to the ticks.
---@field label? string Accessible name.
---@field on_change? fun(value: number)
---@field [string] "no such property"

---@param id string
---@param opts? glass.SliderOpts
---@return Node
function M.slider(id, opts)
    opts = opts or {}
    local s = SIZES[opts.size or "regular"]
    local n = tg.role(opts)
    local lo, hi = opts.min or 0, opts.max or 1
    local W = opts.width or 140
    local track = W - 2 * INSET
    local ticks = opts.ticks
    local neutral = opts.neutral and (opts.neutral - lo) / (hi - lo)
    ---@type StateSignal<number>
    local value = opts.value or state("glass_slider_" .. id, opts.neutral or lo)
    local frac = value:map(function(v) return clamp01(((v or lo) - lo) / (hi - lo)) end)
    local props = { width = W, height = s.h }
    local held, disabled = draggable(id, opts, props, function(pointer)
        local f = clamp01((pointer.x - INSET) / track)
        if ticks and opts.snap then
            f = round(f * (ticks - 1)) / (ticks - 1)
        end
        store(opts, value, lo, hi, f)
    end)
    local R = s.th / 2
    local fill = frac:map(function(f)
        local a, b = 0, f
        if neutral then
            a, b = math.min(f, neutral), math.max(f, neutral)
        end
        local left = neutral and f <= neutral
        local right = neutral and f > neutral
        return {
            translate = { x = INSET + a * track, y = s.ty },
            w = (b - a) * track,
            radius = { top_left = not right and R or 0, bottom_left = not right and R or 0, top_right = not left and R or 0, bottom_right = not left and R or 0 },
        }
    end)
    -- A held slider follows the pointer exactly; otherwise changes ease.
    local ease = function(extra) return held:map(function(h) return h and {} or extra end) end

    local active = core.active(opts.window)
    local fill_color = computed({ disabled, active, theme.dark, theme.scheme }, function(off, a, dark, p)
        if not a then
            return p[opts.on_glass and (off and "vibrant_inactive_disabled_fill" or "vibrant_inactive_fill") or off and "tertiary_fill" or "fill"]
        end
        return off and p[dark and "quaternary_fill" or "quinary_fill"] or p[n("accent")]
    end)
    local children = {
        rect(vibrant(opts, core.shape {
            translate = { x = INSET, y = s.ty },
            width = track,
            height = s.th,
            radius = theme.CAPSULE,
            hittable = false,
            background = c[n("fill")],
        })),
        rect(core.shape {
            translate = fill:map(function(f) return f.translate end),
            width = fill:map(function(f) return f.w end),
            height = s.th,
            radius = fill:map(function(f) return f.radius end),
            hittable = false,
            background = fill_color,
            animate = ease { translate = MOVE, width = MOVE, background = theme.motion.fade },
            children = {
                rect(core.shape {
                    width = "fill",
                    height = "fill",
                    radius = fill:map(function(f) return f.radius end),
                    hittable = false,
                    background = tg.tone("label", 0.08),
                    opacity = computed({ held, disabled }, function(h, off) return h and not off and 1 or 0 end),
                    animate = { opacity = theme.motion.fade },
                }),
            },
        }),
    }
    local tick_color = computed({ disabled, theme.scheme }, function(off, p)
        return p[n(off and "quaternary_label" or "tertiary_label")]
    end)
    if neutral then
        children[#children + 1] = rect(vibrant(opts, {
            translate = { x = INSET + neutral * track - 1, y = s.ty },
            width = 2,
            height = s.th,
            hittable = false,
            background = c.vibrant_tertiary_label,
        }))
    end
    for i = 0, (ticks or 0) - 1 do
        local mid = neutral and math.abs(i / (ticks - 1) - neutral) < 1e-6
        children[#children + 1] = rect(vibrant(opts, core.shape {
            -- not in the kit: the 2 px ticks sit in the middle of the 4 px tick box
            translate = { x = INSET + 1 + i * (track - 4) / (ticks - 1), y = s.tick + (mid and 0 or 1) },
            width = 2,
            height = mid and 4 or 2,
            radius = 1,
            hittable = false,
            background = mid and computed({ disabled, theme.scheme }, function(off, p) return p[off and "quaternary_label" or "label"] end) or tick_color,
        }))
    end
    local kw, kh = ticks and s.tw or s.kw, ticks and s.tkh or s.kh
    local radius = ticks and s.tkr or theme.CAPSULE
    local idle_fill = opts.on_glass and c.on_accent or c.knob
    local function shape(extra)
        return rect(core.shape(core.merge({ width = "fill", height = "fill", radius = radius, hittable = false }, extra)))
    end
    children[#children + 1] = rect {
        width = kw,
        height = kh,
        hittable = false,
        translate = frac:map(function(f) return { x = INSET + f * track - kw / 2, y = s.ty + s.th / 2 - kh / 2 } end),
        scale = held:map(function(h) return h and GROW or 1 end),
        animate = held:map(function(h) return h and { scale = GROW_SPRING } or { translate = MOVE, scale = GROW_SPRING } end),
        children = {
            shape {
                background = idle_fill,
                shadows = { { color = theme.alpha(theme.CLEAR, 0.12), offset = { y = 0.5 }, blur = 6 } },
                opacity = held:map(function(h) return h and 0 or 1 end),
            },
            shape(material.glass("knob", { opacity = held:map(function(h) return h and 1 or 0 end), animate = { opacity = theme.motion.fade } })),
        },
    }
    props.children = children
    return rect(props)
end

-- Drag around the dial: the grabber follows the pointer's angle.
---@class glass.CircularSliderOpts
---@field value? StateSignal<number> Default `min`.
---@field min? number Default 0.
---@field max? number Default 1.
---@field step? number
---@field size? glass.Size
---@field disabled? boolean|Signal<boolean>
---@field on_glass? boolean
---@field label? string Accessible name.
---@field on_change? fun(value: number)
---@field [string] "no such property"

---@param id string
---@param opts? glass.CircularSliderOpts
---@return Node
function M.circular_slider(id, opts)
    opts = opts or {}
    local s = SIZES[opts.size or "regular"]
    local n = tg.role(opts)
    local lo, hi = opts.min or 0, opts.max or 1
    local D = s.dial
    ---@type StateSignal<number>
    local value = opts.value or state("glass_dial_" .. id, lo)
    local turn = value:map(function(v) return (clamp01(((v or lo) - lo) / (hi - lo)) - 0.5) * SWEEP end)
    local props = { width = D, height = D, radius = theme.CAPSULE }
    local held, disabled = draggable(id, opts, props, function(pointer)
        local angle = math.deg(math.atan(pointer.x - D / 2, D / 2 - pointer.y))
        store(opts, value, lo, hi, clamp01(angle / SWEEP + 0.5))
    end)
    props.background = computed({ held, disabled, theme.scheme }, function(down, off, p)
        if off then
            return theme.alpha(p.label, 0.04)
        end
        return down and theme.alpha(p.label, 0.16) or p[n("secondary_fill")]
    end)
    props.animate = { background = theme.motion.fade }
    local grabber = computed({ disabled, theme.scheme }, function(off, p) return theme.alpha(p.label, off and 0.22 or 0.7) end)
    props.children = {
        rect {
            width = "fill",
            height = "fill",
            hittable = false,
            rotate = turn,
            animate = held:map(function(h) return h and {} or { rotate = MOVE } end),
            children = { rect(vibrant(opts, core.shape {
                translate = { x = (D - s.gw) / 2, y = s.gy },
                width = s.gw,
                height = s.gh,
                radius = 1,
                hittable = false,
                background = grabber,
                animate = { background = theme.motion.fade },
            })) },
        },
    }
    return rect(core.shape(props))
end

return M
