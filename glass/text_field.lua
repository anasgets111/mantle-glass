-- Liquid Glass text field, from docs/spec/overlays.md.
local theme = require("glass.theme")
local fields = require("glass.internal.fields")

local M = {}

-- Text field. opts: size ("mini".."xl"), width (default 120), value (state of the text), placeholder,
-- disabled, max_length, on_change(text), on_submit(text), name (accessible name), props (extra box
-- props). Returns the node and { value, focus() }; wrap the call in parentheses to keep the node.
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
