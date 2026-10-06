-- Liquid Glass dropdown and pull-down buttons, from the kit.
local theme = require("glass.theme")
local core = require("glass.core")
local menu = require("glass.overlays.menu")
local buttons = require("glass.internal.buttons")

local text, icon = core.text, core.icon

local M = {}

-- Label inset, then the chevron cell's glyph size, per control size (the cell is height square).
local GEOMETRY = {
    xs = { inset = 7, pop = 10, pull = 8.5 },
    s = { inset = 10, pop = 11, pull = 10 },
    m = { inset = 12, pop = 13, pull = 10 },
    l = { inset = 14, pop = 13, pull = 13 },
    xl = { inset = 18, pop = 13, pull = 13 },
}

local function item_of(i)
    return type(i) == "table" and core.merge({ value = i.label }, i) or { label = i, value = i }
end

-- The button both kinds share: `label` text (a signal or string) and a chevron cell.
local function menu_button(id, opts, glyph, glyph_size, label, on_open)
    local size, g = theme.SIZES[opts.size or "m"], GEOMETRY[opts.size or "m"]
    local anchor = geometry("glass_anchor_" .. id)
    return buttons.control(id, {
        size = opts.size,
        kind = "bezel",
        on_glass = opts.on_glass,
        disabled = opts.disabled,
        window = opts.window,
        width = opts.width,
        padding = { left = g.inset },
        name = opts.name or type(opts.label) == "string" and opts.label or id,
        on_click = function() on_open(anchor) end,
        props = core.merge({ geometry = anchor }, opts.props),
    }, function(color)
        local vib = buttons.vibrant({ kind = "bezel", on_glass = opts.on_glass })
        return {
            text(label, color, size.label, core.merge({ width = opts.width and "fill" or nil }, vib)),
            rect { width = size.height, height = size.height, children = {
                icon(glyph, color, glyph_size, core.merge({ align_h = "center" }, vib)),
            } },
        }
    end)
end

-- Dropdown: shows the selected item and opens a menu to change it.
---@class glass.DropdownOpts: glass.ControlOpts
---@field items (string|glass.MenuItem)[] A string is its own label and value; a table's `value` defaults to its label.
---@field value? StateSignal<any> The selected value; default the first item.
---@field label? string|Signal<string> Text above the control.
---@field on_change? fun(value: any)
---@field width? number Default fits the selected label.
---@field name? string Accessible name; default the label.
---@field props? table
---@field [string] "no such property"

---@param id string
---@param opts glass.DropdownOpts
---@return Node
function M.dropdown(id, opts)
    local items = {}
    for i, item in ipairs(opts.items) do
        items[i] = item_of(item)
    end
    local value = opts.value or state("glass_dropdown_" .. id, items[1] and items[1].value)
    local label = value:map(function(v)
        for _, item in ipairs(items) do
            if item.value == v then
                return item.label
            end
        end
        return ""
    end)
    local button = menu_button(id, opts, "chevrons-up-down", GEOMETRY[opts.size or "m"].pop, label, function(anchor)
        local now, shown = value:get(), {}
        for i, item in ipairs(items) do
            shown[i] = core.merge({ checked = item.value == now }, item)
        end
        menu.open_menu({
            anchor = anchor,
            items = shown,
            width = "anchor",
            window = opts.window,
            on_pick = function(item)
                value:set(item.value)
                if opts.on_change then
                    opts.on_change(item.value)
                end
            end,
        })
    end)
    if not opts.label then
        return button
    end
    return column { spacing = 4, children = { text(opts.label, theme.c.label, theme.SIZES[opts.size or "m"].label), button } }
end

-- Pull-down button: a title and a chevron that opens a list of actions.
---@class glass.PullDownButtonOpts: glass.ControlOpts
---@field label? string|Signal<string>
---@field items glass.MenuItem[] Menu items with `on_click`.
---@field width? number
---@field name? string
---@field props? table
---@field [string] "no such property"

---@param id string
---@param opts glass.PullDownButtonOpts
---@return Node
function M.pull_down_button(id, opts)
    return menu_button(id, opts, "chevron-down", GEOMETRY[opts.size or "m"].pull, opts.label or "", function(anchor)
        menu.open_menu({ anchor = anchor, items = opts.items, width = "anchor", window = opts.window })
    end)
end

return M
