-- Tabs: a segmented control centred over a group box, as Liquid Glass draws an NSTabView. The
-- content swaps through `children`, so a hidden tab is not built.
local segmented = require("glass.controls.segmented_control").segmented_control
local group_box = require("glass.views.group_box").group_box

-- not in the kit: the gap between the tabs and the box.
local GAP = 10

local M = {}

---@class glass.Tab
---@field name string
---@field label? string
---@field icon? string
---@field content? Node
---@field [string] "no such property"

---@class glass.TabsOpts
---@field items glass.Tab[]
---@field value? StateSignal<string> The selected tab's name; default the first.
---@field size? glass.Size
---@field height? number Minimum height of the content box.
---@field window? string
---@field name? string Accessible name of the tab bar.
---@field on_change? fun(name: string)
---@field [string] "no such property"

---@param id string
---@param opts glass.TabsOpts
---@return Node
function M.tabs(id, opts)
    ---@type StateSignal<string>
    local value = opts.value or state("glass_tabs_" .. id, opts.items[1].name)
    local items, content = {}, {}
    for i, tab in ipairs(opts.items) do
        items[i] = { value = tab.name, label = tab.label or tab.name, icon = tab.icon }
        content[tab.name] = tab.content
    end
    local bar = segmented(id .. "_tabs", { items = items, value = value, size = opts.size, window = opts.window, name = opts.name, on_change = opts.on_change })
    return column {
        width = "fill",
        spacing = GAP,
        children = {
            row { width = "fill", align_h = "center", children = { bar } },
            group_box(id, {
                content = column {
                    width = "fill",
                    min_height = opts.height,
                    children = value:map(function(name) return { content[name] } end),
                },
            }),
        },
    }
end

return M
