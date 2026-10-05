-- Segmented control: a rounded track of segments, each an icon, a label or both. The selected
-- segment is filled blue; unselected neighbours are split by a hairline.
local theme = require("glass.theme")
local core = require("glass.core")
local tg = require("glass.internal.toggles")

local c, FADE = theme.c, theme.motion.fade

-- Per size: icon-only segment width and height, radius, label inset, separator height, glyph size.
local SIZES = {
    mini = { w = 23, h = 16, radius = 4, pad = 6, sep = 10, glyph = 10 },
    small = { w = 26, h = 20, radius = 5, pad = 8, sep = 12, glyph = 11 },
    regular = { w = 30, h = 24, radius = 6, pad = 10, sep = 14, glyph = 13 },
    -- not in the kit: label inset of Lg and XL (it gives only Mn, Sm and Rg)
    large = { w = 34, h = 28, radius = theme.CAPSULE, pad = 10, sep = 18, glyph = 13 },
    xl = { w = 38, h = 36, radius = theme.CAPSULE, pad = 10, sep = 20, glyph = 13 },
}

local M = {}

-- opts: items (list of { icon, label, value }; a segment's key is value, else label, else icon),
-- value (state: the selected key, or with `multiple` a set { [key] = true }), multiple, size,
-- disabled, on_glass, on_change(value).
function M.segmented_control(id, opts)
    local s = SIZES[opts.size or "regular"]
    local n = tg.role(opts)
    local items, multiple = opts.items, opts.multiple
    local function key(it) return it.value or it.label or it.icon end
    local value = opts.value or state("glass_seg_" .. id, not multiple and key(items[1]) or {})
    local disabled = tg.sig(opts.disabled)
    local ons, kids = {}, {}
    for i, it in ipairs(items) do
        local k = key(it)
        ons[i] = value:map(function(v)
            if multiple then
                return (v or {})[k] == true
            end
            return v == k
        end)
    end
    for i, it in ipairs(items) do
        local on = ons[i]
        local props = {
            accessible_name = it.label or it.icon,
            width = "fill",
            min_width = s.w,
            height = s.h,
            radius = s.radius,
            padding = it.label and { left = s.pad, right = s.pad } or nil,
        }
        local held, focused = tg.interact("seg_" .. id .. i, props, opts, function()
            if multiple then
                local set = core.merge({}, value:get())
                set[key(it)] = not set[key(it)] or nil
                value:set(set)
            else
                value:set(key(it))
            end
            if opts.on_change then
                opts.on_change(value:get())
            end
        end)
        local glyph = computed({ on, disabled, theme.scheme }, function(selected, d, p)
            return selected and p.on_accent or p[d and n("tertiary_label") or "vibrant_label"]
        end)
        props.shadows = tg.ring(focused)
        props.background = computed({ on, held, theme.scheme }, function(selected, h, p)
            return selected and p[n("accent")] or h and theme.alpha(p.label, 0.16) or theme.CLEAR
        end)
        props.opacity = computed({ on, disabled }, function(selected, d) return d and selected and 0.45 or 1 end)
        props.animate = { background = FADE, opacity = FADE }
        local content = {}
        if it.icon then
            content[#content + 1] = core.icon(it.icon, glyph, s.glyph)
        end
        if it.label then
            content[#content + 1] = core.text(it.label, glyph, theme.SIZES[opts.size or "regular"].label)
        end
        props.children = {
            tg.pressed_tint(s.radius, held, on),
            row { align_h = "center", align_v = "center", spacing = 4, children = content },
        }
        -- Each segment carries the hairline on its leading seam, so the row's slots stay equal.
        local cell = { rect(core.shape(props)) }
        if i > 1 then
            cell[2] = rect(core.shape {
                width = 1,
                height = s.sep,
                radius = 0.5,
                align_v = "center",
                translate = { x = -0.5 },
                hittable = false,
                background = c.vibrant_quaternary_label,
                opacity = computed({ ons[i - 1], on }, function(a, b) return (a or b) and 0 or 1 end),
                animate = { opacity = FADE },
            })
        end
        kids[#kids + 1] = rect { height = s.h, children = cell }
    end
    return row(core.shape {
        homogeneous = true,
        radius = s.radius,
        background = opts.on_glass and c.vibrant_fill or c.secondary_fill,
        children = kids,
    })
end

return M
