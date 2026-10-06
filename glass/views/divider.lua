-- Liquid Glass divider: a 1 px hairline in the kit's separator colour.
local theme = require("glass.theme")
local core = require("glass.core")

local M = {}

---@class glass.DividerOpts
---@field vertical? boolean Default horizontal.
---@field inset? number Pixels trimmed from both ends; default 0.
---@field props? table Extra node props.
---@field [string] "no such property"

---@param id? string|glass.DividerOpts
---@param opts? glass.DividerOpts
---@return Node
function M.divider(id, opts)
    if type(id) == "table" then
        id, opts = nil, id
    end
    opts = opts or {}
    local inset = opts.inset or 0
    return rect(core.merge({
        id = id,
        width = opts.vertical and 1 or "fill",
        height = opts.vertical and "fill" or 1,
        margin = opts.vertical and { top = inset, bottom = inset } or { left = inset, right = inset },
        background = theme.c.separator,
        hittable = false,
    }, opts.props))
end

return M
