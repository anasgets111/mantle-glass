-- Liquid Glass combo box: a text field with an inset menu button, from docs/spec/buttons.md.
local theme = require("glass.theme")
local core = require("glass.core")
local menu = require("glass.overlays.menu")
local buttons = require("glass.internal.buttons")
local fields = require("glass.internal.fields")

local icon = core.icon

local M = {}

-- The menu button's background width, radius and chevron size, and its inset in the field, per size.
local BUTTON = {
    mini = { 16, 2.5, 9, 2 },
    small = { 20, 3.5, 10, 2 },
    regular = { 24, 4.5, 10, 2 },
    large = { 24, 5.5, 12.5, 2 },
    xl = { 30, 6.5, 13, 3 },
}

-- Combo box. Picking an item puts it in the field.
---@class glass.ComboBoxOpts: glass.TextFieldOpts
---@field items? string[]
---@field window? string
---@field [string] "no such property"

---@param id string
---@param opts? glass.ComboBoxOpts
---@return Node, glass.FieldHandle
function M.combo_box(id, opts)
    opts = opts or {}
    local size = opts.size or "regular"
    local b = BUTTON[size]
    local anchor = geometry("glass_anchor_" .. id)
    local input, handle = fields.input(id, opts)
    local menu = buttons.control(id .. "_menu", {
        size = size,
        kind = "plain",
        disabled = opts.disabled,
        window = opts.window,
        name = "Menu",
        on_click = function()
            local now, shown = handle.value:get(), {}
            for i, label in ipairs(opts.items or {}) do
                shown[i] = { label = label, checked = label == now }
            end
            menu.open_menu({
                anchor = anchor,
                items = shown,
                width = "anchor",
                window = opts.window,
                on_pick = function(item)
                    handle.value:set(item.label)
                    if opts.on_change then
                        opts.on_change(item.label)
                    end
                end,
            })
        end,
        props = {
            width = b[1],
            height = theme.SIZES[size].height - 2 * b[4],
            radius = b[2],
            margin = b[4],
            align_h = "center",
            align_v = "center",
        },
    }, function(color)
        return { icon("chevron-down", color, b[3], { align_v = "center" }) }
    end)
    return fields.box(id, {
        size = size,
        width = opts.width or 120,
        padding = { left = fields.SIZES[size].inset },
        disabled = opts.disabled,
        focus = handle.focus,
        geometry = anchor,
        props = opts.props,
    }, { input, menu }), handle
end

return M
