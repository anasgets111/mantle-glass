-- Liquid Glass text field, from the kit.
local fields = require("glass.internal.fields")

local M = {}

-- Text field. Returns the node and a handle; wrap the call in parentheses to keep the node.
---@class glass.FieldHandle
---@field value StateSignal<string>
---@field focus fun()

---@class glass.TextFieldOpts
---@field size? glass.Size
---@field width? number Default 120.
---@field value? StateSignal<string>
---@field placeholder? string
---@field disabled? boolean|Signal<boolean>
---@field max_length? integer
---@field on_change? fun(text: string)
---@field on_submit? fun(text: string)
---@field name? string Accessible name.
---@field props? table Extra box props.
---@field [string] "no such property"

---@param id string
---@param opts? glass.TextFieldOpts
---@return Node, glass.FieldHandle
function M.text_field(id, opts)
    opts = opts or {}
    local inset = fields.SIZES[opts.size or "regular"].inset
    local input, handle = fields.input(id, opts)
    return fields.box(id, {
        size = opts.size,
        width = opts.width or 120,
        padding = { left = inset, right = inset },
        disabled = opts.disabled,
        focus = handle.focus,
        props = opts.props,
    }, { input }), handle
end

return M
