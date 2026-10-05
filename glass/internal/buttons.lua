-- Shared by button.lua, popup_button.lua and color_well.lua: the kit's push-button colours per
-- kind and state (docs/spec/buttons.md) and the pressable, focusable shell every control uses.
local theme = require("glass.theme")
local core = require("glass.core")
local material = require("glass.material")

local merge = core.merge

local M = {}

-- A plain value or a signal, as a signal.
function M.signal(v)
    return type(v) == "userdata" and v or theme.dark:map(function() return v end)
end

local function rgba(hex)
    return tonumber(hex:sub(2, 3), 16), tonumber(hex:sub(4, 5), 16), tonumber(hex:sub(6, 7), 16),
        (tonumber(hex:sub(8, 9), 16) or 255) / 255
end

-- `top` composited over `bottom`: the borderless label's pressed tint, since text takes one colour.
local function over(bottom, top)
    local br, bg, bb, ba = rgba(bottom)
    local tr, tg, tb, ta = rgba(top)
    local a = ta + ba * (1 - ta)
    local function ch(t, b) return math.floor((t * ta + b * ba * (1 - ta)) / a + 0.5) end
    return string.format("#%02X%02X%02X%02X", ch(tr, br), ch(tg, bg), ch(tb, bb), math.floor(a * 255 + 0.5))
end

local PD, PL = "plus_darker", "plus_lighter"
local STATE = { idle = 1, held = 2, disabled = 3 }

-- Kit fills per state (idle, clicked, disabled), each a stack bottom to top of
-- { colour, blend }. `ink` is black on light and white on dark; `false` is no fill.
local BEZEL = {
    content = { light = { { { "#00000014" } }, { { "#00000029" } }, { { "#0000000A" } } },
        dark = { { { "#FFFFFF12" } }, { { "#FFFFFF29" } }, { { "#FFFFFF0A" } } } },
    glass = {
        light = { { { "#0000001F", "overlay" }, { "#00000012", PD } }, { { "#0000001F", "overlay" }, { "#00000021", PD } },
            { { "#0000000F", "overlay" }, { "#00000006", PD } } },
        dark = { { { "#FFFFFF1F", "overlay" }, { "#FFFFFF0D", PL } }, { { "#FFFFFF1F", "overlay" }, { "#FFFFFF21", PL } },
            { { "#FFFFFF0F", "overlay" }, { "#FFFFFF06", PL } } },
    },
}
local TOGGLE_OFF = { light = { "#0000000D", "#00000021", "#00000005" }, dark = { "#FFFFFF0D", "#FFFFFF21", "#FFFFFF05" } }
-- Default buttons: the overlay over the clicked tone, and light content's idle overlay.
local DEFAULT_HELD = { content = { light = { "#0000001A", PD }, dark = { "#FFFFFF1A", PL } },
    glass = { light = { "#00000026", PD }, dark = { "#FFFFFF24", PL } } }
-- Tinted and destructive: the accent at a group opacity per state, with a faint overlay inside it.
local TINT = {
    content = { light = { { 0.22, 0.28, 0.10 }, { "#0000001A", PD } }, dark = { { 0.20, 0.28, 0.12 }, { "#FFFFFF24", PL } } },
    glass = { light = { { 0.20, 0.30, 0.10 }, { "#00000008" } }, dark = { { 0.20, 0.30, 0.10 }, { "#FFFFFF0A", PL } } },
}
-- Toggle: the accent's opacity per state, off and on; dark over-glass adds an overlay shade.
local TOGGLE = {
    content = { off = false, on = { 0.06, 0.16, 0.02 } },
    glass = { off = { 0.06, 0.15, 0.03 }, on = { 0.16, 0.30, 0.03 } },
    glass_dark = { off = { 0.09, 0.16, 0.03 }, on = { 0.20, 0.25, 0.20 },
        shade = { off = { "#00000033", "#00000000", "#0000000D" }, on = { "#00000040", "#00000000", "#00000059" } } },
}

-- `alpha` scaled by `k`.
local function scaled(color, k)
    return theme.alpha(color, select(4, rgba(color)) * k)
end

-- A kit stack (bottom to top) as an engine background list (first on top).
local function layers(stack)
    local out = {}
    for i = #stack, 1, -1 do
        out[#out + 1] = { fill = stack[i][1], blend = stack[i][2] }
    end
    return out
end

-- Fill (a background layer list) and label colour of a control: `kind` as in `button`, `p` the
-- palette, `st` "idle", "held" or "disabled", `on` the toggle or colour-well selection. "plain" is
-- the pop-up/arrow bezel (label `label`, not the vibrant grey) and "well" the colour well's capsule.
function M.look(kind, p, dark, glass, st, on)
    local i, mode, where = STATE[st], dark and "dark" or "light", glass and "glass" or "content"
    local vib = dark and PL or PD
    local accent, red = glass and p.vibrant_accent or p.accent, glass and p.vibrant_red or p.red
    local label = st == "disabled" and (glass and p.vibrant_tertiary_label or p.tertiary_label)
        or (glass or not dark and kind ~= "plain") and p.vibrant_label or p.label
    local bezel = BEZEL[where][mode][i]

    if kind == "well" then
        if on and st ~= "disabled" then
            return layers({ { p.accent }, { dark and "#FFFFFF0F" or "#0000000F", vib } })
        end
        return layers(BEZEL.content[mode][i])
    elseif kind == "toggle" then
        local t = glass and dark and TOGGLE.glass_dark or TOGGLE[where]
        local alphas = t[on and "on" or "off"]
        local stack = alphas and { { theme.alpha(accent, alphas[i]), not (glass and dark) and PD or nil } }
            or { { TOGGLE_OFF[mode][i] } }
        if t.shade then
            stack[2] = { t.shade[on and "on" or "off"][i], "overlay" }
        end
        if on then
            label = st == "disabled" and theme.alpha(accent, glass and 0.3 or 0.4) or accent
        end
        return layers(stack), label
    elseif kind == "default" or kind == "default_destructive" then
        local tone = kind == "default" and p.vibrant_accent or p.vibrant_red
        if st == "disabled" then
            return layers({ { theme.alpha(tone, 0.4) } }), theme.alpha(p.on_accent, 0.5)
        elseif st == "held" then
            return layers({ { tone }, DEFAULT_HELD[where][mode] }), p.on_accent
        end
        local stack = { { glass and tone or (kind == "default" and p.accent or p.red) } }
        if kind == "default" and not glass and not dark then
            stack[2] = { "#00000008", PD }
        end
        return layers(stack), p.on_accent
    elseif kind == "tinted" or kind == "destructive" then
        local tone = kind == "tinted" and accent or red
        local t = TINT[where][mode]
        local k = t[1][i]
        return layers({ { theme.alpha(tone, k) }, { scaled(t[2][1], k), t[2][2] } }),
            st == "disabled" and theme.alpha(tone, glass and 0.25 or 0.4) or tone
    elseif kind == "borderless" then
        local tint = st == "held" and over(accent, glass and dark and "#FFFFFF2E" or "#0000002E") or accent
        return {}, st == "disabled" and theme.alpha(accent, 0.5) or tint
    end
    return layers(bezel), label
end

-- Props for a label or glyph on the control: vibrant on glass, except on the coloured kinds.
function M.vibrant(o)
    local flat = o.kind == "default" or o.kind == "default_destructive"
    return o.on_glass and not flat and material.vibrant({}) or {}
end

-- The control itself: a pressable, keyboard-focusable row of `content(label_colour, disabled)`.
-- `o`: size, kind, on_glass, disabled, on (selection signal), width, padding, radius, name,
-- on_click, props (extra node props).
function M.control(id, o, content)
    local size = theme.SIZES[o.size or "regular"]
    local disabled = M.signal(o.disabled or false)
    local props = merge({
        id = id,
        height = size.height,
        width = o.width,
        padding = o.padding,
        radius = o.radius or size.radius,
        accessible_name = o.name or id,
        focus_ring = false,
        on_click = function()
            if not disabled:get() and o.on_click then
                o.on_click()
            end
        end,
    }, o.props)
    local held = core.pressable(id, props)
    local focus = focused("glass_focus_" .. id)
    local look = computed({ theme.scheme, theme.dark, held, disabled, M.signal(o.on or false) },
        function(p, dark, down, off, selected)
            local fill, label = M.look(o.kind, p, dark, o.on_glass, off and "disabled" or down and "held" or "idle", selected)
            return { fill = fill, label = label }
        end)
    props.background = look:map(function(l) return l.fill end)
    props.focused = focus
    props.shadows = computed({ focus, theme.scheme }, function(on, p) return on and core.focus_ring(p.accent) or {} end)
    props.children = content(look:map(function(l) return l.label end), disabled)
    return row(core.shape(props))
end

return M
