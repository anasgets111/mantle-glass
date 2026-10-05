-- Pickers and indicators: date pickers, token field, path control, level indicators, vertical
-- sliders and the image well.
local section = require("demo.section")
local glass = require("glass")

local c = glass.theme.c

local function column_of(children) return column { width = 496, spacing = 32, children = children } end
local function labelled(caption, node) return section.labelled(caption, node) end
local function line(children) return row { spacing = 16, align_v = "center", children = children } end

local function readout(signal, fmt)
    return glass.text(signal:map(function(v) return fmt(v or {}) end), c.secondary_label, "body")
end
local function date_text(v) return string.format("%04d-%02d-%02d", v.year or 0, v.month or 0, v.day or 0) end
local function time_text(v) return date_text(v) .. string.format(" %02d:%02d", v.hour or 0, v.minute or 0) end

local d1 = state("demo_pick_date", { year = 2026, month = 10, day = 5 })
local d2 = state("demo_pick_time", { year = 2026, month = 10, day = 5, hour = 14, minute = 30 })
local d3 = state("demo_pick_cal", { year = 2026, month = 10, day = 5 })
local d4 = state("demo_pick_pop", { year = 2026, month = 12, day = 24 })
local tokens = state("demo_pick_tokens", { "Design", "Lua" })
local picked = state("demo_pick_path", "")
local rating = state("demo_pick_rating", 3)
local level = state("demo_pick_level", 0.55)

local PATH = {
    { label = "Disk", icon = "hard-drive" },
    { label = "Users", icon = "folder" },
    { label = "anas", icon = "house" },
    { label = "Documents", icon = "folder" },
    { label = "Report.pdf", icon = "file" },
}

local function vslider(id, opts)
    opts.height, opts.vertical = 140, true
    return labelled(id, glass.slider("v_" .. id, opts))
end

local dates = column_of({
    section.section("Date pickers", "Click a part, then use Up and Down or the stepper.", column { spacing = 16, children = {
        line({ glass.date_picker("dp_text", { value = d1 }), readout(d1, date_text) }),
        line({ glass.date_picker("dp_time", { value = d2, time = true }), readout(d2, time_text) }),
        line({ glass.date_picker("dp_pop", { value = d4, style = "popover" }), readout(d4, date_text) }),
        line({ glass.date_picker("dp_small", { value = d1, size = "small" }), glass.date_picker("dp_off", { value = d1, disabled = true }) }),
    } }),
    section.section("Calendar", "Arrow keys move the day, Page Up and Down the month.", line({
        glass.calendar("cal", { value = d3 }),
        readout(d3, date_text),
    })),
})

local tokens_col = column_of({
    section.section("Token field", "Return or a comma makes a token; Backspace removes the last. Try \"sw\".", column { spacing = 12, children = {
        glass.token_field("tok", { value = tokens, width = 320, placeholder = "Add a tag", suggestions = { "Swift", "Swing", "Switch", "Design", "Lua", "Rust" } }),
        glass.text(tokens:map(function(t) return table.concat(t or {}, ", ") end), c.secondary_label, "body"),
        glass.token_field("tok_small", { size = "small", width = 320, value = state("demo_pick_tokens_s", { "One", "Two" }) }),
    } }),
    section.section("Path control", "A click on a segment selects it.", column { spacing = 12, children = {
        glass.path_control("path", { segments = PATH, on_select = function(i) picked:set(PATH[i].label) end }),
        glass.path_control("path_pop", { segments = PATH, style = "popup", on_select = function(i) picked:set(PATH[i].label) end }),
        glass.text(picked:map(function(p) return "selected: " .. (p or "") end), c.secondary_label, "body"),
    } }),
    section.section("Image well", "Click to pick an image.", line({
        glass.image_well("well", { source = section.WALL, size = 64, on_click = function() log.info("image well clicked") end }),
        glass.image_well("well_empty", { size = 64 }),
    })),
})

local levels = column_of({
    section.section("Level indicators", "Yellow from 0.6, red from 0.85.", column { spacing = 14, children = {
        glass.slider("level_ctl", { value = level, width = 240 }),
        labelled("continuous", glass.level_indicator("lvl_c", { value = level, warning = 0.6, critical = 0.85, width = 240 })),
        labelled("discrete", glass.level_indicator("lvl_d", { value = level, warning = 0.6, critical = 0.85, style = "discrete", width = 240 })),
        labelled("small", glass.level_indicator("lvl_s", { value = level, warning = 0.6, critical = 0.85, size = "small", width = 240 })),
        labelled("rating, editable", glass.level_indicator("lvl_r", { value = rating, style = "rating", editable = true })),
        labelled("rating, read only", glass.level_indicator("lvl_ro", { value = 4, style = "rating", size = "small" })),
    } }),
    section.section("Vertical sliders", "The same slider, upright.", row { spacing = 24, align_v = "start", children = {
        vslider("standard", { value = state("demo_pick_v1", 0.4) }),
        vslider("ticks", { value = state("demo_pick_v2", 3), min = 1, max = 5, step = 1, ticks = 5, snap = true }),
        vslider("centred", { value = state("demo_pick_v3", 0.3), min = -1, max = 1, neutral = 0 }),
        vslider("small", { value = state("demo_pick_v4", 0.6), size = "small" }),
        vslider("off", { value = state("demo_pick_v5", 0.5), disabled = true }),
    } }),
})

return section.page({ row { wrap = true, spacing = 32, line_spacing = 32, children = { dates, tokens_col, levels } } })
