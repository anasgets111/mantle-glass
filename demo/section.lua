-- Demo page scaffolding: a page is a column of sections; a section is a title, a line of
-- description and a content node, on the window background with the kit's 12 px content inset.
local glass = require("glass")

local c = glass.theme.c
local material = glass.material

local M = {}

-- A wallpaper for glass to sit on: glass only shows over content.
M.WALL = "/mnt/Work/1Wallpapers/Main/evening_reflections.jpg"

-- Sections are cards of one width that wrap side by side; a wide one takes a row of its own.
local CARD = 780
local wide = setmetatable({}, { __mode = "k" })

function M.page(sections)
    local blocks, run = {}, nil
    for _, s in ipairs(sections) do
        if wide[s] then
            blocks[#blocks + 1], run = s, nil
        else
            if not run then
                run = row { width = "fill", wrap = true, spacing = 32, line_spacing = 32, children = {} }
                blocks[#blocks + 1] = run
            end
            run.children[#run.children + 1] = s
        end
    end
    return column { width = "fill", padding = { left = 24, right = 24, top = 12, bottom = 32 }, spacing = 32, children = blocks }
end

-- opts.wide: the full width, for content wider than a card.
function M.section(title, description, content, opts)
    local node = column {
        width = opts and opts.wide and "fill" or CARD,
        spacing = 12,
        children = {
            column {
                spacing = 2,
                children = {
                    glass.text(title, c.label, "title3"),
                    glass.text(description, c.secondary_label, "body", { wrap = "word", width = "fill" }),
                },
            },
            content,
        },
    }
    if opts and opts.wide then
        wide[node] = true
    end
    return node
end

-- A section on a row of its own.
function M.wide(title, description, content)
    return M.section(title, description, content, { wide = true })
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
