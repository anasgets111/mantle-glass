-- Liquid Glass window chrome: traffic lights, the glass toolbar and its items, and `app_window`, which
-- frames an app with an optional edge-to-edge sidebar. Metrics: docs/spec/foundations.md 3-4.
local theme = require("glass.theme")
local core = require("glass.core")
local material = require("glass.material")
local overlay = require("glass.overlay")

local c, CLEAR = theme.c, theme.CLEAR
local merge, text, icon = core.merge, core.text, core.icon

local M = {}

M.active = core.active

-- A glass style while `active`, its inactive variant otherwise.
local function by_activity(style, active)
    return active:map(function(on) return on and style or style .. "_inactive" end)
end

-- Chrome per toolbar style: bar height, traffic-light origin, toolbar item size.
local CHROME = {
    titlebar = { height = 33, lights = { 9, 9.5 } },
    compact = { height = 40, lights = { 13, 13 }, item = 24 },
    unified = { height = 52, lights = { 18, 19 }, item = 36 },
}
local SIDEBAR_WIDTH = 256

-- Window drop shadows (docs/spec/foundations.md 3.1): a wide ambient one and a 1 px rim. Dark without
-- a sidebar uses the tighter one while active; every inactive window uses it at half strength.
local RIM = { color = "#000000CC", blur = 1 }
local SHADOWS = {
    active = { { color = "#00000066", offset = { x = 0, y = 36 }, blur = 100 }, RIM },
    active_tight = { { color = "#00000066", offset = { x = 0, y = 16 }, blur = 33 }, RIM },
    inactive = { { color = "#00000033", offset = { x = 0, y = 16 }, blur = 32 }, RIM },
}
-- The band `geometry_inset` adds around the frame for the widest shadow: its blur radius past the
-- frame, less the y offset above and plus it below.
local BAND = { left = 100, right = 100, top = 64, bottom = 136 }

-- The band per side: none on a tiled side, none at all maximised or fullscreen.
local function band(s)
    if s.maximized or s.fullscreen then
        return 0
    end
    local t = s.tiled
    return {
        left = t.left and 0 or BAND.left,
        right = t.right and 0 or BAND.right,
        top = t.top and 0 or BAND.top,
        bottom = t.bottom and 0 or BAND.bottom,
    }
end

-- Close, minimise, zoom: 14 px dots on a 23 px pitch, grey while the window is inactive. Hovering
-- the group colours them and shows their glyphs (not in the kit; as native apps draw them).
---@class glass.TrafficLightsOpts
---@field on_close? fun()
---@field window? string
---@field [string] "no such property"

---@param opts? glass.TrafficLightsOpts
---@return Node
function M.traffic_lights(opts)
    opts = opts or {}
    local active = M.active(opts.window)
    local over = hover("glass_lights_" .. (opts.window or "app"))
    local lit = computed({ active, over }, function(on, h) return on or h end)
    local function dot(role, glyph, run, label)
        return rect(core.shape {
            width = 14,
            height = 14,
            radius = 7,
            background = computed({ lit, theme.scheme }, function(on, p) return on and p[role] or p.traffic_inactive end),
            shadows = { { color = "#00000073", spread = 0.5, inset = true } },
            accessible_name = label,
            focus_ring = false,
            cursor = "default",
            on_click = run,
            animate = { background = theme.motion.fade },
            children = {
                icon(glyph, "#00000099", 7, {
                    align_h = "center",
                    opacity = over:map(function(h) return h and 1 or 0 end),
                }),
            },
        })
    end
    -- ponytail: minimise and zoom need `toplevel(id):minimize()` / `:maximize()` (mantle-27).
    return row {
        spacing = 9,
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
local function glyph_button(id, item, inner, active)
    local props = { width = inner, height = inner, radius = inner / 2, accessible_name = item.label, on_click = item.on_click }
    core.focusable(id, props)
    local held = core.pressable(id, props)
    local selected = type(item.selected) == "userdata" and item.selected or theme.dark:map(function() return item.selected == true end)
    props.background = computed({ held, selected, theme.scheme }, function(down, on, p)
        return (down or on) and p.vibrant_secondary_fill or CLEAR
    end)
    props.animate = { background = theme.motion.fade }
    props.children = {
        icon(item.icon, theme.pick(active, "vibrant_label", "vibrant_tertiary_label"), inner == 28 and 13 or 11,
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
---@field [string] "no such property"

---@class glass.ToolbarGroupOpts
---@field items glass.ToolbarItem[]
---@field size? "xl"|"medium" "xl" 36 high (default), "medium" 24.
---@field window? string The id whose focus it follows.
---@field [string] "no such property"

---@param id string
---@param opts glass.ToolbarGroupOpts
---@return Node
function M.toolbar_group(id, opts)
    local xl = opts.size ~= "medium"
    local inner, pad = xl and 28 or 20, xl and 4 or 2
    local active = M.active(opts.window)
    local kids = {}
    for i, item in ipairs(opts.items) do
        kids[i] = glyph_button(id .. "_" .. i, item, inner, active)
    end
    return row(material.glass(by_activity("small", active), {
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
---@field [string] "no such property"

---@param id string
---@param opts glass.ToolbarButtonOpts
---@return Node
function M.toolbar_button(id, opts)
    return M.toolbar_group(id, { size = opts.size, window = opts.window, items = { opts } })
end

local function title_block(props)
    local title_color = theme.pick(M.active(props.id), "vibrant_label", "vibrant_tertiary_label")
    local kids = { text(props.title, title_color, props.sidebar and "sidebar_title" or "window_title", material.vibrant({})) }
    if props.subtitle then
        kids[2] = text(props.subtitle, c.vibrant_tertiary_label, "control_small", material.vibrant({}))
    end
    return column { align_v = "center", spacing = 2, children = kids }
end

-- A press on empty chrome moves the window; a right press opens the compositor's window menu.
-- Drag areas sit behind the chrome's controls, never around them, so a control's press stays its own.
local function drag_area(id)
    return rect {
        width = "fill",
        height = "fill",
        on_press = function(_, button)
            if button == "left" then
                toplevel(id):move()
            elseif button == "right" then
                toplevel(id):show_menu()
            end
        end,
    }
end

-- Invisible handles on the frame's edges and corners that start a compositor resize.
local GRIP = 6
local function resize_grips(id)
    local function grip(edge, cursor, props)
        props.cursor = cursor
        props.on_press = function(_, button)
            if button == "left" then
                toplevel(id):resize(edge)
            end
        end
        return rect(props)
    end
    return {
        grip("top", "ns-resize", { width = "fill", height = GRIP }),
        grip("bottom", "ns-resize", { width = "fill", height = GRIP, align_v = "end" }),
        grip("left", "ew-resize", { width = GRIP, height = "fill" }),
        grip("right", "ew-resize", { width = GRIP, height = "fill", align_h = "end" }),
        grip("top_left", "nwse-resize", { width = 2 * GRIP, height = 2 * GRIP }),
        grip("top_right", "nesw-resize", { width = 2 * GRIP, height = 2 * GRIP, align_h = "end" }),
        grip("bottom_left", "nesw-resize", { width = 2 * GRIP, height = 2 * GRIP, align_v = "end" }),
        grip("bottom_right", "nwse-resize", { width = 2 * GRIP, height = 2 * GRIP, align_h = "end", align_v = "end" }),
    }
end

-- The band under the toolbar (docs/spec/foundations.md 2.5): "soft" fades the window's colour out,
-- "hard" is the window's colour over a blur, with a hairline.
-- ponytail: soft also blurs under its fade (r100); a masked backdrop blur sees nothing (engine gap).
local function scroll_edge(kind, height)
    if kind == "hard" then
        return rect {
            width = "fill",
            height = height,
            hittable = false,
            background = theme.dark:map(function(d) return d and "#1E1E1E8C" or "#FFFFFFD9" end),
            effect = { backdrop = { blur = 3 } },
            border_width = { bottom = 0.67 },
            border_color = { bottom = theme.dark:map(function(d) return d and "#FFFFFF1A" or "#0000000D" end) },
        }
    end
    return rect {
        width = "fill",
        height = height,
        hittable = false,
        background = c.window_background:map(function(bg)
            return { gradient = "linear", stops = { { 0, theme.alpha(bg, 0.6) }, { 1, theme.alpha(bg, 0) } } }
        end),
    }
end

local CHROME_PROPS = { subtitle = true, toolbar = true, leading = true, trailing = true, scroll_edge = true, sidebar = true, child = true }

-- An app window in Liquid Glass chrome: any `window` field plus the chrome fields below.
---@class glass.AppWindowProps: WindowProps
---@field subtitle? string|Signal<string>
---@field toolbar? "unified"|"compact"|"titlebar" Default "unified".
---@field leading? Node[] Toolbar nodes left of the title.
---@field trailing? Node[] Toolbar nodes right of the title.
---@field scroll_edge? "soft"|"hard" Default "soft" fade; "hard" is a blurred band with a hairline.
---@field sidebar? Node The 256 px glass pane.
---@field child? Node The content, which scrolls under the floating toolbar.

---@param props glass.AppWindowProps
---@return Surface
function M.app_window(props)
    local own = {}
    for k, v in pairs(props) do
        if not CHROME_PROPS[k] then
            own[k] = v
        end
    end
    local style = CHROME[props.toolbar or "unified"]
    local has_sidebar = props.sidebar ~= nil
    local lights = M.traffic_lights({ on_close = props.on_close, window = props.id })
    local bar = {}
    if props.leading then
        for _, node in ipairs(props.leading) do bar[#bar + 1] = node end
    end
    bar[#bar + 1] = title_block(props)
    bar[#bar + 1] = rect { width = "fill" }
    if props.trailing then
        for _, node in ipairs(props.trailing) do bar[#bar + 1] = node end
    end
    local toolbar = row {
        width = "fill",
        height = style.height,
        spacing = 8,
        padding = { left = has_sidebar and 8 or style.lights[1] + 68 + 12, right = 8 },
        children = bar,
    }
    -- The content runs under the toolbar; the scroll edge keeps the bar legible over it.
    local content = rect {
        width = "fill",
        height = "fill",
        background = c.window_background,
        children = {
            rect { width = "fill", height = "fill", padding = { top = style.height }, children = { props.child } },
            scroll_edge(props.scroll_edge, style.height + 1),
            rect { width = "fill", height = style.height, children = { drag_area(props.id) } },
            toolbar,
        },
    }
    local panes = { content }
    if has_sidebar then
        table.insert(panes, 1, column(material.glass(by_activity("sidebar", M.active(props.id)), {
            width = SIDEBAR_WIDTH,
            height = "fill",
            children = {
                rect {
                    width = "fill",
                    height = style.height,
                    children = { drag_area(props.id), row { height = style.height, padding = { left = style.lights[1] }, children = { lights } } },
                },
                props.sidebar,
            },
        })))
    else
        content.children[#content.children + 1] = rect {
            margin = { left = style.lights[1], top = style.lights[2] },
            children = { lights },
        }
    end
    local window_state = toplevel(props.id):state()
    -- Square the corners the window shares with a screen edge or a neighbour, and all of them maximised.
    local frame = rect(core.shape {
        width = "fill",
        height = "fill",
        radius = window_state:map(function(s)
            local t, R = s.tiled, theme.WINDOW_RADIUS
            if s.maximized or s.fullscreen then
                return 0
            end
            return {
                top_left = (t.top or t.left) and 0 or R,
                top_right = (t.top or t.right) and 0 or R,
                bottom_right = (t.bottom or t.right) and 0 or R,
                bottom_left = (t.bottom or t.left) and 0 or R,
            }
        end),
        clip = "rounded",
        border_width = 1,
        border_color = c.window_border,
        shadows = computed({ M.active(props.id), theme.dark }, function(on, dark)
            if not on then
                return SHADOWS.inactive
            end
            return dark and not has_sidebar and SHADOWS.active_tight or SHADOWS.active
        end),
        geometry = overlay.bounds(props.id),
        children = overlay.root(row { width = "fill", height = "fill", children = panes }, props.id),
    })
    local grips = resize_grips(props.id)
    table.insert(grips, 1, frame)
    local inset = window_state:map(band)
    return window(merge({
        background = CLEAR,
        decorations = "client",
        geometry_inset = inset,
        on_escape = function() overlay.escape(props.id) end,
        on_key = function(key) return overlay.key(props.id, key) end,
        child = rect {
            width = "fill",
            height = "fill",
            padding = inset,
            children = { rect { width = "fill", height = "fill", children = grips } },
        },
    }, own))
end

return M
