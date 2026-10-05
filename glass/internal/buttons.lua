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

-- `top` composited over `bottom`. Stands in for the kit's plus-darker/plus-lighter overlays until
-- `material.HAS.blend`.
function M.over(bottom, top)
    local br, bg, bb, ba = rgba(bottom)
    local tr, tg, tb, ta = rgba(top)
    local a = ta + ba * (1 - ta)
    local function ch(t, b) return math.floor((t * ta + b * ba * (1 - ta)) / a + 0.5) end
    return string.format("#%02X%02X%02X%02X", ch(tr, br), ch(tg, bg), ch(tb, bb), math.floor(a * 255 + 0.5))
end

-- Fill alphas (of black on light, white on dark; /255) for idle, clicked, disabled. Over-glass is
-- the kit's overlay plus its PD/PL fill, flattened into one.
local BEZEL = {
    content = { light = { 20, 41, 10 }, dark = { 18, 41, 10 } },
    glass = { light = { 47, 60, 21 }, dark = { 43, 60, 21 } },
}
local TOGGLE_OFF = { 13, 33, 5 }
-- Accent alphas for idle, clicked, disabled.
local TINT = {
    tinted = { light = { 0.22, 0.28, 0.10 }, dark = { 0.20, 0.28, 0.12 } },
    destructive = { light = { 0.20, 0.28, 0.10 }, dark = { 0.20, 0.28, 0.12 } },
    glass = { 0.20, 0.30, 0.10 },
}
local TOGGLE_ON = { content = { 0.06, 0.16, 0.02 }, glass = { 0.16, 0.30, 0.03 } }
local STATE = { idle = 1, held = 2, disabled = 3 }

-- Fill and label colour of a control: `kind` as in `button`, `p` the palette, `st` "idle", "held"
-- or "disabled", `on` the toggle or colour-well selection. "plain" is the pop-up/arrow bezel
-- (label `label`, not the vibrant grey) and "well" the colour well's capsule.
function M.look(kind, p, dark, glass, st, on)
    local i, mode = STATE[st], dark and "dark" or "light"
    local ink = p.label:sub(1, 7)
    local function bezel(alphas) return theme.alpha(ink, alphas[i] / 255) end
    local accent, red = glass and p.vibrant_accent or p.accent, glass and p.vibrant_red or p.red
    local label = st == "disabled" and (glass and p.vibrant_tertiary_label or p.tertiary_label)
        or (glass or not dark and kind ~= "plain") and p.vibrant_label or p.label
    local fill = bezel(glass and BEZEL.glass[mode] or BEZEL.content[mode])

    if kind == "well" then
        return on and st ~= "disabled" and M.over(p.accent, theme.alpha(ink, 0.06)) or fill
    elseif kind == "toggle" then
        fill = glass and fill or bezel(TOGGLE_OFF)
        if on then
            local a = (glass and TOGGLE_ON.glass or TOGGLE_ON.content)[i]
            fill = M.over(fill, theme.alpha(accent, a))
            label = st == "disabled" and theme.alpha(accent, glass and 0.3 or 0.4) or accent
        end
        return fill, label
    elseif kind == "default" or kind == "default_destructive" then
        local tone = kind == "default" and p.vibrant_accent or p.vibrant_red
        if st == "disabled" then
            return theme.alpha(tone, 0.4), theme.alpha(p.on_accent, 0.5)
        end
        local base = st == "idle" and not glass and (kind == "default" and p.accent or p.red) or tone
        return st == "held" and M.over(base, theme.alpha(ink, glass and 0.15 or 0.10)) or base, p.on_accent
    elseif kind == "tinted" or kind == "destructive" then
        local tone = kind == "tinted" and accent or red
        local alphas = glass and TINT.glass or TINT[kind][mode]
        return theme.alpha(tone, alphas[i]), st == "disabled" and theme.alpha(tone, glass and 0.25 or 0.4) or tone
    elseif kind == "borderless" then
        local tint = st == "held" and M.over(accent, theme.alpha(ink, 0.18)) or accent
        return theme.CLEAR, st == "disabled" and theme.alpha(accent, 0.5) or tint
    end
    return fill, label
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
