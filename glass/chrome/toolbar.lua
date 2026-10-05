-- Liquid Glass toolbar items, from the kit: traffic lights, glass capsules of glyph
-- buttons, the back/forward group and the sidebar toggle.
local theme = require("glass.theme")
local core = require("glass.core")
local material = require("glass.material")
local sig = require("glass.internal.toggles").sig

local c, CLEAR, icon = theme.c, theme.CLEAR, core.icon

local M = {}

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
    local function dot(role, glyph, run, label)
        return rect(core.shape {
            width = utility and 10 or 14,
            height = utility and 10 or 14,
            radius = utility and 5 or 7,
            background = computed({ lit, theme.scheme }, function(on, p) return on and p[role] or p.traffic_inactive end),
            shadows = { { color = "#00000073", spread = 0.5, inset = true } },
            accessible_name = label,
            focus_ring = false,
            cursor = "default",
            on_click = run,
            animate = { background = theme.motion.fade },
            children = {
                icon(glyph, "#00000099", utility and 5 or 7, {
                    align_h = "center",
                    opacity = over:map(function(h) return h and 1 or 0 end),
                }),
            },
        })
    end
    -- ponytail: minimise and zoom stay inert until the engine can ask the compositor for them.
    return row {
        spacing = utility and 7 or 9,
        align_v = "center",
        hover = over,
        children = {
            dot("traffic_close", "x", opts.on_close, "Close"),
            dot("traffic_minimize", "minus", nil, "Minimise"),
            dot("traffic_zoom", "maximize-2", nil, "Zoom"),
        },
    }
end

-- One toolbar glyph button inside a group: 28 (or 20) square, a pill while held or selected.
local function glyph_button(id, item, inner, active, wide)
    local off = sig(item.disabled or false)
    local props = {
        width = wide or inner,
        height = inner,
        radius = inner / 2,
        align_v = "center",
        accessible_name = item.label,
        on_click = function()
            if item.on_click and not off:get() then
                item.on_click()
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
---@field selected? boolean|Signal<boolean>
---@field disabled? boolean|Signal<boolean>
---@field [string] "no such property"

---@class glass.ToolbarGroupOpts
---@field items glass.ToolbarItem[]
---@field size? "xl"|"medium" "xl" 36 high (default), "medium" 24.
---@field window? string The id whose focus it follows.
---@field active? Signal<boolean> Overrides the window's focus, for an inline preview.
---@field [string] "no such property"

---@param id string
---@param opts glass.ToolbarGroupOpts
---@return Node
function M.toolbar_group(id, opts)
    local xl = opts.size ~= "medium"
    local inner, pad = xl and 28 or 20, xl and 4 or 2
    local active = opts.active or core.active(opts.window)
    local kids = {}
    for i, item in ipairs(opts.items) do
        kids[i] = glyph_button(id .. "_" .. i, item, inner, active)
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
---@field size? "xl"|"medium"
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
---@field size? "xl"|"medium" Default "xl".
---@field window? string
---@field active? Signal<boolean>
---@field [string] "no such property"

---@param id string
---@param opts? glass.ToolbarNavigationOpts
---@return Node
function M.toolbar_navigation(id, opts)
    opts = opts or {}
    local active = opts.active or core.active(opts.window)
    local medium = opts.size == "medium"
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

-- The sidebar toggle: 36 px in the expanded and unified toolbars, 24 px in compact.
---@class glass.SidebarToggleOpts
---@field shown StateSignal<boolean>
---@field size? "xl"|"medium"
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
