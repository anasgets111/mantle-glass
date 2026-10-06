-- Level indicators after NSLevelIndicator: a capacity bar, continuous or in cells, that turns
-- green, yellow then red as the value reaches the warning and critical marks, and a star rating.
local theme = require("glass.theme")
local core = require("glass.core")
local tg = require("glass.internal.toggles")

-- not in the kit: bar thickness per size, cell gap and corner radius, star points per size and
-- the star's inner radius as a fraction of its outer radius (the regular five-point star)
local HEIGHT = { xs = 6, s = 6, m = 10, l = 12, xl = 14 }
local CELL_GAP, CELL_RADIUS = 2, 2
local STAR = { xs = 10, s = 12, m = 16, l = 20, xl = 24 }
local STAR_GAP = 2
local STAR_INNER = 0.382

local M = {}

local function wash(light, dark)
    return computed({ theme.dark, theme.scheme }, function(is_dark, p) return theme.alpha(p.label, is_dark and dark or light) end)
end

-- Level indicator. Marks follow NSLevelIndicator: yellow from `warning` up, red from `critical` up.
---@class glass.LevelIndicatorOpts
---@field value? StateSignal<number>|number Default `min`; for `rating`, the stars lit, a state when `editable`.
---@field style? "continuous"|"discrete"|"rating" Default "continuous".
---@field min? number Default 0.
---@field max? number Default 1; for `rating`, the star count, default 5.
---@field warning? number
---@field critical? number
---@field cells? integer Cells of `discrete`; default 10.
---@field editable? boolean `rating` only: a click or the arrow keys set the stars.
---@field width? number Bars; default 140.
---@field size? glass.Size
---@field disabled? boolean|Signal<boolean>
---@field window? string
---@field on_change? fun(value: number)
---@field [string] "no such property"

---@param id string
---@param opts? glass.LevelIndicatorOpts
---@return Node
function M.level_indicator(id, opts)
    opts = opts or {}
    local style = opts.style or "continuous"
    local size = opts.size or "m"
    local rating = style == "rating"
    local lo, hi = opts.min or 0, opts.max or (rating and 5 or 1)
    local value = opts.value
    if type(value) ~= "userdata" then
        value = value or lo
        value = state("glass_level_" .. id, value)
    end
    local disabled = tg.sig(opts.disabled)
    local active = core.active(opts.window)
    local function level(v)
        if opts.critical and v >= opts.critical then
            return "red"
        end
        return opts.warning and v >= opts.warning and "yellow" or "green"
    end
    local function colour(p, a, off, v)
        if off then
            return p.tertiary_label
        end
        return a and p[level(v)] or p.inactive_progress
    end

    if rating then
        local S = STAR[size]
        local sw = S / 10
        local R = S / 2 - sw / 2
        local commands = {}
        for k = 0, 9 do
            local r = k % 2 == 0 and R or R * STAR_INNER
            local a = math.rad(-90 + k * 36)
            commands[#commands + 1] = { op = k == 0 and "M" or "L", points = { S / 2 + r * math.cos(a), S / 2 + r * math.sin(a) + S / 20 } }
        end
        commands[#commands + 1] = { op = "Z", points = {} }
        local stars = {}
        for i = 1, hi do
            local paint = computed({ value, active, disabled, theme.scheme }, function(v, a, off, p)
                if (v or 0) < i then
                    return p.tertiary_label
                end
                return off and p.quaternary_label or a and p.yellow or p.secondary_label
            end)
            stars[i] = path {
                width = S,
                height = S,
                commands = commands,
                fill = paint,
                stroke = paint,
                stroke_width = sw,
                stroke_join = "round",
                hittable = false,
                animate = { fill = theme.motion.fade, stroke = theme.motion.fade },
            }
        end
        local function set(v)
            v = math.max(0, math.min(hi, v))
            if v ~= value:get() then
                value:set(v)
                if opts.on_change then
                    opts.on_change(v)
                end
            end
        end
        local props = { spacing = STAR_GAP, align_v = "center", children = stars, accessible_name = id }
        if opts.editable then
            props.radius = 4
            props.on_click = function(_, _, pointer)
                if not disabled:get() then
                    set(math.floor(pointer.x / (S + STAR_GAP)) + 1)
                end
            end
            props.hittable = disabled:map(function(off) return not off end)
            props.on_key = function(k)
                local dir = ({ Right = 1, Up = 1, Left = -1, Down = -1 })[k.name]
                if dir and not disabled:get() then
                    set((value:get() or 0) + dir)
                    return true
                end
            end
            core.focusable("level_" .. id, props)
        end
        return row(props)
    end

    local W, H = opts.width or 140, HEIGHT[size]
    local frac = value:map(function(v) return math.max(0, math.min(1, ((v or lo) - lo) / (hi - lo))) end)
    if style == "discrete" then
        local n = opts.cells or 10
        local w = (W - CELL_GAP * (n - 1)) / n
        local children = {}
        for i = 1, n do
            local top = lo + i / n * (hi - lo)
            children[i] = rect(core.shape {
                width = w,
                height = H,
                radius = CELL_RADIUS,
                background = computed({ value, active, disabled, theme.scheme }, function(v, a, off, p)
                    local lit = ((v or lo) - lo) / (hi - lo) * n > i - 0.5
                    if not lit then
                        return theme.alpha(p.label, off and 0.04 or 0.1)
                    end
                    return colour(p, a, off, top)
                end),
                animate = { background = theme.motion.fade },
            })
        end
        return row { spacing = CELL_GAP, accessible_name = id, children = children }
    end
    return rect(core.shape {
        width = W,
        height = H,
        radius = theme.CAPSULE,
        clip = "rounded",
        background = wash(0.06, 0.08),
        border_width = 0.5,
        border_color = wash(0.07, 0.04),
        accessible_name = id,
        children = { rect(core.shape {
            width = frac:map(function(f) return f * W end),
            height = "fill",
            radius = theme.CAPSULE,
            background = computed({ value, active, disabled, theme.scheme }, function(v, a, off, p) return colour(p, a, off, v or lo) end),
            animate = { width = theme.motion.default, background = theme.motion.fade },
        }) },
    })
end

return M
