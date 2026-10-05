-- Liquid Glass notification banner, from docs/spec/overlays.md: top-right of the window under the toolbar, slides in,
-- dismisses itself after a few seconds or on a click. One at a time; a new one replaces it.
local theme = require("glass.theme")
local core = require("glass.core")
local material = require("glass.material")
local overlay = require("glass.overlay")

local c = theme.c
local text, icon = core.text, core.icon

local M = {}

local BANNER = {
    width = 344,
    height = 78,
    radius = 20,
    padding = { left = 14, right = 12, top = 12, bottom = 12 },
    icon = 32,
    icon_radius = 8, -- not in the kit: the app icon is an image
    gap = 12,
    margin = 12, -- not in the kit: banner to window edge
    top = 52 + 12, -- not in the kit: below the unified toolbar, which the banner would cover
    seconds = 5, -- not in the kit
}

local serial = 0

overlay.layer("glass_notify", function(data)
    return rect {
        id = "glass_notify",
        width = "fill",
        height = "fill",
        hittable = false,
        animate = { exit = { duration = 200, easing = "in_quad", opacity = 0, translate = { x = BANNER.width + BANNER.margin } } },
        children = { row(material.glass("notification", {
            width = BANNER.width,
            min_height = BANNER.height,
            radius = BANNER.radius,
            padding = BANNER.padding,
            spacing = BANNER.gap,
            align_h = "end",
            align_v = "start",
            margin = { top = BANNER.top, right = BANNER.margin },
            hittable = true,
            opacity = 1,
            translate = { x = 0, y = 0 },
            -- not in the kit: slides in from the right edge
            animate = {
                opacity = { duration = 150, from = 0 },
                translate = { spring = theme.motion.snappy.spring, from = { x = BANNER.width + BANNER.margin, y = 0 } },
            },
            accessible_name = data.title,
            on_click = function() overlay.close("glass_notify") end,
            children = {
                rect(core.shape {
                    width = BANNER.icon,
                    height = BANNER.icon,
                    radius = BANNER.icon_radius,
                    align_v = "center",
                    background = c.accent,
                    children = { icon(data.icon or "bell", c.on_accent, 13, { align_h = "center", align_v = "center" }) },
                }),
                column {
                    width = "fill",
                    align_v = "center",
                    children = {
                        text(data.title, c.vibrant_label, "headline", material.vibrant({ width = "fill" })),
                        text(data.body, c.vibrant_label, "body", material.vibrant({ width = "fill", wrap = "word", max_lines = 2 })),
                    },
                },
                text(data.app or "now", c.vibrant_secondary_label, "subheadline", material.vibrant({ align_v = "start" })),
            },
        })) },
    }
end)

-- Banner at the window's top right; dismisses after a few seconds or on click.
---@class glass.NotificationOpts
---@field title? string
---@field body? string
---@field icon? string Lucide name; default "bell".
---@field app? string The caption at the right; default "now".
---@field window? string The window or panel it opens over; default `core.window`.
---@field [string] "no such property"

---@param opts glass.NotificationOpts
function M.open_notification(opts)
    serial = serial + 1
    local mine = serial
    overlay.open("glass_notify", opts, opts.window)
    timer(BANNER.seconds * 1000, function()
        if mine == serial then
            overlay.close("glass_notify")
        end
    end)
end

return M
