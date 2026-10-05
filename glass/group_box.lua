-- Group box: a quaternary-filled rounded box around related content, with an optional title.
local theme = require("glass.theme")
local core = require("glass.core")

local c = theme.c

-- not in the kit: the kit gives the box only (radius 12, fill), no title or padding.
local BOX = { radius = 12, padding = 12, title_gap = 6 }

local M = {}

-- Group box.
---@class glass.GroupBoxOpts
---@field title? string|Signal<string>
---@field content? Node
---@field [string] "no such property"

---@param _ any Unused.
---@param opts? glass.GroupBoxOpts
---@return Node
function M.group_box(_, opts)
    opts = opts or {}
    local box = rect(core.shape {
        width = "fill",
        radius = BOX.radius,
        padding = BOX.padding,
        background = c.quaternary_fill,
        children = { opts.content },
    })
    if not opts.title then
        return box
    end
    return column {
        width = "fill",
        spacing = BOX.title_gap,
        children = { core.text(opts.title, c.label, "headline"), box },
    }
end

return M
