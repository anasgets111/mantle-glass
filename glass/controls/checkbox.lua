-- Checkbox and radio group: a square (checkbox) or round (radio) box with the label to its right.
-- The box is filled blue when on or mixed, grey when off, and goes darker or lighter while pressed.
local theme = require("glass.theme")
local core = require("glass.core")
local material = require("glass.material")
local tg = require("glass.internal.toggles")

local FADE = theme.motion.fade

-- Per size: box, checkbox radius, label gap (checkbox, radio), frame height, label style, then the
-- check and dash as { x, y, w, h } inside the box, and the radio dot's diameter.
local SIZES = {
    xs = { box = 12, radius = 3.5, gap = { 3, 3 }, frame = 14, label = "control_mini", check = { 2.1, 2.2, 7.9, 7.6 }, dash = { 3.2, 5.1, 5.5, 1.7 }, dot = 4 },
    s = { box = 14, radius = 4.5, gap = { 4, 3 }, frame = 18, label = "control_small", check = { 2.3, 2.5, 9.3, 8.9 }, dash = { 3.8, 6, 6.5, 2 }, dot = 4.8 },
    m = { box = 16, radius = 5.5, gap = { 5, 3 }, frame = 24, label = "control", check = { 3.3, 3.5, 9.3, 8.9 }, dash = { 4.8, 7, 6.5, 2 }, dot = 4.8 },
    l = { box = 18, radius = 6.5, gap = { 5, 5 }, frame = 28, label = "control", check = { 3.1, 3.4, 11.7, 11.3 }, dash = { 5, 8, 8, 2 }, dot = 5 },
    xl = { box = 18, radius = 6.5, gap = { 7, 7 }, frame = 36, label = "control", check = { 3.1, 3.4, 11.7, 11.3 }, dash = { 5, 8, 8, 2 }, dot = 5 },
}
local RADIO_GROUP_GAP = 12 -- not in the kit: spacing of a horizontal radio group

local M = {}

-- `status` is a signal of "off", "mixed" or "on"; `activate` runs on click.
local function choice(id, opts, radio, status, activate)
    local s = SIZES[opts.size or "m"]
    local n = tg.role(opts)
    local disabled = tg.sig(opts.disabled)
    local active = core.active(opts.window)
    local props = { accessible_name = opts.name or type(opts.label) == "string" and opts.label or id, height = s.frame, spacing = s.gap[radio and 2 or 1] }
    local held, focused = tg.interact("cb_" .. id, props, opts, activate)
    local on = status:map(function(v) return v ~= "off" end)
    local dim = computed({ disabled, active }, function(d, a) return d and a and 0.5 or 1 end)
    local glyph = computed({ active, disabled, theme.scheme }, function(a, d, p)
        return a and p.on_accent or p[d and "inactive_glyph_disabled" or "inactive_glyph"]
    end)
    local ck, dh = s.check, s.dash
    local mark
    if radio then
        mark = rect(core.shape {
            width = s.dot,
            height = s.dot,
            radius = s.dot / 2,
            align_h = "center",
            align_v = "center",
            background = glyph,
            scale = status:map(function(v) return v == "on" and 1 or 0 end),
            opacity = dim,
            animate = { scale = theme.motion.snappy, background = FADE },
        })
    else
        mark = path {
            width = ck[3],
            height = ck[4],
            margin = { left = ck[1], top = ck[2] },
            stroke = glyph,
            stroke_width = ck[3] * 0.2,
            stroke_cap = "round",
            stroke_join = "round",
            opacity = dim,
            trim_end = status:map(function(v) return v == "on" and 1 or 0 end),
            animate = { trim_end = { duration = 150, easing = "out_quad" } },
            commands = {
                { op = "M", points = { ck[3] * 0.1, ck[4] * 0.58 } },
                { op = "L", points = { ck[3] * 0.36, ck[4] * 0.93 } },
                { op = "L", points = { ck[3] * 0.93, ck[4] * 0.06 } },
            },
        }
    end
    props.children = {
        rect(core.shape {
            width = s.box,
            height = s.box,
            radius = radio and s.box / 2 or s.radius,
            align_v = "center",
            shadows = tg.ring(focused),
            background = computed({ on, held, disabled, active, theme.scheme }, function(checked, h, d, a, p)
                if checked then
                    return a and p[n("accent")] or p[d and "inactive_disabled_fill" or "inactive_fill"]
                end
                return h and theme.alpha(p.label, 0.19) or p[d and (a and n("tertiary_fill") or "quaternary_fill") or n("fill")]
            end),
            opacity = computed({ on, disabled, active }, function(checked, d, a) return d and checked and a and 0.45 or 1 end),
            animate = { background = FADE, opacity = FADE },
            children = {
                tg.pressed_tint(radio and s.box / 2 or s.radius, held, on),
                mark,
                rect(core.shape {
                    width = dh[3],
                    height = dh[4],
                    radius = dh[4] / 2,
                    margin = { left = dh[1], top = dh[2] },
                    background = glyph,
                    opacity = computed({ status, dim }, function(v, k) return v == "mixed" and k or 0 end),
                    animate = { opacity = FADE, background = FADE },
                }),
            },
        }),
        opts.label and core.text(opts.label, computed({ disabled, theme.scheme }, function(d, p)
            return p[d and n("tertiary_label") or "vibrant_label"]
        end), s.label, material.vibrant({})) or nil,
    }
    return row(props)
end

-- Checkbox.
---@class glass.CheckboxOpts: glass.ControlOpts
---@field value? StateSignal<boolean|"mixed"> A click on mixed turns on.
---@field label? string|Signal<string> Text beside the box.
---@field name? string Accessible name; default the label.
---@field on_change? fun(value: boolean)
---@field [string] "no such property"

---@param id string
---@param opts? glass.CheckboxOpts
---@return Node
function M.checkbox(id, opts)
    opts = opts or {}
    ---@type StateSignal<boolean|"mixed">
    local value = opts.value or state("glass_check_" .. id, false)
    local status = value:map(function(v) return v == "mixed" and "mixed" or v and "on" or "off" end)
    return choice(id, opts, false, status, function()
        local on = value:get() ~= true
        value:set(on)
        if opts.on_change then
            opts.on_change(on)
        end
    end)
end

-- Radio group.
---@class glass.RadioGroupOpts: glass.ControlOpts
---@field options string[] Labels.
---@field value? StateSignal<string> The chosen label; default the first.
---@field horizontal? boolean
---@field name? string Accessible name of the group.
---@field on_change? fun(label: string)
---@field [string] "no such property"

---@param id string
---@param opts glass.RadioGroupOpts
---@return Node
function M.radio_group(id, opts)
    local value = opts.value or state("glass_radio_" .. id, opts.options[1])
    local kids = {}
    for i, option in ipairs(opts.options) do
        local status = value:map(function(v) return v == option and "on" or "off" end)
        kids[i] = choice(id .. i, core.merge(core.merge({}, opts), { label = option, name = false }), true, status, function()
            value:set(option)
            if opts.on_change then
                opts.on_change(option)
            end
        end)
    end
    return (opts.horizontal and row or column) { accessible_name = opts.name, spacing = opts.horizontal and RADIO_GROUP_GAP or 0, children = kids }
end

return M
