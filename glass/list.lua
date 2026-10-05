-- List: a scrolling inset list. Selection is an inset rounded accent fill, rows may alternate.
-- Built on the engine's `list` node, which builds each row once.
local theme = require("glass.theme")
local core = require("glass.core")

local c, FADE = theme.c, theme.motion.fade

-- not in the kit: the kit has no table or list specs; the medium sidebar row's metrics stand in.
local ROW = { height = 32, radius = 8, inset = 4, pad = 10, max_height = 320 }

local M = {}

-- List: selection is an accent fill. `row` gets boolean signals: `emphasized` while the row has
-- the accent fill, so its content can switch to `on_accent`; `selected` stays true while the window
-- is inactive and the fill is grey.
---@class glass.ListOpts
---@field items any[]|Signal<any[]>
---@field row fun(item: any, emphasized: Signal<boolean>, selected: Signal<boolean>): Node
---@field key? fun(item: any): string Unique per item; default `tostring`.
---@field value? StateSignal<string> The selected key.
---@field alternating? boolean Tint every other row.
---@field max_height? number Default 320; longer lists scroll.
---@field on_select? fun(item: any)
---@field window? string
---@field [string] "no such property"

---@param id string
---@param opts glass.ListOpts
---@return Node
function M.list(id, opts)
    opts = opts or {}
    local active = core.active(opts.window)
    local key = opts.key or tostring
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
    return list {
        width = "fill",
        max_height = opts.max_height or ROW.max_height,
        padding = { left = ROW.inset, right = ROW.inset },
        scroll = scroll("glass_list_" .. id),
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
                children = { opts.row(entry.item, emphasized, selected) },
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
end

return M
