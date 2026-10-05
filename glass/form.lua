-- Grouped form: an inset rounded section of rows split by separators, and the row with its
-- leading icon, label, subtitle and trailing control. Metrics: docs/spec/sidebars.md "Forms".
local theme = require("glass.theme")
local core = require("glass.core")

local c = theme.c

local SECTION = { radius = 12, side = 10 }
local ROW = { plain = 40, control = 48, subtitle = 56, gap = 10, icon = 24, icon_radius = 5.4, glyph = 13 }
-- not in the kit: header and footer text beside the section.
local CAPTION = { gap = 6, inset = 10 }

local M = {}

-- opts: label, subtitle, icon (Lucide name; a grey 24 px service icon), trailing (a node, right
-- aligned), control (true when the trailing node is a 24 px control: 48 high, else 40; a
-- subtitle makes it 56), on_click.
function M.form_row(id, opts)
    opts = opts or {}
    local kids = {}
    if opts.icon then
        kids[1] = rect(core.shape {
            align_v = "center",
            width = ROW.icon,
            height = ROW.icon,
            radius = ROW.icon_radius,
            -- not in the kit's palette: the gradient #BFBFBF to #919191 becomes system gray.
            background = c.gray,
            children = { core.icon(opts.icon, c.on_accent, ROW.glyph, { align_h = "center" }) },
        })
    end
    local text = { core.text(opts.label, c.label, "control") }
    if opts.subtitle then
        text[2] = core.text(opts.subtitle, c.secondary_label, "subheadline")
    end
    kids[#kids + 1] = column { width = "fill", align_v = "center", spacing = 2, children = text }
    kids[#kids + 1] = opts.trailing and rect { align_v = "center", children = { opts.trailing } } or nil
    local tall = opts.subtitle and ROW.subtitle or (opts.icon or opts.control) and ROW.control or ROW.plain
    local props = {
        width = "fill",
        height = tall,
        align_v = "center",
        spacing = ROW.gap,
        accessible_name = opts.on_click and opts.label or nil,
        on_click = opts.on_click,
        children = kids,
    }
    if opts.on_click then
        core.focusable("fr_" .. id, props)
    end
    return row(props)
end

-- opts: header, footer (strings or signals), rows (nodes, usually form_row).
function M.form_section(_, opts)
    opts = opts or {}
    local kids = {}
    for i, node in ipairs(opts.rows) do
        kids[#kids + 1] = node
        if i < #opts.rows then
            kids[#kids + 1] = rect { width = "fill", height = 1, background = c.tertiary_fill }
        end
    end
    local out = {}
    local function caption(content)
        return row {
            width = "fill",
            padding = { left = CAPTION.inset, right = CAPTION.inset },
            children = { core.text(content, c.secondary_label, "subheadline", { width = "fill", wrap = "word" }) },
        }
    end
    if opts.header then
        out[#out + 1] = caption(opts.header)
    end
    out[#out + 1] = column(core.shape {
        width = "fill",
        radius = SECTION.radius,
        clip = "rounded",
        padding = { left = SECTION.side, right = SECTION.side },
        background = c.quaternary_fill,
        children = kids,
    })
    if opts.footer then
        out[#out + 1] = caption(opts.footer)
    end
    return column { width = "fill", spacing = CAPTION.gap, children = out }
end

return M
