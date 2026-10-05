-- Liquid Glass color well: a capsule with a colour swatch inset 3 px, from the kit.
local theme = require("glass.theme")
local core = require("glass.core")
local buttons = require("glass.internal.buttons")

local M = {}

local SWATCH_INSET = 3

-- Color well.
---@class glass.ColorWellOpts
---@field size? glass.Size
---@field value? StateSignal<string> "#RRGGBB"; default system green.
---@field selected? boolean|Signal<boolean> The well is the active one, e.g. its picker is open.
---@field disabled? boolean|Signal<boolean>
---@field window? string
---@field on_click? fun() Open the picker.
---@field name? string
---@field props? table
---@field [string] "no such property"

---@param id string
---@param opts? glass.ColorWellOpts
---@return Node
function M.color_well(id, opts)
    opts = opts or {}
    local height = theme.SIZES[opts.size or "regular"].height
    local value = opts.value or state("glass_well_" .. id, theme.SYSTEM.green[1])
    return buttons.control(id, {
        size = opts.size,
        kind = "well",
        disabled = opts.disabled,
        window = opts.window,
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
