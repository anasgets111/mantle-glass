-- Toggles: checkboxes, radios, switches, segmented controls and steppers.
local section = require("demo.section")
local glass = require("glass")

local c = glass.theme.c
local on_wall = section.on_wall

-- Every cell is as tall as the biggest control, so controls of any size share a centre line and caption row.
local CELL = 36
local function labelled(caption, node, height)
    return section.labelled(caption, rect { height = height or CELL, children = { row { align_v = not height and "center" or nil, children = { node } } } })
end

local SIZES = { "mini", "small", "regular", "large", "xl" }

local function line(children) return row { spacing = 16, align_v = "center", children = children } end
local function top(children) return row { spacing = 16, align_v = "start", children = children } end

local function each(list, make)
    local out = {}
    for i, v in ipairs(list) do out[i] = make(v) end
    return out
end

local function live(signal)
    return glass.text(signal:map(function(v) return tostring(v) end), c.secondary_label, "body")
end

local function checks(prefix, on_glass)
    local function box(name, value, label, extra)
        return glass.checkbox(prefix .. name, glass.merge({ value = value, label = label, on_glass = on_glass }, extra))
    end
    return {
        box("on", state("demo_toggles_" .. prefix .. "on", true), "Checked"),
        box("off", state("demo_toggles_" .. prefix .. "off", false), "Unchecked"),
        box("mixed", state("demo_toggles_" .. prefix .. "mixed", "mixed"), "Mixed"),
        box("dis", state("demo_toggles_" .. prefix .. "dis", true), "Disabled", { disabled = true }),
    }
end

local check_sizes = each(SIZES, function(size)
    return labelled(size, glass.checkbox("cs_" .. size, { size = size, label = "Option", value = state("demo_toggles_cs_" .. size, true) }))
end)

local radio = state("demo_toggles_radio", "Small")
local radio_h = state("demo_toggles_radio_h", "B")

local switch_sizes = each(SIZES, function(size)
    return labelled(size, glass.switch("sw_" .. size, { size = size, value = state("demo_toggles_sw_" .. size, true), label = size }))
end)
switch_sizes[#switch_sizes + 1] = labelled("off", glass.switch("sw_off", { value = state("demo_toggles_sw_off", false), label = "off" }))
switch_sizes[#switch_sizes + 1] = labelled("disabled", glass.switch("sw_dis", { value = state("demo_toggles_sw_dis", true), disabled = true, label = "disabled" }))

local seg_label = state("demo_toggles_seg_label", "Day")
local seg_icon = state("demo_toggles_seg_icon", "list")
local seg_both = state("demo_toggles_seg_both", "Inbox")
local seg_multi = state("demo_toggles_seg_multi", { bold = true })
local seg_sizes = each({ "small", "regular", "large" }, function(size)
    return labelled(size, glass.segmented_control("seg_" .. size, { size = size, value = state("demo_toggles_seg_" .. size, "Day"), items = { { label = "Day" }, { label = "Week" }, { label = "Month" } } }))
end)

local step = state("demo_toggles_step", 5)
local step_sizes = each({ "small", "regular", "large" }, function(size)
    return labelled(size, glass.stepper("step_" .. size, { size = size, value = state("demo_toggles_step_" .. size, 3), min = 0, max = 10 }))
end)

return section.page {
    section.section("Checkboxes", "On, off, mixed (a click turns mixed on) and disabled.", top(checks("c_"))),
    section.section("Checkbox sizes", "Mini to extra large.", top(check_sizes)),
    section.section("Radio groups", "One choice from a few, vertical or horizontal.", top({
        labelled("vertical", glass.radio_group("radio", { options = { "Small", "Medium", "Large" }, value = radio }), 72),
        labelled("horizontal", glass.radio_group("radio_h", { options = { "A", "B", "C" }, value = radio_h, horizontal = true }), 72),
        labelled("disabled", glass.radio_group("radio_off", { options = { "One", "Two" }, value = state("demo_toggles_radio_off", "One"), disabled = true }), 72),
        labelled("selected", glass.text(radio, c.label, "body"), 72),
    })),
    section.section("Switches", "Every size; press to see the glass knob.", top(switch_sizes)),
    section.section("Segmented controls", "Labels, icons or both; one choice or several.", column { spacing = 16, children = {
        top({
            labelled("labels", glass.segmented_control("seg_label", { value = seg_label, items = { { label = "Day" }, { label = "Week" }, { label = "Month" } } })),
            labelled("value", live(seg_label)),
            labelled("icons", glass.segmented_control("seg_icon", { value = seg_icon, items = { { icon = "list", value = "list" }, { icon = "layout-grid", value = "grid" }, { icon = "columns-3", value = "columns" } } })),
            labelled("value", live(seg_icon)),
            labelled("icon and label", glass.segmented_control("seg_both", { value = seg_both, items = { { icon = "inbox", label = "Inbox" }, { icon = "send", label = "Sent" }, { icon = "archive", label = "Archive" } } })),
        }),
        top({
            labelled("multiple", glass.segmented_control("seg_multi", { multiple = true, value = seg_multi, items = { { icon = "bold", value = "bold" }, { icon = "italic", value = "italic" }, { icon = "underline", value = "underline" } } })),
            labelled("set", live(seg_multi:map(function(set)
                local keys = {}
                for k in pairs(set) do keys[#keys + 1] = k end
                table.sort(keys)
                return #keys > 0 and table.concat(keys, ", ") or "none"
            end))),
            labelled("disabled", glass.segmented_control("seg_off", { disabled = true, value = state("demo_toggles_seg_off", "Day"), items = { { label = "Day" }, { label = "Week" } } })),
        }),
        top(seg_sizes),
    } }),
    section.section("Steppers", "Two stacked buttons; a button dims at its limit (0 to 10).", top({
        labelled("stepper", glass.stepper("step", { value = step, min = 0, max = 10 })),
        labelled("value", live(step)),
        top(step_sizes),
        labelled("disabled", glass.stepper("step_off", { value = state("demo_toggles_step_off", 3), disabled = true })),
    })),
    section.section("Over glass", "The same controls on a wallpaper (on_glass).", on_wall({ section.glass_pane({
        line({
            glass.checkbox("wall_check", { label = "Checkbox", value = state("demo_toggles_wall_check", true), on_glass = true }),
            glass.radio_group("wall_radio", { options = { "One", "Two" }, value = state("demo_toggles_wall_radio", "One"), horizontal = true, on_glass = true }),
            glass.switch("wall_switch", { value = state("demo_toggles_wall_switch", true), on_glass = true, label = "Switch" }),
        }),
        line({
            glass.segmented_control("wall_seg", { value = state("demo_toggles_wall_seg", "Day"), items = { { label = "Day" }, { label = "Week" }, { label = "Month" } }, on_glass = true }),
            glass.stepper("wall_step", { value = state("demo_toggles_wall_step", 2), on_glass = true }),
        }),
    }) }, 220)),
}
