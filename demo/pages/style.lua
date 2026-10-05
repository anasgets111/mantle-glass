-- Colour & type: system colours, label/fill/separator roles, accent choices, the type scale and
-- the control sizes, all read from glass.theme.
local section = require("demo.section")
local glass = require("glass")

local theme = glass.theme
local c = theme.c

local SYSTEM = { "red", "orange", "yellow", "green", "mint", "teal", "cyan", "blue", "indigo", "purple", "pink", "brown", "gray" }
local TYPES = { "large_title", "title1", "title2", "title3", "headline", "body", "callout", "subheadline", "footnote",
    "caption1", "caption2", "control", "control_small", "control_mini", "window_title", "sidebar_title" }
local SIZES = { "mini", "small", "regular", "large", "xl" }

local function swatch(role, name)
    return column { spacing = 4, width = 56, children = {
        rect(glass.shape { width = 56, height = 36, radius = 8, background = c[role] }),
        glass.text(name, c.secondary_label, "caption1"),
    } }
end

local function colours(prefix)
    local cells = {}
    for i, name in ipairs(SYSTEM) do cells[i] = swatch(prefix .. name, name) end
    return row { width = "fill", wrap = true, spacing = 12, line_spacing = 12, children = cells }
end

local system = column { spacing = 12, children = {
    glass.text("Normal", c.label, "headline"), colours(""),
    glass.text("Vibrant (the tone drawn on glass)", c.label, "headline"), colours("vibrant_"),
} }

local ROLES = {
    { "Labels", { "label", "secondary_label", "tertiary_label", "quaternary_label" } },
    { "Fills", { "fill", "secondary_fill", "tertiary_fill", "quaternary_fill" } },
    { "Separators and borders", { "separator", "input_border", "chrome_border", "scroll_knob" } },
}

local function role_cell(role)
    local is_label = role:find("label")
    return column { spacing = 4, width = 120, children = {
        rect(glass.shape { width = 120, height = 44, radius = 8, background = is_label and c.fill or c[role], children = {
            is_label and glass.text("Aa", c[role], "title1", { align_h = "center" }) or nil,
        } }),
        glass.text(role, c.secondary_label, "caption1"),
    } }
end

local roles = {}
for i, group in ipairs(ROLES) do
    local cells = {}
    for j, role in ipairs(group[2]) do cells[j] = role_cell(role) end
    roles[i] = column { spacing = 6, children = { glass.text(group[1], c.label, "headline"), row { width = "fill", wrap = true, spacing = 12, line_spacing = 12, children = cells } } }
end
roles[#roles + 1] = rect { width = "fill", height = 1, background = c.separator }

local function accent_dot(name)
    local picked = theme.accent_name:map(function(a) return a == name end)
    return rect(glass.shape {
        width = 24,
        height = 24,
        radius = theme.CAPSULE,
        accessible_name = name,
        background = theme.scheme:map(function(p) return p[name] or c.gray:get() end),
        on_click = function() theme.accent:set(name) end,
        children = { glass.icon("check", c.on_accent, 13, { align_h = "center", opacity = picked:map(function(v) return v and 1 or 0 end) }) },
    })
end
local accents = {}
for i, name in ipairs(theme.ACCENTS) do accents[i] = accent_dot(name) end
local accent = column { spacing = 8, children = {
    row { spacing = 12, children = accents },
    glass.text(theme.accent, c.secondary_label, "body"),
} }

local function type_row(style)
    local t = theme.type[style]
    return row { spacing = 16, height = t[3] + 12, align_v = "center", children = {
        glass.text(style, c.secondary_label, "caption1", { width = 100 }),
        glass.text(string.format("%d / %d  w%d  %+.2f", t[1], t[3], t[2], t[4]), c.secondary_label, "caption1", { width = 130 }),
        glass.text("The quick brown fox", c.label, style),
    } }
end
local scale = {}
for i, style in ipairs(TYPES) do scale[i] = type_row(style) end

local function size_row(name)
    local s = theme.SIZES[name]
    local radius = s.radius == theme.CAPSULE and "capsule" or tostring(s.radius)
    return row { spacing = 16, height = 40, align_v = "center", children = {
        glass.text(name, c.label, "control", { width = 60 }),
        glass.text(string.format("h %d  r %s  %s  inset %d  icon %d", s.height, radius, s.label, s.inset, s.icon), c.secondary_label, "body", { width = 300 }),
        glass.button("size_" .. name, { size = name, kind = "default", label = "Button", icon = "plus", props = { align_v = "center" } }),
        glass.button("size_icon_" .. name, { size = name, icon = "plus", props = { align_v = "center" } }),
    } }
end
local sizes = {}
for i, name in ipairs(SIZES) do sizes[i] = size_row(name) end

return section.page {
    section.section("System colours", "Light and dark follow the appearance; vibrant tones are what labels take on glass.", system),
    section.section("Roles", "Label, fill and separator roles.", column { spacing = 14, children = roles }),
    section.section("Accent", "Click one to set the accent; selected controls and the sidebar follow.", accent),
    section.section("Type scale", "Size / line height, weight and tracking per style.", column { spacing = 2, children = scale }),
    section.section("Control sizes", "theme.SIZES: every button-like control follows one table.", column { children = sizes }),
}
