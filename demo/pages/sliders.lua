-- Sliders and progress: linear and circular sliders, bars, rings and spinners.
local section = require("demo.section")
local glass = require("glass")

local c = glass.theme.c
local on_wall = section.on_wall

-- Every cell is as tall as the biggest control, so controls of any size share a centre line and
-- caption row. A slider's track starts 10 px in, so its caption does too (`indent`).
local CELL = 36
local function labelled(caption, node, indent)
    return column { spacing = 6, children = {
        rect { height = CELL, children = { row { align_v = "center", children = { node } } } },
        glass.text(caption, c.tertiary_label, "caption1", { margin = { left = indent } }),
    } }
end

local function slider(caption, id, opts)
    return labelled(caption, glass.slider(id, opts), 10)
end

local SIZES = { "mini", "small", "regular", "large", "xl" }

local function line(children) return row { spacing = 16, align_v = "center", children = children } end
local function top(children) return row { spacing = 16, align_v = "start", children = children } end

local function each(list, make)
    local out = {}
    for i, v in ipairs(list) do out[i] = make(v) end
    return out
end

local function readout(signal, fmt)
    return glass.text(signal:map(function(v) return string.format(fmt or "%.2f", v) end), c.secondary_label, "body", { width = 48 })
end

local std = state("demo_sliders_std", 0.4)
local ticks = state("demo_sliders_ticks", 3)
local snap = state("demo_sliders_snap", 50)
local center = state("demo_sliders_center", -0.5)
local dial = state("demo_sliders_dial", 0.35)
local bar = state("demo_sliders_bar", 0.6)

local size_sliders = each(SIZES, function(size)
    return slider(size, "sl_" .. size, { size = size, value = state("demo_sliders_" .. size, 0.5) })
end)

local dials = each({ "small", "regular", "large" }, function(size)
    return labelled(size, glass.circular_slider("dial_" .. size, { size = size, value = state("demo_sliders_dial_" .. size, 0.5) }))
end)

local bars = each({ "small", "regular" }, function(size)
    return labelled(size, glass.progress_bar("bar_" .. size, { size = size, value = bar }))
end)

return section.page {
    section.section("Sliders", "Drag the knob: it grows into glass while held.", column { spacing = 16, children = {
        top({ slider("standard", "std", { value = std, width = 240 }), labelled("value", readout(std)) }),
        top({ slider("5 ticks", "ticks", { value = ticks, min = 1, max = 5, step = 1, ticks = 5, snap = true, width = 240 }), labelled("value", readout(ticks, "%d")) }),
        top({ slider("ticks, 0 to 100", "snap", { value = snap, min = 0, max = 100, step = 10, ticks = 11, snap = true, width = 240 }), labelled("value", readout(snap, "%d")) }),
        top({ slider("center-biased", "center", { value = center, min = -1, max = 1, neutral = 0, width = 240 }), labelled("value", readout(center)) }),
        line({ slider("disabled", "sl_off", { value = state("demo_sliders_off", 0.5), disabled = true, width = 240 }) }),
    } }),
    section.section("Slider sizes", "Mini to extra large.", top(size_sliders)),
    section.section("Circular slider", "Drag around the dial.", top({
        labelled("regular", glass.circular_slider("dial", { value = dial })),
        labelled("value", readout(dial)),
        table.unpack(dials),
    })),
    section.section("Progress bars", "Determinate follows the slider; indeterminate loops.", column { spacing = 16, children = {
        row { spacing = 16, align_v = "center", margin = { left = -10 }, children = { glass.slider("bar_ctl", { value = bar, width = 160 }), readout(bar) } },
        top(bars),
        top({
            labelled("indeterminate", glass.progress_bar("bar_ind", { indeterminate = true })),
            labelled("indeterminate, small", glass.progress_bar("bar_ind_s", { indeterminate = true, size = "small" })),
        }),
    } }),
    section.section("Rings and spinners", "Circular progress, determinate and not.", top({
        labelled("ring", glass.progress_ring("ring", { value = bar })),
        labelled("ring, small", glass.progress_ring("ring_s", { size = "small", value = bar })),
        labelled("spinner", glass.spinner("spin", {})),
        labelled("spinner, small", glass.spinner("spin_s", { size = "small" })),
    })),
    section.section("Over glass", "Controls on a wallpaper (on_glass).", on_wall({
        section.glass_pane({
            glass.slider("wall_slider", { value = state("demo_sliders_wall", 0.5), width = 240, on_glass = true }),
            glass.slider("wall_ticks", { value = state("demo_sliders_wall_t", 3), min = 1, max = 5, step = 1, ticks = 5, snap = true, width = 240, on_glass = true }),
            glass.progress_bar("wall_bar", { value = bar, on_glass = true }),
            glass.progress_bar("wall_ind", { indeterminate = true, on_glass = true }),
        }),
        section.glass_pane({
            row { spacing = 16, align_v = "center", children = {
                glass.circular_slider("wall_dial", { value = state("demo_sliders_wall_d", 0.5), on_glass = true }),
                glass.progress_ring("wall_ring", { value = bar, on_glass = true }),
                glass.spinner("wall_spin", {}),
            } },
        }),
    }, 260)),
}
