-- Progress indicators: a linear bar (determinate or indeterminate), a circular ring and the
-- spinner. Indeterminate motion is an engine keyframe loop, so no Lua runs per frame.
local theme = require("glass.theme")
local core = require("glass.core")
local material = require("glass.material")
local tg = require("glass.internal.toggles")

local BAR_HEIGHT = { s = 6, m = 10 }
-- Ring: outer diameter and ring width. Spinner: box, spoke width and length.
local RING = { s = { d = 16, w = 5 }, m = { d = 32, w = 5 } }
local SPINNER = { s = { d = 16, w = 2, l = 5 }, m = { d = 32, w = 4, l = 10 } }
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

-- The fill: the accent, grey while the window is inactive.
local function fill_color(opts)
    local n = tg.role(opts)
    return computed({ core.active(opts.window), theme.scheme }, function(a, p) return p[a and n("accent") or n("inactive_progress")] end)
end

-- Bar; fills go grey while the window is inactive.
---@class glass.ProgressBarOpts
---@field value? number|Signal<number> 0..1.
---@field indeterminate? boolean|Signal<boolean> A moving gradient fill.
---@field size? "s"|"m" 6 or 10 px.
---@field width? number Default 140.
---@field on_glass? boolean
---@field name? string Accessible name; default "progress" ("loading" for the spinner).
---@field window? string
---@field [string] "no such property"

---@param _ any Unused.
---@param opts? glass.ProgressBarOpts
---@return Node
function M.progress_bar(_, opts)
    opts = opts or {}
    local h = BAR_HEIGHT[opts.size or "m"]
    local W = opts.width or 140
    local indeterminate = tg.sig(opts.indeterminate or false)
    local fill = fill_color(opts)
    local function bar(extra)
        extra.height = "fill"
        extra.radius = theme.CAPSULE
        extra.hittable = false
        extra.background = fill
        extra.animate = core.merge({ background = theme.motion.fade }, extra.animate)
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
        accessible_name = opts.name or "progress",
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

---@class glass.ProgressRingOpts
---@field value? number|Signal<number> 0..1.
---@field indeterminate? boolean|Signal<boolean> The spinner in place of the ring, as this platform shows indefinite waits.
---@field size? "s"|"m" 16 or 32 px.
---@field on_glass? boolean
---@field name? string Accessible name; default "progress" ("loading" for the spinner).
---@field window? string
---@field [string] "no such property"

---@param _ any Unused.
---@param opts? glass.ProgressRingOpts
---@return Node
function M.progress_ring(_, opts)
    opts = opts or {}
    local s = RING[opts.size or "m"]
    local r = (s.d - s.w) / 2
    local commands = { { op = "A", points = { s.d / 2, s.d / 2, r, -90, 360 } } }
    local function arc(extra)
        extra.width = s.d
        extra.height = s.d
        extra.stroke_width = s.w
        extra.commands = commands
        return path(extra)
    end
    local ring = rect {
        width = s.d,
        height = s.d,
        accessible_name = opts.name or "progress",
        children = {
            arc { stroke = wash(0.06, 0.08) },
            arc {
                stroke = fill_color(opts),
                stroke_cap = "round",
                trim_end = fraction(opts),
                animate = { trim_end = theme.motion.default, stroke = theme.motion.fade },
            },
        },
    }
    local ind = opts.indeterminate
    if not ind then
        return ring
    end
    local spin = M.spinner(nil, { size = opts.size, name = opts.name, window = opts.window })
    if type(ind) ~= "userdata" then
        return spin
    end
    return rect { children = (ind --[[@as Signal<boolean>]]):map(function(on) return { on and spin or ring } end) }
end

-- The lead spoke steps round the circle clockwise.
---@class glass.SpinnerOpts
---@field size? "s"|"m" 16 or 32 px.
---@field name? string Accessible name; default "progress" ("loading" for the spinner).
---@field window? string
---@field [string] "no such property"

---@param _ any Unused.
---@param opts? glass.SpinnerOpts
---@return Node
function M.spinner(_, opts)
    opts = opts or {}
    local s = SPINNER[opts.size or "m"]
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
        accessible_name = opts.name or "loading",
        opacity = core.active(opts.window):map(function(a) return a and 1 or 0.5 end),
        animate = { rotate = SPIN, opacity = theme.motion.fade },
        children = spokes,
    }
end

return M
