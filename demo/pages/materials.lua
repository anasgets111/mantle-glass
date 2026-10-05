-- Materials: every glass style and standard material over the wallpaper, with the kit's backdrop numbers.
local section = require("demo.section")
local glass = require("glass")

local c, material = glass.theme.c, glass.material

local TILES = {
    { "small", radius = 999 }, { "small_tinted", radius = 999 }, { "large", radius = 20 }, { "menu", radius = 12 },
    { "notification", radius = 20 }, { "tooltip", radius = 0 }, { "knob", radius = 999 },
    { "ultra_thick", radius = 12 }, { "thick", radius = 12 }, { "regular", radius = 12 },
    { "thin", radius = 12 }, { "ultra_thin", radius = 12 },
}

local function tile(spec)
    local name = spec[1]
    local s = material.STYLES[name].dark
    local light = material.STYLES[name].light
    local numbers = s.blur and string.format("blur %s, saturate %s / %s", s.blur, light.saturate, s.saturate) or "behind the window"
    local props = { width = 200, height = 84, radius = spec.radius, padding = 12, spacing = 2, align_v = "center", align_h = "center" }
    props.children = {
        glass.text(name, c.label, "headline", { align_h = "center" }),
        glass.text(numbers, c.secondary_label, "subheadline", { align_h = "center" }),
    }
    return column(material.glass(name, props, { tint = name == "small_tinted" and glass.theme.c.accent or nil }))
end

local tiles = {}
for i, spec in ipairs(TILES) do tiles[i] = tile(spec) end

local wall = rect(glass.shape {
    width = "fill",
    radius = 12,
    clip = "rounded",
    children = {
        image { source = section.WALL, width = "fill", height = "fill", fit = "cover" },
        row { width = "fill", padding = 20, spacing = 16, line_spacing = 16, wrap = true, children = tiles },
    },
})

return section.page {
    section.section("Styles", "Each style over the wallpaper, with its backdrop blur radius and saturation (light / dark) from the kit.", wall),
}
