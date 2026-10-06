-- List: a scrolling inset list. Selection is an inset rounded accent fill, rows may alternate.
-- Built on the engine's `list` node, which builds each row once; the overlay scroller shows while it scrolls.
local theme = require("glass.theme")
local core = require("glass.core")
local scroller = require("glass.views.scroll_view")
local knob = scroller.knob

local FADE = theme.motion.fade

-- not in the kit: the kit has no table or list specs; the medium sidebar row's metrics stand in.
local ROW = { height = 32, radius = 8, inset = 4, pad = 10, max_height = 320 }

local M = {}

-- List: selection is an accent fill. `row` gets boolean signals: `emphasized` while the row has
-- the accent fill, so its content can switch to `on_accent`; `selected` stays true while the window
-- is inactive and the fill is grey. Without `row`, an item is a string or `{ label, icon? }` and the
-- row draws it, switching its ink on the accent.
---@class glass.ListOpts
---@field items any[]|Signal<any[]>
---@field row? fun(item: any, emphasized: Signal<boolean>, selected: Signal<boolean>): Node
---@field key? fun(item: any): string Unique per item; default the item's `label`, else `tostring`.
---@field value? StateSignal<string> The selected key.
---@field alternating? boolean Tint every other row.
---@field max_height? number Default 320; longer lists scroll.
---@field width? number|"fill" Default "fill".
---@field height? number|"fill" A fixed height instead of growing to `max_height`.
---@field on_select? fun(item: any)
---@field window? string
---@field [string] "no such property"

local function label_of(item)
    return type(item) == "table" and item.label or tostring(item)
end

local function default_row(item, emphasized)
    local kids = {}
    if type(item) == "table" and item.icon then
        kids[1] = core.icon(item.icon, theme.pick(emphasized, "on_accent", "accent"), 13, {})
    end
    kids[#kids + 1] = core.text(label_of(item), theme.pick(emphasized, "on_accent", "label"), "body", { width = "fill", elide = "end" })
    return row { width = "fill", spacing = 8, align_v = "center", children = kids }
end

---@param id string
---@param opts glass.ListOpts
---@return Node
function M.list(id, opts)
    opts = opts or {}
    local active = core.active(opts.window)
    local key = opts.key or label_of
    local draw = opts.row or default_row
    ---@type StateSignal<string>
    local value = opts.value or state("glass_list_" .. id, "")
    local items = type(opts.items) == "userdata" and opts.items or theme.dark:map(function() return opts.items end)
    local indexed = items:map(function(all)
        local out = {}
        for i, item in ipairs(all or {}) do
            out[i] = { item = item, i = i }
        end
        return out
    end)
    local offset, view = scroll("glass_list_" .. id), geometry("glass_list_" .. id)
    local list_node = list {
        width = "fill",
        height = opts.height and "fill",
        max_height = opts.height and nil or opts.max_height or ROW.max_height,
        padding = { left = ROW.inset, right = ROW.inset },
        scroll = offset,
        animate = { scroll = scroller.ease("list_" .. id) },
        geometry = view,
        source = indexed,
        key = function(entry) return key(entry.item) end,
        itemfn = function(entry)
            local k = key(entry.item)
            local selected = value:map(function(v) return v == k end)
            local emphasized = computed({ selected, active }, function(on, a) return on and a end)
            local props = {
                width = "fill",
                height = ROW.height,
                radius = ROW.radius,
                padding = { left = ROW.pad, right = ROW.pad },
                align_v = "center",
                animate = { background = FADE },
                children = { draw(entry.item, emphasized, selected) },
                on_click = function()
                    value:set(k)
                    if opts.on_select then
                        opts.on_select(entry.item)
                    end
                end,
            }
            local striped = opts.alternating and entry.i % 2 == 0
            -- not in the kit: native lists fill a key window's selected row with the accent, else grey.
            props.background = computed({ selected, active, theme.scheme }, function(on, a, p)
                return on and (a and p.accent or p.inactive_selected_fill) or striped and p.quaternary_fill or theme.CLEAR
            end)
            return row(core.shape(props))
        end,
    }
    return rect {
        width = opts.width or "fill",
        height = opts.height,
        children = { list_node, knob("list_" .. id, offset, view, indexed:map(function(all) return #all * ROW.height end)) },
    }
end

return M
