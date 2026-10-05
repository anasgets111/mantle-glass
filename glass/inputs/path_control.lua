-- Path control after NSPathControl: a breadcrumb of segments split by chevrons, or a pop-up that
-- shows the last segment and lists the path in a menu.
local theme = require("glass.theme")
local core = require("glass.core")
local menu = require("glass.overlays.menu")
local buttons = require("glass.internal.buttons")

local c = theme.c

-- not in the kit: the chevron between segments, as an SF point size
local CHEVRON = 10

local M = {}

---@class glass.PathSegment
---@field label string
---@field icon? string Lucide name.
---@field [string] "no such property"

-- Path control. `segments` may be a signal of a list; the control follows it.
---@class glass.PathControlOpts
---@field segments glass.PathSegment[]|Signal<glass.PathSegment[]> Root first.
---@field style? "standard"|"popup" Default "standard".
---@field size? glass.Size
---@field on_select? fun(index: integer) The segment clicked or picked, 1 the root.
---@field disabled? boolean|Signal<boolean>
---@field on_glass? boolean
---@field window? string
---@field [string] "no such property"

---@param id string
---@param opts glass.PathControlOpts
---@return Node
function M.path_control(id, opts)
    local size = opts.size or "regular"
    local g = theme.SIZES[size]
    local segments = buttons.signal(opts.segments)
    local function select(i)
        if opts.on_select then
            opts.on_select(i)
        end
    end
    local function content(seg, color)
        local kids = {}
        if seg.icon then
            kids[1] = core.icon(seg.icon, color, g.icon)
        end
        kids[#kids + 1] = core.text(seg.label, color, g.label)
        return kids
    end

    if opts.style == "popup" then
        local anchor = geometry("glass_anchor_" .. id)
        local last = segments:map(function(list) return { list[#list] or { label = "" } } end)
        return buttons.control(id, {
            size = size,
            kind = "plain",
            on_glass = opts.on_glass,
            disabled = opts.disabled,
            window = opts.window,
            padding = { left = g.inset - 4 },
            name = id,
            props = { geometry = anchor, spacing = 4 },
            on_click = function()
                local list, items = segments:get() or {}, {}
                for i = #list, 1, -1 do
                    items[#items + 1] = { label = list[i].label, icon = list[i].icon, value = i }
                end
                menu.open_menu({
                    anchor = anchor,
                    items = items,
                    width = "anchor",
                    window = opts.window,
                    on_pick = function(item) select(item.value) end,
                })
            end,
        }, function(color)
            return {
                list {
                    direction = "horizontal",
                    source = last,
                    itemfn = function(seg) return row { spacing = 4, children = content(seg, color) } end,
                },
                rect { width = g.height, height = g.height, children = { core.icon("chevrons-up-down", color, g.icon, { align_h = "center" }) } },
            }
        end)
    end

    return list {
        direction = "horizontal",
        spacing = 2,
        align_v = "center",
        source = segments:map(function(all)
            local out = {}
            for i, seg in ipairs(all or {}) do
                out[i] = { seg = seg, i = i }
            end
            return out
        end),
        itemfn = function(item)
            local kids = {}
            if item.i > 1 then
                kids[1] = core.icon("chevron-right", c.tertiary_label, CHEVRON)
            end
            kids[#kids + 1] = buttons.control(id .. "_" .. item.i, {
                size = size,
                kind = "borderless",
                on_glass = opts.on_glass,
                disabled = opts.disabled,
                window = opts.window,
                padding = { left = 6, right = 6 },
                name = item.seg.label,
                on_click = function() select(item.i) end,
                props = { spacing = 4 },
            }, function(color) return content(item.seg, color) end)
            return row { spacing = 2, align_v = "center", children = kids }
        end,
    }
end

return M
