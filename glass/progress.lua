-- Progress indicators: a linear bar (determinate or indeterminate), a circular ring and the
-- spinner. Indeterminate motion is an engine keyframe loop, so no Lua runs per frame.
local theme = require("glass.theme")
local core = require("glass.core")
local material = require("glass.material")
local tg = require("glass.internal.toggles")

local c = theme.c

local BAR_HEIGHT = { small = 6, regular = 10 }
-- Ring: outer diameter and ring width. Spinner: box, spoke width and length.
local RING = { small = { d = 16, w = 5 }, regular = { d = 32, w = 5 } }
local SPINNER = { small = { d = 16, w = 2, l = 5 }, regular = { d = 32, w = 4, l = 10 } }
-- Spinner alpha of spokes 1..8; spoke 1 is the lead, at the top, and the rest go clockwise.
local SPOKES = { 0.55, 0.06, 0.13, 0.20, 0.27, 0.34, 0.41, 0.48 }
-- not in the kit: the motion of the indeterminate bar and the spinner (kit has none)
local SLIDE = { duration = 1600, easing = "in_out_quad", loops = "infinite" }
local SPIN = { duration = 800, easing = { steps = 8 }, loops = "infinite", keyframes = { 0, 360 } }

local M = {}

local function clamp01(x) return math.max(0, math.min(1, x)) end

-- A signal of the clamped value of `opts.value` (a number or a signal), 0 when absent.
local function fraction(opts)
    return tg.sig(opts.value or 0):map(clamp01)
end

-- The label colour at the kit's track alphas: light, dark.
local function wash(light, dark)
    return computed({ theme.dark, theme.scheme }, function(is_dark, p) return theme.alpha(p.label, is_dark and dark or light) end)
end

-- opts: value (0..1 number or signal), indeterminate (boolean or signal: a moving gradient fill),
-- size ("small" 6 px or "regular" 10 px), width (default 140), on_glass.
function M.progress_bar(_, opts)
    opts = opts or {}
    local h = BAR_HEIGHT[opts.size or "regular"]
    local W = opts.width or 140
    local indeterminate = tg.sig(opts.indeterminate or false)
    local fill = c[tg.role(opts)("accent")]
    local function bar(extra)
        extra.height = "fill"
        extra.radius = theme.CAPSULE
        extra.hittable = false
        extra.background = fill
        return rect(core.shape(extra))
    end
    local track = {
        width = W,
        height = h,
        radius = theme.CAPSULE,
        clip = "rounded",
        background = wash(0.06, 0.08),
        border_width = 0.5,
        border_color = wash(0.07, 0.04),
        accessible_name = "progress",
        children = {
            bar {
                width = fraction(opts):map(function(f) return f * W end),
                visible = indeterminate:map(function(on) return not on end),
                animate = { width = theme.motion.default },
            },
            bar {
                -- the kit's fill is 60% of the track, fading out along its length
                width = W * 0.6,
                visible = indeterminate,
                mask = { gradient = "linear", angle = 90, stops = { { 0, "#000000FF" }, { 1, "#00000000" } } },
                animate = { translate = core.merge({ keyframes = { { x = -W * 0.6 }, { x = W } } }, SLIDE) },
            },
        },
    }
    return rect(opts.on_glass and material.vibrant(core.shape(track)) or core.shape(track))
end

-- opts: value (0..1 number or signal), size ("small" 16 px or "regular" 32 px), on_glass.
function M.progress_ring(_, opts)
    opts = opts or {}
    local s = RING[opts.size or "regular"]
    local r = (s.d - s.w) / 2
    local commands = { { op = "A", points = { s.d / 2, s.d / 2, r, -90, 360 } } }
    local function arc(extra)
        extra.width = s.d
        extra.height = s.d
        extra.stroke_width = s.w
        extra.commands = commands
        return path(extra)
    end
    return rect {
        width = s.d,
        height = s.d,
        accessible_name = "progress",
        children = {
            arc { stroke = wash(0.06, 0.08) },
            arc {
                stroke = c[tg.role(opts)("accent")],
                stroke_cap = "round",
                trim_end = fraction(opts),
                animate = { trim_end = theme.motion.default },
            },
        },
    }
end

-- opts: size ("small" 16 px or "regular" 32 px). The lead spoke steps round the circle clockwise.
function M.spinner(_, opts)
    opts = opts or {}
    local s = SPINNER[opts.size or "regular"]
    local spokes = {}
    for i, alpha in ipairs(SPOKES) do
        spokes[i] = rect {
            width = s.d,
            height = s.d,
            hittable = false,
            rotate = (i - 1) * 45,
            children = { rect(core.shape {
                translate = { x = (s.d - s.w) / 2 },
                width = s.w,
                height = s.l,
                radius = theme.CAPSULE,
                hittable = false,
                background = wash(alpha, alpha),
            }) },
        }
    end
    return rect {
        width = s.d,
        height = s.d,
        accessible_name = "loading",
        animate = { rotate = SPIN },
        children = spokes,
    }
end

return M
