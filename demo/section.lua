-- Demo page scaffolding: a page is a column of sections; a section is a title, a line of
-- description and a content node, on the window background with the kit's 12 px content inset.
local glass = require("glass")

local c = glass.theme.c
local material = glass.material

local M = {}

-- A wallpaper for glass to sit on: glass only shows over content.
M.WALL = "/mnt/Work/1Wallpapers/Main/evening_reflections.jpg"

function M.page(sections)
    return column { width = "fill", padding = { left = 24, right = 24, top = 12, bottom = 32 }, spacing = 32, children = sections }
end

function M.section(title, description, content)
    return column {
        width = "fill",
        spacing = 12,
        children = {
            column {
                spacing = 2,
                children = {
                    glass.text(title, c.label, "title3"),
                    glass.text(description, c.secondary_label, "body"),
                },
            },
            content,
        },
    }
end

-- A captioned cell: `node` above a small grey caption.
function M.labelled(caption, node)
    return column { spacing = 6, children = { node, glass.text(caption, c.tertiary_label, "caption1") } }
end

-- `children` over the wallpaper, for controls that sit on glass.
function M.on_wall(children, height)
    return rect(glass.shape {
        width = "fill",
        height = height or 160,
        radius = 12,
        clip = "rounded",
        children = {
            image { source = M.WALL, width = "fill", height = "fill", fit = "cover" },
            row { padding = 20, spacing = 16, children = children },
        },
    })
end

-- A pane of large glass holding `children` in a column, for controls that sit on glass.
function M.glass_pane(children)
    return column(material.glass("large", { radius = 20, padding = 16, spacing = 16, children = children }))
end

return M
