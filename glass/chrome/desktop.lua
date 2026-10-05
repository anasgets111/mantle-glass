-- Liquid Glass menu bar and Dock, from the kit. Desktop chrome rather than app chrome:
-- put them in a `panel`, and return `glass.overlay.popup(<panel id>)` beside it so their menus
-- and labels draw past the panel.
local theme = require("glass.theme")
local core = require("glass.core")
local material = require("glass.material")
local menu = require("glass.overlays.menu")
local tooltip = require("glass.overlays.tooltip").tooltip

local M = {}

local BAR = { height = 34, item = 24, inset = 10, trailing_inset = 20, gap = 4, radius = 12 }
local DOCK = { height = 58, radius = 15, icon = 36, gap = 9, pad = 8, dot = 4, dot_gap = 3, separator = { 1, 41, 11 } }
-- not in the kit: an app tile's corner, as native app icons round about 22% of their side
local TILE_RADIUS = 8

---@class glass.MenuBarMenu
---@field title? string
---@field icon? string Lucide name, for the leading system menu.
---@field bold? boolean The app's own name, as native apps set it.
---@field items glass.MenuItem[]
---@field [string] "no such property"

---@class glass.MenuBarOpts
---@field menus glass.MenuBarMenu[]
---@field trailing? Node[] Status items, right aligned.
---@field ink? string|Signal<string> Title colour; default white, as over a dark wallpaper.
---@field window? string The panel the menus open over; default `core.window`.
---@field [string] "no such property"

-- A transparent bar of menu titles. A click opens a title's menu; while one is open, moving onto
-- another title opens that one instead, as in native apps.
---@param id string
---@param opts glass.MenuBarOpts
---@return Node
function M.menu_bar(id, opts)
    local ink = opts.ink or "#FFFFFF"
    local opens = {}
    for i in ipairs(opts.menus) do
        opens[i] = menu.is_menu_open(id .. "_" .. i)
    end
    local any_open = computed(opens, function(...)
        for _, on in ipairs({ ... }) do
            if on then
                return true
            end
        end
        return false
    end)
    local function open(i, anchor)
        local m = opts.menus[i]
        if m.items then
            menu.open_menu({ anchor = anchor, items = m.items, id = id .. "_" .. i, window = opts.window })
        end
    end
    local kids = {}
    for i, m in ipairs(opts.menus) do
        local anchor = geometry("glass_menubar_" .. id .. "_" .. i)
        local over = hover("glass_menubar_" .. id .. "_" .. i)
        local label = m.icon and core.icon(m.icon, ink, 15, { align_v = "center" })
            or core.text(m.title, ink, "control", { font_weight = m.bold and 700 or 600 })
        kids[#kids + 1] = rect {
            height = BAR.item,
            geometry = anchor,
            hover = over,
            accessible_name = m.title or m.icon,
            cursor = "default",
            on_click = function() open(i, anchor) end,
            on_hover = function(inside)
                if inside and any_open:get() and not opens[i]:get() then
                    open(i, anchor)
                end
            end,
            children = {
                rect(material.glass("menu_bar_item", {
                    width = "fill",
                    height = "fill",
                    radius = BAR.radius,
                    opacity = opens[i]:map(function(on) return on and 1 or 0 end),
                    animate = { opacity = theme.motion.fade },
                })),
                row { height = "fill", padding = { left = BAR.inset, right = BAR.inset }, children = { label } },
            },
        }
    end
    kids[#kids + 1] = rect { width = "fill" }
    for _, node in ipairs(opts.trailing or {}) do
        kids[#kids + 1] = node
    end
    return row {
        width = "fill",
        height = BAR.height,
        align_v = "center",
        spacing = BAR.gap,
        padding = { left = BAR.inset - BAR.gap, right = BAR.trailing_inset },
        children = kids,
    }
end

---@class glass.DockItem
---@field label? string Shown above the icon on hover.
---@field icon? string Lucide glyph on a coloured tile, standing in for an app icon.
---@field color? string A `theme.SYSTEM` name for the tile; default "blue".
---@field image? string An app icon's path instead of the tile.
---@field running? boolean|Signal<boolean> Draws the dot under it.
---@field on_click? fun()
---@field separator? boolean Divides apps from folders and the Trash.
---@field [string] "no such property"

---@class glass.DockOpts
---@field items glass.DockItem[]
---@field window? string The panel its labels draw over; default `core.window`.
---@field [string] "no such property"

local function tile(item)
    if item.image then
        return image { source = item.image, width = DOCK.icon, height = DOCK.icon, fit = "contain" }
    end
    local base = theme.SYSTEM[item.color or "blue"] or theme.SYSTEM.blue
    return rect(core.shape {
        width = DOCK.icon,
        height = DOCK.icon,
        radius = TILE_RADIUS,
        background = { gradient = "linear", stops = { { 0, base[2] }, { 1, base[3] } } },
        shadows = { { color = "#00000040", offset = { x = 0, y = 1 }, blur = 2 } },
        children = { core.icon(item.icon or "app-window", "#FFFFFF", 20, { align_h = "center" }) },
    })
end

-- The Dock: a glass shelf of app icons with running dots and a separator.
-- ponytail: no magnification or bounce; icons press darker only.
---@param id string
---@param opts glass.DockOpts
---@return Node
function M.dock(id, opts)
    local kids = {}
    for i, item in ipairs(opts.items) do
        if item.separator then
            kids[#kids + 1] = rect {
                width = DOCK.separator[3],
                height = DOCK.separator[2],
                align_v = "center",
                children = { rect { width = DOCK.separator[1], height = "fill", align_h = "center", background = "#404040" } },
            }
        else
            local props = { width = DOCK.icon, accessible_name = item.label, cursor = "default", on_click = item.on_click }
            local held = core.pressable("dock_" .. id .. "_" .. i, props)
            props.effect = held:map(function(down) return down and { brightness = 0.7 } or {} end)
            local running = type(item.running) == "userdata" and item.running
                or theme.dark:map(function() return item.running == true end)
            props.children = {
                column {
                    spacing = DOCK.dot_gap,
                    children = {
                        tile(item),
                        rect(core.shape {
                            width = DOCK.dot,
                            height = DOCK.dot,
                            radius = DOCK.dot / 2,
                            align_h = "center",
                            background = "#707070",
                            blend = "plus_lighter",
                            opacity = running:map(function(on) return on and 1 or 0 end),
                        }),
                    },
                },
            }
            local node = rect(props)
            kids[#kids + 1] = item.label and tooltip("dock_" .. id .. "_" .. i, { label = item.label, child = node, window = opts.window }) or node
        end
    end
    return row(material.glass("dock", {
        height = DOCK.height,
        radius = DOCK.radius,
        padding = { left = DOCK.pad, right = DOCK.pad, top = (DOCK.height - DOCK.icon) / 2 },
        spacing = DOCK.gap,
        align_v = "start",
        children = kids,
    }))
end

return M
