-- Liquid Glass tooltip, from docs/spec/overlays.md: square glass chip under the pointer after a hover
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
}

-- Wraps `opts.child` so resting the pointer on it shows `opts.label` just under the pointer.
-- ponytail: the tip is not kept inside the window; one near the right or bottom edge is clipped.
function M.tooltip(id, opts)
    local anchor_name = "glass_tip_" .. id
    local over = hover("glass_tip_" .. id)
    local at_pointer = pointer("glass_tip_" .. id)
    local function build(at)
        local p = at_pointer:get() or { x = 0, y = 0 }
        return column(material.glass("tooltip", {
            margin = at:map(function(r) return { left = r.x + p.x, top = r.y + p.y + TOOLTIP.below } end),
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
                        overlay.show_tip(id, anchor_name, build)
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
