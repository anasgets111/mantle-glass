-- Liquid Glass color well: a capsule with a colour swatch inset 3 px, from docs/spec/buttons.md.
local theme = require("glass.theme")
local core = require("glass.core")
local buttons = require("glass.internal.buttons")

local M = {}

local SWATCH_INSET = 3

-- Color well. opts: value (state of the colour, "#RRGGBB"; default green), size, selected (the
-- well is the active one, e.g. its picker is open), disabled, on_click (open the picker), name,
-- props.
function M.color_well(id, opts)
    opts = opts or {}
    local height = theme.SIZES[opts.size or "regular"].height
    local value = opts.value or state("glass_well_" .. id, theme.SYSTEM.green[1])
    return buttons.control(id, {
        size = opts.size,
        kind = "well",
        disabled = opts.disabled,
        on = opts.selected,
        width = 2 * height,
        padding = SWATCH_INSET,
        radius = theme.CAPSULE,
        name = opts.name or "Color",
        on_click = opts.on_click,
        props = opts.props,
    }, function(_, disabled)
        return { rect(core.shape {
            width = 2 * height - 2 * SWATCH_INSET,
            height = height - 2 * SWATCH_INSET,
            radius = theme.CAPSULE,
            background = value,
            border_width = 1,
            border_color = theme.alpha(theme.CLEAR, 0.1),
            opacity = disabled:map(function(off) return off and 0.503 or 1 end),
        }) }
    end)
end

return M
