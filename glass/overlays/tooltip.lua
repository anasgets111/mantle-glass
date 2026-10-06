-- Liquid Glass tooltip, from the kit: square glass chip under the pointer after a hover
-- delay, drawn in the overlay so no ancestor clips it.
local theme = require("glass.theme")
local core = require("glass.core")
local material = require("glass.material")
local overlay = require("glass.overlay")

local c = theme.c

local M = {}

local TOOLTIP = {
    pad = { left = 6, right = 6, top = 3, bottom = 3 },
    delay = 750, -- not in the kit: native tooltips show after about this long
    below = 18, -- not in the kit: the arrow cursor's height, so the tip clears it
    edge = 4, -- not in the kit: the least room left between the tip and the window's edge
}

local box = geometry("glass_tip_box")

-- Wraps `opts.child` so resting the pointer on it shows `opts.label` just under the pointer, or
-- above it and slid left where the window or panel would cut it.
---@class glass.TooltipOpts
---@field child Node
---@field label string|Signal<string>
---@field window? string
---@field [string] "no such property"

---@param id string
---@param opts glass.TooltipOpts
---@return Node
function M.tooltip(id, opts)
    local anchor_name = "glass_tip_" .. id
    local over = hover("glass_tip_" .. id)
    local at_pointer = pointer("glass_tip_" .. id)
    local function build(at, bounds)
        local p = at_pointer:get() or { x = 0, y = 0 }
        return column(material.glass("tooltip", {
            geometry = box,
            margin = computed({ at, bounds, box }, function(r, b, t)
                local x, y = r.x + p.x, r.y + p.y
                local w, h = t and t.width or 0, t and t.height or 0
                local left, top = x, y + TOOLTIP.below
                if b and left + w > b.x + b.width - TOOLTIP.edge then
                    left = math.max(b.x + TOOLTIP.edge, b.x + b.width - TOOLTIP.edge - w)
                end
                if b and top + h > b.y + b.height - TOOLTIP.edge then
                    top = y - h - TOOLTIP.edge
                end
                return { left = left, top = top }
            end),
            padding = TOOLTIP.pad,
            opacity = 1,
            animate = { opacity = { duration = 120, from = 0 }, exit = { duration = 80, opacity = 0 } },
            children = { core.text(opts.label, c.vibrant_label, "control_small", material.vibrant({})) },
        }))
    end
    return rect {
        hover = over,
        pointer = at_pointer,
        geometry = geometry(anchor_name),
        on_hover = function(inside)
            if inside then
                timer(TOOLTIP.delay, function()
                    if over:get() then
                        overlay.show_tip(id, anchor_name, build, opts.window)
                    end
                end)
            else
                overlay.hide_tip(id)
            end
        end,
        children = { opts.child },
    }
end

return M
