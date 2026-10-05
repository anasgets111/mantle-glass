-- Liquid Glass tooltip, from docs/spec/overlays.md: square glass chip under its anchor after a hover
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
    gap = 4, -- not in the kit: anchor to tip
    span = 480, -- the box the tip centres in, wider than any label
}

-- Wraps `opts.child` so resting the pointer on it shows `opts.label`.
function M.tooltip(id, opts)
    local anchor_name = "glass_tip_" .. id
    local over = hover("glass_tip_" .. id)
    local function build(at)
        return rect {
            width = TOOLTIP.span,
            margin = at:map(function(r) return { left = r.x + r.width / 2 - TOOLTIP.span / 2, top = r.y + r.height + TOOLTIP.gap } end),
            children = { column(material.glass("tooltip", {
                align_h = "center",
                padding = TOOLTIP.pad,
                opacity = 1,
                animate = { opacity = { duration = 120, from = 0 }, exit = { duration = 80, opacity = 0 } },
                children = { core.text(opts.label, c.vibrant_label, "control_small", material.vibrant({})) },
            })) },
        }
    end
    return rect {
        hover = over,
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
