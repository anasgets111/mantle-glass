-- Liquid Glass text view: several lines of text in the kit's input box, as an NSTextView in a bordered
-- scroll view. It grows from `min_lines` to `max_lines`, then scrolls inside.
local fields = require("glass.internal.fields")

local M = {}

-- not in the kit: the kit has no multiline field; the text field's box with this vertical inset.
local PAD_V = 5

---@class glass.TextViewOpts
---@field size? glass.Size
---@field width? number|"fill" Default "fill".
---@field value? StateSignal<string>
---@field placeholder? string
---@field min_lines? integer Default 3.
---@field max_lines? integer Default 0, no limit; past it the text scrolls.
---@field submit_key? "ctrl+return"|"return" Default "ctrl+return": Return breaks the line. "return" submits on Return and breaks on Shift+Return, as a chat box.
---@field disabled? boolean|Signal<boolean>
---@field max_length? integer
---@field on_change? fun(text: string)
---@field on_submit? fun(text: string)
---@field window? string
---@field name? string Accessible name.
---@field props? table Extra box props.
---@field [string] "no such property"

---@param id string
---@param opts? glass.TextViewOpts
---@return Node, glass.FieldHandle
function M.text_view(id, opts)
    opts = opts or {}
    local inset = fields.SIZES[opts.size or "regular"].inset
    local input, handle = fields.input(id, {
        size = opts.size,
        value = opts.value,
        placeholder = opts.placeholder,
        disabled = opts.disabled,
        max_length = opts.max_length,
        on_change = opts.on_change,
        on_submit = opts.on_submit,
        window = opts.window,
        name = opts.name,
        multiline = true,
        min_lines = opts.min_lines or 3,
        max_lines = opts.max_lines or 0,
        submit_key = opts.submit_key,
    })
    return fields.box(id, {
        size = opts.size,
        width = opts.width or "fill",
        grow = true,
        padding = { left = inset, right = inset, top = PAD_V, bottom = PAD_V },
        disabled = opts.disabled,
        focus = handle.focus,
        props = opts.props,
    }, { input }), handle
end

return M
