-- Sidebar: the content of the window's glass pane, from docs/spec/sidebars.md. Rows select on
-- click, folders open in place, and a long sidebar scrolls.
local theme = require("glass.theme")
local core = require("glass.core")
local material = require("glass.material")
local window = require("glass.window")
local reveal = require("glass.internal.sidebar").reveal

local c, FADE = theme.c, theme.motion.fade

-- Per size: row and header height, header font, title font, icon box and glyph, disclosure
-- column, trailing detail font. Fonts are { size, weight, line height }.
local SIZES = {
    small = { row = 24, header = 18, hfont = { 11, 700, 14 }, tfont = { 11, 500, 14 }, icon = 16, glyph = 11, disc = 12, dfont = { 11, 500, 14 } },
    medium = { row = 32, header = 18, hfont = { 11, 700, 14 }, tfont = { 13, 400, 16 }, icon = 20, glyph = 13, disc = 16, dfont = { 13, 500, 16 } },
    large = { row = 40, header = 20, hfont = { 13, 700, 16 }, tfont = { 15, 400, 20 }, icon = 24, glyph = 15, disc = 16, dfont = { 15, 500, 20 } },
}
local FOLDER_WEIGHT = 500
local PANE = { inset = 4, pad = 10, gap = 4, indent = 12, radius = 8, selected = 0.055 }
-- not in the kit: the gap between sections and the scroll's bottom room.
local SECTION_GAP, BOTTOM = 12, 8

local M = {}

local function label(content, color, font, extra)
    return core.text(content, color, "body", material.vibrant(core.merge({
        font_size = font[1],
        font_weight = font[2],
        line_height = font[3] / font[1],
        letter_spacing = 0,
    }, extra)))
end

-- opts: sections ({ { header?, items = { { name, label, icon?, count?, children? } } } }),
-- value (state of the selected item name; default the first item), size ("small", "medium"
-- default, "large"), on_select(name). A child list nests items to any depth.
function M.sidebar(id, opts)
    local s = SIZES[opts.size or "medium"]
    local first = opts.sections[1].items[1].name
    ---@type StateSignal<string>
    local value = opts.value or state("glass_sidebar_" .. id, first)
    local active = window.active
    local title_color = theme.pick(active, "vibrant_label", "vibrant_tertiary_label")
    local icon_color = theme.pick(active, "vibrant_accent", "vibrant_secondary_label")
    -- not in the kit: without the plus-lighter/darker blend a tertiary vibrant grey vanishes on the pane.
    local faint = c.vibrant_tertiary_label

    local build
    local function item_row(item, level, folders, open)
        local kids = {}
        if folders then
            local chevron = item.children and core.icon(
                open:map(function(o) return o and "chevron-down" or "chevron-right" end),
                faint, 11, material.vibrant({ margin = { left = PANE.indent * level }, align_v = "center" })) or nil
            local toggle = {
                width = s.disc + PANE.indent * level,
                height = "fill",
                accessible_name = item.children and "Toggle " .. item.label or nil,
                on_click = item.children and function() open:set(not open:get()) end or nil,
                children = { chevron },
            }
            if item.children then
                core.focusable("sb_" .. id .. "_" .. item.name .. "_toggle", toggle)
            end
            kids[1] = rect(toggle)
        end
        if item.icon then
            kids[#kids + 1] = rect {
                width = s.icon,
                height = "fill",
                children = { core.icon(item.icon, icon_color, s.glyph, material.vibrant({ align_h = "center" })) },
            }
        end
        kids[#kids + 1] = label(item.label, title_color, s.tfont, {
            width = "fill",
            elide = "end",
            font_weight = item.children and FOLDER_WEIGHT or s.tfont[2],
        })
        if item.count then
            kids[#kids + 1] = label(item.count, c.vibrant_secondary_label, s.dfont)
        end
        local props = {
            width = "fill",
            height = s.row,
            radius = PANE.radius,
            align_v = "center",
            spacing = PANE.gap,
            padding = { left = PANE.pad, right = PANE.pad },
            accessible_name = item.label,
            background = computed({ value, theme.scheme }, function(v, p)
                return v == item.name and theme.alpha(p.label, PANE.selected) or theme.CLEAR
            end),
            animate = { background = FADE },
            on_click = function()
                value:set(item.name)
                if opts.on_select then
                    opts.on_select(item.name)
                end
            end,
            children = kids,
        }
        core.focusable("sb_" .. id .. "_" .. item.name, props)
        return row(core.shape(props))
    end

    function build(item, level, folders)
        local open = item.children and state("glass_sidebar_" .. id .. "_open_" .. item.name, false) or nil
        local row_node = item_row(item, level, folders, open)
        if not item.children then
            return row_node
        end
        local nested = {}
        for i, child in ipairs(item.children) do
            nested[i] = build(child, level + 1, folders)
        end
        return column {
            width = "fill",
            children = { row_node, reveal(open, column { width = "fill", children = nested }) },
        }
    end

    local blocks = {}
    for _, section in ipairs(opts.sections) do
        local folders = false
        for _, item in ipairs(section.items) do
            folders = folders or item.children ~= nil
        end
        local nodes = {}
        if section.header then
            nodes[1] = row {
                width = "fill",
                height = s.header,
                align_v = "center",
                padding = { left = PANE.pad },
                children = { label(section.header, faint, s.hfont) },
            }
        end
        for _, item in ipairs(section.items) do
            nodes[#nodes + 1] = build(item, 0, folders)
        end
        blocks[#blocks + 1] = column { width = "fill", children = nodes }
    end
    return column {
        width = "fill",
        height = "fill",
        scroll = scroll("glass_sidebar_" .. id),
        padding = { left = PANE.inset, right = PANE.inset, bottom = BOTTOM },
        spacing = SECTION_GAP,
        children = blocks,
    }
end

return M
