-- Liquid Glass toolbar items, from the kit: traffic lights, glass capsules of glyph
-- buttons, the back/forward group and the sidebar toggle.
local theme = require("glass.theme")
local core = require("glass.core")
local material = require("glass.material")
local sig = require("glass.internal.toggles").sig
local menu = require("glass.overlays.menu")

local c, CLEAR, icon = theme.c, theme.CLEAR, core.icon

local M = {}

local ON = theme.dark:map(function() return true end)

-- Close, minimise, zoom: 14 px dots on a 23 px pitch, grey while the window is inactive. Hovering
-- the group colours them and shows their glyphs (not in the kit; as native apps draw them). A utility
-- panel's are 10 px on a 17 px pitch.
---@class glass.TrafficLightsOpts
---@field on_close? fun()
---@field window? string
---@field kind? "window"|"utility"
---@field active? Signal<boolean> Overrides the window's focus, for an inline preview.
---@field [string] "no such property"

---@param opts? glass.TrafficLightsOpts
---@return Node
function M.traffic_lights(opts)
    opts = opts or {}
    local utility = opts.kind == "utility"
    local active = opts.active or core.active(opts.window)
    local over = hover("glass_lights_" .. (opts.window or "app"))
    local lit = computed({ active, over }, function(on, h) return on or h end)
    -- A real window asks the compositor; one it refuses greys out. Previews (`active` given) only draw.
    local win = not opts.active and opts.window and toplevel(opts.window)
    local can = win and win:state():map(function(s) return s.capabilities end)
    local function allowed(cap)
        return can and can:map(function(caps) return caps[cap] ~= false end) or ON
    end
    local function dot(role, glyph, run, label, enabled)
        enabled = enabled or ON
        return rect(core.shape {
            width = utility and 10 or 14,
            height = utility and 10 or 14,
            radius = utility and 5 or 7,
            background = computed({ lit, enabled, theme.scheme }, function(on, ok, p) return on and ok and p[role] or p.traffic_inactive end),
            shadows = { { color = "#00000073", spread = 0.5, inset = true } },
            accessible_name = label,
            focus_ring = false,
            cursor = "default",
            on_click = function(...)
                if run and enabled:get() then
                    run(...)
                end
            end,
            animate = { background = theme.motion.fade },
            children = {
                icon(glyph, "#00000099", utility and 5 or 7, {
                    align_h = "center",
                    opacity = over:map(function(h) return h and 1 or 0 end),
                }),
            },
        })
    end
    -- Liquid Glass: the green light toggles full screen; with Option (Alt) it zooms.
    local function zoom(_, _, _, mods)
        if not win then
            return
        end
        local s = win:state():get()
        if mods and mods.alt then
            win:set_maximized(not s.maximized)
        else
            win:set_fullscreen(not s.fullscreen)
        end
    end
    return row {
        spacing = utility and 7 or 9,
        align_v = "center",
        hover = over,
        children = {
            dot("traffic_close", "x", opts.on_close, "Close"),
            dot("traffic_minimize", "minus", win and function() win:set_minimized() end, "Minimise", allowed("minimize")),
            dot("traffic_zoom", "maximize-2", win and zoom, "Zoom", allowed("fullscreen")),
        },
    }
end

-- One toolbar glyph button inside a group: 28 (or 20) square, a pill while held or selected.
local function glyph_button(id, item, inner, active, wide, window)
    local off = sig(item.disabled or false)
    local anchor = item.menu and geometry("glass_toolbar_menu_" .. id)
    local props = {
        geometry = anchor,
        width = wide or inner,
        height = inner,
        radius = inner / 2,
        align_v = "center",
        accessible_name = item.label,
        on_click = function()
            if off:get() then
                return
            end
            if item.on_click then
                item.on_click()
            end
            if item.menu then
                menu.open_menu({ anchor = anchor, items = item.menu, align = "end", window = window })
            end
        end,
    }
    core.focusable(id, props)
    local held = core.pressable(id, props)
    local selected = type(item.selected) == "userdata" and item.selected or theme.dark:map(function() return item.selected == true end)
    props.background = computed({ held, selected, theme.scheme }, function(down, on, p)
        return (down or on) and p.vibrant_secondary_fill or CLEAR
    end)
    props.animate = { background = theme.motion.fade }
    props.children = {
        icon(item.icon, theme.pick(computed({ active, off }, function(on, d) return on and not d end), "vibrant_label", "vibrant_tertiary_label"), inner == 28 and 13 or 11,
            material.vibrant({ align_h = "center" })),
    }
    return rect(core.shape(props))
end

-- A capsule of glass holding toolbar buttons.
---@class glass.ToolbarItem
---@field icon string
---@field label? string
---@field on_click? fun()
---@field menu? glass.MenuItem[] Opens under the button when clicked.
---@field selected? boolean|Signal<boolean>
---@field disabled? boolean|Signal<boolean>
---@field [string] "no such property"

---@class glass.ToolbarGroupOpts
---@field items glass.ToolbarItem[]
---@field size? "xl"|"m" "xl" 36 high (default), "m" 24.
---@field window? string The id whose focus it follows.
---@field active? Signal<boolean> Overrides the window's focus, for an inline preview.
---@field [string] "no such property"

---@param id string
---@param opts glass.ToolbarGroupOpts
---@return Node
function M.toolbar_group(id, opts)
    local xl = opts.size ~= "m"
    local inner, pad = xl and 28 or 20, xl and 4 or 2
    local active = opts.active or core.active(opts.window)
    local kids = {}
    for i, item in ipairs(opts.items) do
        kids[i] = glyph_button(id .. "_" .. i, item, inner, active, nil, opts.window)
    end
    return row(material.glass(material.by_activity("small", active), {
        height = inner + 2 * pad,
        align_v = "center",
        radius = theme.CAPSULE,
        padding = pad,
        spacing = xl and 9 or 4,
        children = kids,
    }))
end

-- A single toolbar button: a group of one.
---@class glass.ToolbarButtonOpts: glass.ToolbarItem
---@field size? "xl"|"m"
---@field window? string
---@field active? Signal<boolean>
---@field [string] "no such property"

---@param id string
---@param opts glass.ToolbarButtonOpts
---@return Node
function M.toolbar_button(id, opts)
    return M.toolbar_group(id, { size = opts.size, window = opts.window, active = opts.active, items = { opts } })
end

-- Back and forward in one glass capsule: 73x36 (two 20 px buttons around a 3x22 separator), or
-- 55x24 medium (24x20 buttons around a 3x16 separator).
---@class glass.ToolbarNavigationOpts
---@field can_back? boolean|Signal<boolean> Default true.
---@field can_forward? boolean|Signal<boolean> Default true.
---@field on_back? fun()
---@field on_forward? fun()
---@field size? "xl"|"m" Default "xl".
---@field window? string
---@field active? Signal<boolean>
---@field [string] "no such property"

---@param id string
---@param opts? glass.ToolbarNavigationOpts
---@return Node
function M.toolbar_navigation(id, opts)
    opts = opts or {}
    local active = opts.active or core.active(opts.window)
    local medium = opts.size == "m"
    local function button(name, glyph, label, can, run)
        local item = { icon = glyph, label = label, on_click = run, disabled = sig(can == nil or can):map(function(on) return not on end) }
        return glyph_button(id .. "_" .. name, item, 20, active, medium and 24 or nil)
    end
    return row(material.glass(material.by_activity("small", active), {
        width = medium and 55 or 73,
        height = medium and 24 or 36,
        align_v = "center",
        radius = theme.CAPSULE,
        padding = medium and 2 or { left = 9.5, right = 9.5 },
        spacing = medium and 0 or 5.5,
        children = {
            button("back", "chevron-left", "Back", opts.can_back, opts.on_back),
            rect {
                width = 3,
                height = medium and 16 or 22,
                align_v = "center",
                children = { rect(material.vibrant({ width = 1, height = "fill", align_h = "center", background = c.vibrant_tertiary_fill })) },
            },
            button("forward", "chevron-right", "Forward", opts.can_forward, opts.on_forward),
        },
    }))
end

-- Window tabs, as file managers and browsers draw them: equal-width tabs on a fill strip, the
-- selected one raised on small glass, a close button on the hovered one and a + after the strip.
-- not in the kit: the metrics, and that the hover tint is a fill.
M.TAB_BAR = 34
local TAB = { strip = 28, pad = 2, radius = 7, gap = 2, close = 16, new = 24, inset = 8 }

---@class glass.TabBarTab
---@field name string Unique key, the value of `tab`.
---@field title string
---@field [string] "no such property"

---@class glass.TabBarOpts
---@field tabs glass.TabBarTab[]|Signal<glass.TabBarTab[]>
---@field tab? StateSignal<string> The selected tab's name; default its own, the first.
---@field on_new_tab? fun()
---@field on_close_tab? fun(name: string)
---@field window? string
---@field active? Signal<boolean>
---@field [string] "no such property"

-- Build it once: each tab keeps its hover across list changes. The bar shows no tab selected once
-- `tab` names none, so the app picks the next one when it closes the selected tab.
---@param id string
---@param opts glass.TabBarOpts
---@return Node
function M.tab_bar(id, opts)
    local active = opts.active or core.active(opts.window)
    local tabs = sig(opts.tabs)
    local tab = opts.tab or state(id .. "_tab", (tabs:get()[1] or {}).name or "")
    local function item(t)
        local over = hover(id .. "_h_" .. t.name)
        local selected = tab:map(function(v) return v == t.name end)
        local node = {
            width = "fill",
            height = "fill",
            radius = TAB.radius,
            hover = over,
            accessible_name = t.title,
            cursor = "default",
            on_click = function() tab:set(t.name) end,
        }
        core.focusable(id .. "_" .. t.name, node)
        node.children = {
            rect(core.shape {
                width = "fill",
                height = "fill",
                radius = TAB.radius,
                hittable = false,
                background = c.secondary_fill,
                opacity = computed({ over, selected }, function(h, on) return h and not on and 1 or 0 end),
                animate = { opacity = theme.motion.fade },
            }),
            rect(material.glass(material.by_activity("small", active), {
                width = "fill",
                height = "fill",
                radius = TAB.radius,
                hittable = false,
                opacity = selected:map(function(on) return on and 1 or 0 end),
                animate = { opacity = theme.motion.fade },
            })),
            core.text(t.title, theme.pick(selected, "label", "secondary_label"), "control_small", {
                align_h = "center",
                align_v = "center",
                elide = "end",
                margin = { left = TAB.close + 12, right = TAB.close + 12 },
                hittable = false,
            }),
            rect(core.shape {
                width = TAB.close,
                height = TAB.close,
                radius = TAB.close / 2,
                align_v = "center",
                margin = { left = 6 },
                accessible_name = "Close " .. t.title,
                opacity = over:map(function(h) return h and 1 or 0 end),
                animate = { opacity = theme.motion.fade },
                on_click = function()
                    if opts.on_close_tab then
                        opts.on_close_tab(t.name)
                    end
                end,
                children = { icon("x", c.secondary_label, 10, { align_h = "center" }) },
            }),
        }
        return rect(core.shape(node))
    end
    local strip = row {
        width = "fill",
        height = TAB.strip,
        radius = TAB.radius + TAB.pad,
        padding = TAB.pad,
        spacing = TAB.gap,
        background = c.tertiary_fill,
        children = { list {
            width = "fill",
            height = "fill",
            direction = "horizontal",
            spacing = TAB.gap,
            source = tabs,
            key = function(t) return t.name end,
            itemfn = item,
        } },
    }
    local plus = {
        width = TAB.new,
        height = TAB.new,
        radius = TAB.new / 2,
        margin = { top = (TAB.strip - TAB.new) / 2 },
        accessible_name = "New tab",
        on_click = opts.on_new_tab,
        animate = { background = theme.motion.fade },
    }
    core.focusable(id .. "_new", plus)
    local held = core.pressable(id .. "_new", plus)
    plus.background = computed({ held, theme.scheme }, function(down, p) return down and p.secondary_fill or CLEAR end)
    plus.children = { icon("plus", c.secondary_label, 14, { align_h = "center" }) }
    return row {
        width = "fill",
        height = M.TAB_BAR,
        align_v = "start",
        spacing = 6,
        padding = { left = TAB.inset, right = TAB.inset },
        children = { strip, rect(core.shape(plus)) },
    }
end

-- The sidebar toggle: 36 px in the expanded and unified toolbars, 24 px in compact.
---@class glass.SidebarToggleOpts
---@field shown StateSignal<boolean>
---@field size? "xl"|"m"
---@field window? string
---@field active? Signal<boolean>
---@field [string] "no such property"

---@param id string
---@param opts glass.SidebarToggleOpts
---@return Node
function M.sidebar_toggle(id, opts)
    return M.toolbar_button(id, {
        icon = "panel-left",
        label = "Toggle sidebar",
        size = opts.size,
        window = opts.window,
        active = opts.active,
        on_click = function() opts.shown:set(not opts.shown:get()) end,
    })
end

return M
