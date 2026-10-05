-- Liquid Glass tokens from Apple's UI kit: colours, vibrancy, type, control sizes, shapes and
-- motion. `c.<role>` is a live signal of one role that follows `dark`.
local M = {}

M.dark = state("glass_dark", true)

M.accent = state("glass_accent", "blue")

-- System colours: { light, dark, light vibrant (plus-darker), dark vibrant (plus-lighter) }.
M.SYSTEM = {
    red = { "#FF383C", "#FF4245", "#F52F32", "#FF4747" },
    orange = { "#FF8D28", "#FF9230", "#F58625", "#FF9E33" },
    yellow = { "#FFCC00", "#FFD600", "#F5C200", "#FFE014" },
    green = { "#34C759", "#30D158", "#26BF4D", "#3BDB63" },
    mint = { "#00C8B3", "#00DAC3", "#00BDA9", "#2DE0CD" },
    teal = { "#00C3D0", "#00D2E0", "#00B3BF", "#2DD7E0" },
    cyan = { "#00C0E8", "#3CD3FE", "#00ABCF", "#47D8FC" },
    blue = { "#0088FF", "#0091FF", "#0078F0", "#0A99FF" },
    indigo = { "#6155F5", "#6D7CFF", "#5C50E6", "#7163FF" },
    purple = { "#CB30E0", "#DB34F2", "#B72BC9", "#E647FC" },
    pink = { "#FF2D55", "#FF375F", "#F5234B", "#FF4169" },
    brown = { "#AC7F5E", "#B78A66", "#9E7354", "#C29672" },
    gray = { "#8E8E93", "#98989D", "#848489", "#A2A2A7" },
}
M.ACCENTS = { "blue", "purple", "pink", "red", "orange", "yellow", "green", "gray" }

-- Roles: { light, dark }. `vibrant_*` roles are opaque greys drawn with `M.vibrancy` (plus-darker
-- on light, plus-lighter on dark), so they take the colour of the glass under them.
local ROLES = {
    label = { "#000000D9", "#FFFFFF" },
    secondary_label = { "#00000080", "#FFFFFF8C" },
    tertiary_label = { "#00000040", "#FFFFFF40" },
    quaternary_label = { "#0000001A", "#FFFFFF1A" },
    quinary_label = { "#0000000D", "#FFFFFF0D" },
    vibrant_label = { "#363636", "#FFFFFFF5" },
    vibrant_secondary_label = { "#737373", "#8A8A8A" },
    vibrant_tertiary_label = { "#B2B2B2", "#4C4C4C" },
    vibrant_quaternary_label = { "#D9D9D9", "#262626" },
    fill = { "#0000001A", "#FFFFFF1A" },
    secondary_fill = { "#00000014", "#FFFFFF14" },
    tertiary_fill = { "#0000000D", "#FFFFFF0D" },
    quaternary_fill = { "#00000008", "#FFFFFF08" },
    quinary_fill = { "#00000005", "#FFFFFF05" },
    vibrant_fill = { "#00000026", "#FFFFFF24" },
    vibrant_secondary_fill = { "#00000012", "#FFFFFF14" },
    vibrant_tertiary_fill = { "#0000000D", "#FFFFFF0D" },
    separator = { "#3C3C434A", "#FFFFFF1A" },
    chrome_border = { "#3C3C431F", "#3C3C431F" },
    window_background = { "#FFFFFF", "#1E1E1E" },
    window_border = { "#00000000", "#FFFFFF33" },
    input_background = { "#FFFFFF", "#1E1E1E" },
    input_border = { "#0000000D", "#FFFFFF0A" },
    scroll_knob = { "#00000080", "#FFFFFF8C" },
    on_accent = { "#FFFFFF", "#FFFFFF" },
    knob = { "#FFFFFF", "#DEDEDE" },
    menu_highlight = { "#0069F9", "#0069F9" },
    modal_dim = { "#ABABAB99", "#1717179E" },
    traffic_close = { "#FF5C60", "#FF5C60" },
    traffic_minimize = { "#FAC800", "#FAC800" },
    traffic_zoom = { "#35C759", "#35C759" },
    traffic_inactive = { "#00000026", "#FFFFFF2B" },
}

-- Every role and system colour for one appearance; the accent's own row gives `accent`.
local function palette(dark, accent)
    local p = {}
    for role, pair in pairs(ROLES) do
        p[role] = pair[dark and 2 or 1]
    end
    for name, set in pairs(M.SYSTEM) do
        p[name] = set[dark and 2 or 1]
        p["vibrant_" .. name] = set[dark and 4 or 3]
    end
    local a = M.SYSTEM[accent] or M.SYSTEM.blue
    p.accent = a[dark and 2 or 1]
    p.vibrant_accent = a[dark and 4 or 3]
    return p
end

M.scheme = computed({ M.dark, M.accent }, function(dark, accent) return palette(dark ~= false, accent) end)

M.c = setmetatable({}, {
    __index = function(roles, role)
        local signal = M.scheme:map(function(p) return p[role] end)
        rawset(roles, role, signal)
        return signal
    end,
})

-- The blend that makes `vibrant_*` colours vibrant on the current appearance.
M.vibrancy = M.dark:map(function(d) return d and "plus_lighter" or "plus_darker" end)

-- A role chosen by a boolean signal: `pick(on, "accent", "secondary_fill")`.
function M.pick(flag, yes, no)
    return computed({ flag, M.scheme }, function(on, p) return p[on and yes or no] or yes end)
end

-- `color` at `alpha` (0..1).
function M.alpha(color, alpha)
    return color:sub(1, 7) .. string.format("%02X", math.floor(alpha * 255 + 0.5))
end

M.CLEAR = "#00000000"

-- native text styles: { size, weight, line height, tracking }. SF Pro's tracking per size, applied
-- to Inter, which stands in for SF Pro.
M.FONT = "Inter"
M.type = {
    large_title = { 26, 400, 32, 0.22 },
    title1 = { 22, 400, 26, -0.26 },
    title2 = { 17, 400, 22, -0.43 },
    title3 = { 15, 400, 20, -0.23 },
    headline = { 13, 700, 16, -0.08 },
    body = { 13, 400, 16, -0.08 },
    callout = { 12, 400, 15, 0 },
    subheadline = { 11, 400, 14, 0.06 },
    footnote = { 10, 400, 13, 0.12 },
    caption1 = { 10, 400, 13, 0.12 },
    caption2 = { 10, 500, 13, 0.12 },
    -- Control labels and window titles, from the kit.
    control = { 13, 500, 16, -0.08 },
    control_small = { 11, 500, 13, 0.06 },
    control_mini = { 10, 500, 13, 0.12 },
    window_title = { 13, 700, 15, 0 },
    sidebar_title = { 15, 700, 15, -0.2 },
}

-- Control sizes, shared by every button-like control: height, corner radius (`CAPSULE` is a pill),
-- label style and horizontal label inset.
M.CAPSULE = 999
M.SMOOTHING = 0.6
M.SIZES = {
    mini = { height = 16, radius = 4, label = "control_mini", inset = 7, icon = 10 },
    small = { height = 20, radius = 5, label = "control_small", inset = 10, icon = 11 },
    regular = { height = 24, radius = 6, label = "control", inset = 16, icon = 13 },
    large = { height = 28, radius = M.CAPSULE, label = "control", inset = 16, icon = 13 },
    xl = { height = 36, radius = M.CAPSULE, label = "control", inset = 16, icon = 13 },
}

M.WINDOW_RADIUS = 16
M.CONTENT_INSET = 12

-- SwiftUI's springs as engine springs: response r seconds and damping fraction z give
-- stiffness (2 pi / r)^2 and damping 4 pi z / r.
local function spring(response, fraction)
    return { spring = { stiffness = (2 * math.pi / response) ^ 2, damping = 4 * math.pi * fraction / response } }
end
M.motion = {
    default = spring(0.55, 1),
    smooth = spring(0.5, 1),
    snappy = spring(0.5, 0.85),
    bouncy = spring(0.5, 0.7),
    press = spring(0.3, 0.65),
    fade = { duration = 200, easing = "out_quad" },
}

return M
