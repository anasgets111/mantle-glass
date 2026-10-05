-- Liquid Glass and the standard materials, transcribed from Apple's UI kit. `M.glass(style,
-- props)` spreads one style onto a box's props, following light and dark.
--
-- Kit notation, kept as written so it can be checked against glass/docs/spec/foundations.md:
-- a fill is "RRGGBB[AA] [mode]", a shadow "RRGGBB[AA] [mode] x y blur spread", listed bottom to
-- top as Sketch does. Modes: +L plus-lighter, +D plus-darker, or a CSS blend name.
local theme = require("glass.theme")

local M = {}

-- ponytail: engine features land one by one (mantle-27). Each flag gates one; while it is off the
-- style degrades to what the engine has. Delete the flags and the fallbacks once all are true.
M.HAS = { layers = true, blend = theme.BLEND, inset = true, effect = true }

local MODES = { ["+L"] = "plus_lighter", ["+D"] = "plus_darker" }

local function color(hex)
    return "#" .. (#hex == 6 and hex .. "FF" or hex)
end

local function words(s)
    local out = {}
    for w in s:gmatch("%S+") do
        out[#out + 1] = w
    end
    return out
end

-- "RRGGBB [mode]" -> { fill, blend }
local function fill(s)
    local w = words(s)
    return { fill = color(w[1]), blend = w[2] and (MODES[w[2]] or w[2]) or nil }
end

-- "RRGGBB [mode] x y blur spread" -> shadow layer
local function shadow(s, inset)
    local w = words(s)
    local mode = tonumber(w[2]) == nil and table.remove(w, 2) or nil
    return {
        color = color(w[1]),
        offset = { x = tonumber(w[2]), y = tonumber(w[3]) },
        blur = tonumber(w[4]),
        spread = tonumber(w[5]),
        inset = inset or nil,
        blend = mode and (MODES[mode] or mode) or nil,
    }
end

-- Styles: per appearance, `fills`, `drops` and `inner` in kit order, `blur`/`saturate` for the
-- backdrop, and `flat`, the single colour used while layered fills are unavailable.
M.STYLES = {
    -- Toolbar buttons and groups, search fields, segmented controls in toolbars. Capsule.
    small = {
        light = {
            blur = 6, saturate = 2, flat = "#F6F6F6C0",
            fills = { "00000040", "FFFFFF40", "44444499 +L", "F8F8F833 luminosity" },
            inner = { "D9D9D9 +D 20 0 20 -30", "D9D9D9 +D -20 0 20 -30", "666666 +L 0 -4 0.5 -4", "666666 +L 0 4 0.5 -4",
                "171717 +L 0 -1 0 0", "171717 +L 0 1 0 0", "E6E6E6 +D 0 40 30 -40", "282828 +L 0 -40 10 -40", "282828 +L 0 40 10 -40" },
            drops = { "00000005 0 8 15 0", "DBDBDB +D 0 0 0 0.5", "DBDBDB +D -1.25 0 0 -0.75", "DBDBDB +D 1.25 0 0 -0.75" },
        },
        dark = {
            blur = 6, saturate = 1, flat = "#3A3A3AC0",
            fills = { "000000 screen", "9999992B" },
            inner = { "B2B2B2 +D 20 0 20 -30", "B2B2B2 +D -20 0 20 -30", "666666 +L 0 -4 0.5 -4", "666666 +L 0 4 0.5 -4",
                "171717 +L 0 -1 0 0", "171717 +L 0 1 0 0", "1A1A1A +L 0 -40 10 -40", "1A1A1A +L 0 40 10 -40" },
            drops = { "0000000A 0 8 15 0", "A6A6A6 +D 0 0 0 0.5", "A6A6A6 +D -1.25 0 0 -0.75", "A6A6A6 +D 1.25 0 0 -0.75" },
        },
    },
    -- Small glass while the window is inactive: no blur, a faint fill and rim.
    small_inactive = {
        light = { flat = "#00000005", fills = { "00000005" },
            drops = { "EBEBEB +D 0 0 0 0.5", "F2F2F2 +D -0.75 0 0 -0.25", "F2F2F2 +D 0.75 0 0 -0.25" } },
        dark = { flat = "#FFFFFF0D", fills = { "FFFFFF0D" },
            drops = { "E6E6E6 +D 0 0 0 0.5", "CCCCCC +D -1 0 0 -0.5", "CCCCCC +D 1 0 0 -0.5" } },
    },
    -- Tinted small glass; `TINT` is replaced by the tint colour.
    small_tinted = {
        light = {
            blur = 6, saturate = 1, flat = "TINT",
            fills = { "FFFFFFF5", "TINT +D" },
            inner = { "D9D9D9 +D 20 0 20 -30", "D9D9D9 +D -20 0 20 -30", "999999 +L 0 -4 0.5 -4", "999999 +L 0 4 0.5 -4",
                "262626 +L 0 -1 0 0", "262626 +L 0 1 0 0", "111111 +L 0 -40 10 -40", "111111 +L 0 40 10 -40" },
            drops = { "0000000A 0 8 15 0", "DBDBDB +D 0 0 0 0.5", "DBDBDB +D -1.25 0 0 -0.75", "DBDBDB +D 1.25 0 0 -0.75" },
        },
        dark = {
            blur = 6, saturate = 1, flat = "TINT",
            fills = { "FFFFFFF5", "TINT +D" },
            inner = { "B2B2B2 +D 20 0 20 -30", "B2B2B2 +D -20 0 20 -30", "999999 +L 0 -4 0.5 -4", "999999 +L 0 4 0.5 -4",
                "262626 +L 0 -1 0 0", "262626 +L 0 1 0 0", "111111 +L 0 -40 10 -40", "111111 +L 0 40 10 -40" },
            drops = { "0000000A 0 8 15 0", "D9D9D9 +D 0 0 0 0.5", "CCCCCC +D -1.25 0 0 -0.75", "CCCCCC +D 1.25 0 0 -0.75" },
        },
    },
    -- The knob of a switch or slider while it is dragged. Capsule; the kit gives no blend modes.
    knob = {
        light = {
            blur = 4, saturate = 1, flat = "#FFFFFF40",
            inner = { "666666 0 -4 0.5 -4", "666666 0 4 0.5 -4", "171717 0 -1 0 -0.25", "171717 0 1 0 -0.25",
                "F2F2F2 0 20 20 -20", "333333 0 -40 10 -40", "333333 0 40 10 -40" },
            drops = { "D9D9D9 0 0 0 1", "FFFFFF73 0 0 0 0.5" },
        },
        dark = {
            blur = 4, saturate = 1, flat = "#FFFFFF26",
            inner = { "666666 0 -4 0.5 -4", "666666 0 4 0.5 -4", "171717 0 -1 0 -0.25", "171717 0 1 0 -0.25",
                "F2F2F2 0 20 20 -20", "333333 0 -40 10 -40", "333333 0 40 10 -40" },
            drops = { "00000033 0 0 0 1" },
        },
    },
    -- Popovers, panels and other large glass. Radius 20.
    large = {
        light = {
            blur = 30, saturate = 1.4, flat = "#FFFFFFB2",
            fills = { "FFFFFFB2 lighten", "BFBFBF1A darken" },
            inner = { "272727 +L 0 -4 8 -4", "272727 +L 0 4 8 -4", "272727 +L 0 -1 1.5 -0.5", "272727 +L 0 1 1.5 -0.5", "FFFFFF 0 2 0.25 -1.5" },
            drops = { "00000040 0 18 46 0", "DBDBDB80 +D 0 0 0.3 0.3", "DBDBDB +D 1.25 0 0 -0.75", "DBDBDB +D -1.25 0 0 -0.75" },
        },
        dark = {
            blur = 30, saturate = 1.2, flat = "#1A1A1A99",
            fills = { "1A1A1A80", "1A1A1A80 luminosity", "1A1A1A lighten" },
            inner = { "343434 +L 0 -4 8 -4", "343434 +L 0 4 8 -4", "676767 +L 0 -1 1.5 -0.5", "676767 +L 0 1 1.5 -0.5", "FFFFFF33 0 2 0.2 -1.2" },
            drops = { "00000073 0 18 48 0", "A6A6A6CC +D 0 0 0.3 0.3", "A6A6A6 +D 1.25 0 0 -0.75", "A6A6A6 +D -1.25 0 0 -0.75" },
        },
    },
    -- Menus. Radius 12.
    menu = {
        light = {
            blur = 20, saturate = 0.8, flat = "#E6E6E6B3",
            fills = { "E6E6E68C luminosity" },
            inner = { "0D0D0D +L 0 -4 8 -4", "0D0D0D +L 0 4 8 -4", "262626 +L 0 -0.5 0 0", "262626 +L 0 0.5 0 0", "66666626 +L 0 0 0 1" },
            drops = { "0000004C 0 4 24 0", "00000033 0 0 0 0.5" },
        },
        dark = {
            blur = 20, saturate = 1.2, flat = "#3C3C3C99",
            fills = { "5A5A5A80 luminosity" },
            inner = { "0D0D0D +L 0 -4 8 -4", "0D0D0D +L 0 4 8 -4", "262626 +L 0 -0.5 0 0", "262626 +L 0 0.5 0 0", "66666666 +L 0 0 0 1" },
            drops = { "0000004C 0 4 24 0", "000000CC 0 0 0 0.5" },
        },
    },
    -- Notification banners. Radius 20.
    notification = {
        light = {
            blur = 15, saturate = 1, flat = "#EDEDEDB3",
            fills = { "BFBFBF40 lighten", "1A1A1A +L" },
            inner = { "222222 +L 0 -6 4 -6", "222222 +L 0 6 4 -6", "676767 +L 0 -1 1.5 -1", "676767 +L 0 1 1.5 -1", "FFFFFF33 0 2 0.2 -1.2" },
            drops = { "0000001A 0 4 16 0", "ABABAB +D 0 0 0.3 0.3" },
        },
        dark = {
            blur = 10, saturate = 1, flat = "#2E2E2E99",
            fills = { "6666661A lighten" },
            inner = { "222222 +L 0 -6 4 -6", "222222 +L 0 6 4 -6", "676767 +L 0 -1 1.5 -1", "676767 +L 0 1 1.5 -1", "FFFFFF33 0 2 0.2 -1.2" },
            drops = { "0000001A 0 4 16 0", "ABABAB +D 0 0 0.3 0.3" },
        },
    },
    -- The sidebar pane: edge to edge, no radius. Its blur reads the desktop behind the window
    -- (`behind`), which the compositor draws; the kit's radius and saturation are its own.
    sidebar = {
        behind = true,
        light = { flat = "#FAFAFACC", fills = { "FAFAFACC" } },
        dark = { flat = "#0C0C0CD9", fills = { "0C0C0CD9" } },
    },
    sidebar_inactive = {
        behind = true,
        light = { flat = "#F4F4F4", fills = { "F4F4F4" } },
        dark = { flat = "#2E2E2ED9", fills = { "2E2E2ED9" } },
    },
    -- Tooltips. Square corners.
    tooltip = {
        light = { blur = 45, saturate = 1.8, flat = "#E7E7E7D9", fills = { "E7E7E7D9" }, drops = { "00000066 0 0 2 0", "00000033 0 2 8 0" } },
        dark = { blur = 45, saturate = 2, flat = "#262626CC", fills = { "262626CC" }, drops = { "FFFFFF26 0 0 0 0.6", "00000066 0 0 2 0", "00000033 0 2 8 0" } },
    },
}

-- The standard materials: one fill over a radius-60 backdrop blur.
for name, spec in pairs({
    ultra_thick = { "ECECECE0", 2, "2C2C2CD1", 1.9 },
    thick = { "ECECECC2", 2, "2C2C2CB5", 1.9 },
    regular = { "ECECECA1", 1.45, "2C2C2C9C", 1.9 },
    thin = { "ECECEC80", 1.45, "2929297D", 1.9 },
    ultra_thin = { "ECECEC61", 1.45, "29292966", 1.8 },
}) do
    M.STYLES[name] = {
        light = { blur = 60, saturate = spec[2], flat = color(spec[1]), fills = { spec[1] } },
        dark = { blur = 60, saturate = spec[4], flat = color(spec[3]), fills = { spec[3] } },
    }
end

local function reversed(list, convert, ...)
    local out = {}
    for i = #list, 1, -1 do
        out[#out + 1] = convert(list[i], ...)
    end
    return out
end

-- The props one appearance of `style` resolves to; `tint` replaces TINT.
local function resolve(style, dark, tint)
    local s = M.STYLES[style][dark and "dark" or "light"]
    local function sub(str) return (str:gsub("TINT", (tint or "#0088FF"):sub(2, 7))) end
    local fills, drops, inner = {}, {}, {}
    for i, f in ipairs(s.fills or {}) do fills[i] = sub(f) end
    for i, d in ipairs(s.drops or {}) do drops[i] = sub(d) end
    for i, d in ipairs(s.inner or {}) do inner[i] = sub(d) end
    local out = {}
    -- Engine lists are first on top; the kit lists bottom to top.
    -- The kit's stacks depend on their blend modes (black in `screen`, the tint in plus-darker),
    -- so they draw only with both layers and blend; until then the tuned flat colour stands in.
    if M.HAS.layers and M.HAS.blend then
        out.background = reversed(fills, fill)
    else
        out.background = s.flat == "TINT" and (tint or "#0088FF") or s.flat
    end
    -- A blended layer composited normally draws the wrong colour, so without blend it is left out.
    local shadows = {}
    local function add(layer)
        if M.HAS.blend or not layer.blend then
            shadows[#shadows + 1] = layer
        end
    end
    if M.HAS.inset then
        for _, layer in ipairs(reversed(inner, shadow, true)) do add(layer) end
    end
    for _, layer in ipairs(reversed(drops, shadow)) do add(layer) end
    out.shadows = shadows
    if s.blur and M.HAS.effect then
        out.effect = { backdrop = { blur = s.blur, saturate = s.saturate } }
    end
    return out
end

-- Spreads glass `style` onto `props`, live across light and dark. `opts.tint` (colour or signal)
-- colours `small_tinted`. Extra `opts.shadows` (a signal of a list, e.g. a focus ring) go on top.
function M.glass(style, props, opts)
    opts = opts or {}
    local tint = opts.tint
    local tint_signal = type(tint) == "userdata" and tint or theme.dark:map(function() return tint end)
    local look = computed({ theme.dark, tint_signal, opts.shadows or theme.dark:map(function() return {} end) },
        function(dark, t, extra)
            local r = resolve(style, dark, t)
            for i, layer in ipairs(extra or {}) do
                table.insert(r.shadows, i, layer)
            end
            return r
        end)
    props.background = look:map(function(r) return r.background end)
    props.shadows = look:map(function(r) return r.shadows end)
    if M.STYLES[style].light.blur and M.HAS.effect then
        props.effect = look:map(function(r) return r.effect end)
    end
    if M.STYLES[style].behind then
        props.behind_blur = true
    end
    props.corner_smoothing = theme.SMOOTHING
    return props
end

-- Vibrant foreground: `blend` that lets a `vibrant_*` colour take the glass's tone.
function M.vibrant(props)
    if M.HAS.blend then
        props.blend = theme.vibrancy
    end
    return props
end

return M
