-- Liquid Glass image well, from the kit: a quinary-filled square in three spread rings,
-- the image inset 2 px.
local theme = require("glass.theme")
local core = require("glass.core")

local M = {}

local WELL = { size = 28, radius = 2, inset = 2 }
local RINGS = {
    { color = "#0000000D", spread = 0.5 },
    { color = "#0000000D", spread = 1.5 },
    { color = "#FFFFFFFF", spread = 1 },
}

---@class glass.ImageWellOpts
---@field source? string|Signal<string> Image path; empty shows the bare well.
---@field size? number Default 28, the kit's; the image keeps the 2 px inset.
---@field fit? "contain"|"cover" Default "contain".
---@field on_click? fun() Usually opens a picker.
---@field label? string Accessible name.
---@field [string] "no such property"

---@param id string
---@param opts? glass.ImageWellOpts
---@return Node
function M.image_well(id, opts)
    opts = opts or {}
    local size = opts.size or WELL.size
    local props = {
        width = size,
        height = size,
        radius = WELL.radius,
        padding = WELL.inset,
        background = theme.c.quinary_fill,
        accessible_name = opts.label or id,
        on_click = opts.on_click,
        children = opts.source and { image {
            source = opts.source,
            width = "fill",
            height = "fill",
            fit = opts.fit or "contain",
        } } or {},
    }
    if opts.on_click then
        core.focusable("image_well_" .. id, props)
        props.shadows = computed({ props.shadows, theme.scheme }, function(focus, _)
            local out = { table.unpack(RINGS) }
            for _, layer in ipairs(focus) do
                out[#out + 1] = layer
            end
            return out
        end)
    else
        props.shadows = RINGS
    end
    return rect(core.shape(props))
end

return M
