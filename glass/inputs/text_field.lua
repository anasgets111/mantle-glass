-- Liquid Glass text field, from the kit; `multiline` makes it a text view: an NSTextView in a bordered
-- scroll view, growing from `min_lines` to `max_lines`, then scrolling inside.
local core = require("glass.core")
local fields = require("glass.internal.fields")

local M = {}

-- not in the kit: the kit has no multiline field; the text field's box with this vertical inset.
local PAD_V = 5

-- Text field. Returns the node and a handle; wrap the call in parentheses to keep the node.
---@class glass.FieldHandle
---@field value StateSignal<string>
---@field focus fun()
---@field clear fun()
---@field set fun(text: string)

---@class glass.TextFieldOpts
---@field size? glass.Size
---@field width? number|"fill" Default 120, "fill" when `multiline`.
---@field value? StateSignal<string>
---@field label? string|Signal<string> Text above the field.
---@field placeholder? string
---@field disabled? boolean|Signal<boolean>
---@field max_length? integer
---@field multiline? boolean Several lines in a box that grows.
---@field min_lines? integer `multiline` only; default 3.
---@field max_lines? integer `multiline` only; default 0, no limit; past it the text scrolls.
---@field submit_key? "ctrl+return"|"return" `multiline` only; default "ctrl+return": Return breaks the line. "return" submits on Return and breaks on Shift+Return, as a chat box.
---@field window? string
---@field on_change? fun(text: string)
---@field on_submit? fun(text: string)
---@field name? string Accessible name; default the label.
---@field props? table Extra box props.
---@field [string] "no such property"

---@param id string
---@param opts? glass.TextFieldOpts
---@return Node, glass.FieldHandle
function M.text_field(id, opts)
    opts = opts or {}
    local multiline = opts.multiline
    local inset = fields.SIZES[opts.size or "m"].inset
    local input, handle = fields.input(id, multiline and core.merge({ min_lines = 3, max_lines = 0 }, opts) or opts)
    return fields.box(id, {
        size = opts.size,
        width = opts.width or (multiline and "fill" or 120),
        grow = multiline,
        padding = { left = inset, right = inset, top = multiline and PAD_V or nil, bottom = multiline and PAD_V or nil },
        disabled = opts.disabled,
        focus = handle.focus,
        label = opts.label,
        props = opts.props,
    }, { input }), handle
end

return M
