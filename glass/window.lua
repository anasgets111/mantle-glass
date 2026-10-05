-- Liquid Glass window chrome: traffic lights, the glass toolbar and its items, and `app_window`, which
-- frames an app with an optional edge-to-edge sidebar. Metrics: docs/spec/foundations.md 3-4.
local theme = require("glass.theme")
local core = require("glass.core")
local material = require("glass.material")
local overlay = require("glass.overlay")

local c, CLEAR = theme.c, theme.CLEAR
local merge, text, icon = core.merge, core.text, core.icon

local M = {}

-- ponytail: there is no toplevel activation signal yet (mantle-27: `toplevel(id).state`); the
-- window always draws active. Bind this to the window's `activated` state once it lands.
M.active = state("glass_window_active", true)

-- Chrome per toolbar style: bar height, traffic-light origin, toolbar item size.
local CHROME = {
    titlebar = { height = 33, lights = { 9, 9.5 } },
    compact = { height = 40, lights = { 13, 13 }, item = 24 },
    unified = { height = 52, lights = { 18, 19 }, item = 36 },
}
local SIDEBAR_WIDTH = 256

-- Close, minimise, zoom: 14 px dots on a 23 px pitch, grey while the window is inactive.
function M.traffic_lights(opts)
    opts = opts or {}
    local function dot(role, run, label)
        return rect(core.shape {
            width = 14,
            height = 14,
            radius = 7,
            background = computed({ M.active, theme.scheme }, function(on, p) return on and p[role] or p.traffic_inactive end),
            shadows = { { color = "#00000073", spread = 0.5, inset = true } },
            accessible_name = label,
            focus_ring = false,
            cursor = "default",
            on_click = run,
            animate = { background = theme.motion.fade },
        })
    end
    -- ponytail: minimise and zoom need `toplevel(id):minimize()` / `:maximize()` (mantle-27).
    return row {
        spacing = 9,
        align_v = "center",
        children = {
            dot("traffic_close", opts.on_close, "Close"),
            dot("traffic_minimize", nil, "Minimise"),
            dot("traffic_zoom", nil, "Zoom"),
        },
    }
end

-- One toolbar glyph button inside a group: 28 (or 20) square, a pill while held or selected.
local function glyph_button(id, item, inner)
    local props = { width = inner, height = inner, radius = inner / 2, accessible_name = item.label, on_click = item.on_click }
    core.focusable(id, props)
    local held = core.pressable(id, props)
    local selected = type(item.selected) == "userdata" and item.selected or theme.dark:map(function() return item.selected == true end)
    props.background = computed({ held, selected, theme.scheme }, function(down, on, p)
        return (down or on) and p.vibrant_secondary_fill or CLEAR
    end)
    props.animate = { background = theme.motion.fade }
    props.children = {
        icon(item.icon, c.vibrant_label, inner == 28 and 13 or 11, material.vibrant({ align_h = "center" })),
    }
    return rect(core.shape(props))
end

-- A capsule of glass holding toolbar buttons. opts: items ({ icon, label, on_click, selected }),
-- size ("xl" 36 high, default; "medium" 24).
function M.toolbar_group(id, opts)
    local xl = opts.size ~= "medium"
    local inner, pad = xl and 28 or 20, xl and 4 or 2
    local kids = {}
    for i, item in ipairs(opts.items) do
        kids[i] = glyph_button(id .. "_" .. i, item, inner)
    end
    return row(material.glass("small", {
        height = inner + 2 * pad,
        align_v = "center",
        radius = theme.CAPSULE,
        padding = pad,
        spacing = xl and 9 or 4,
        children = kids,
    }))
end

-- A single toolbar button: a group of one.
function M.toolbar_button(id, opts)
    return M.toolbar_group(id, { size = opts.size, items = { opts } })
end

local function title_block(props)
    local kids = { text(props.title, c.vibrant_label, props.sidebar and "sidebar_title" or "window_title", material.vibrant({})) }
    if props.subtitle then
        kids[2] = text(props.subtitle, c.vibrant_tertiary_label, "control_small", material.vibrant({}))
    end
    return column { align_v = "center", spacing = 2, children = kids }
end

-- An app window in Liquid Glass chrome. props: window's own (id, title, app_id, min_size, on_close,
-- ...) plus `subtitle`, `toolbar` ("unified" default, "compact", "titlebar"), `leading` and
-- `trailing` (toolbar nodes either side of the title), `sidebar` (a node for the 256 px glass
-- pane) and `child` (the content, which scrolls under the floating toolbar).
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

function M.app_window(props)
    local style = CHROME[props.toolbar or "unified"]
    local has_sidebar = props.sidebar ~= nil
    local lights = M.traffic_lights({ on_close = props.on_close })
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
    -- The content runs under the toolbar; a hard scroll edge keeps the bar legible over it.
    local content = rect {
        width = "fill",
        height = "fill",
        background = c.window_background,
        children = {
            rect { width = "fill", height = "fill", padding = { top = style.height }, children = { props.child } },
            rect {
                width = "fill",
                height = style.height + 1,
                background = theme.dark:map(function(d) return d and "#1E1E1E8C" or "#FFFFFFD9" end),
                border_width = { bottom = 0.67 },
                border_color = { bottom = theme.dark:map(function(d) return d and "#FFFFFF1A" or "#0000000D" end) },
                children = { drag_area(props.id) },
            },
            toolbar,
        },
    }
    local panes = { content }
    if has_sidebar then
        table.insert(panes, 1, column(material.glass("sidebar", {
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
    local frame = rect(core.shape {
        width = "fill",
        height = "fill",
        radius = theme.WINDOW_RADIUS,
        clip = "rounded",
        border_width = 1,
        border_color = c.window_border,
        children = overlay.root(row { width = "fill", height = "fill", children = panes }),
    })
    local grips = resize_grips(props.id)
    table.insert(grips, 1, frame)
    return window(merge({
        background = CLEAR,
        on_escape = overlay.escape,
        on_key = overlay.key,
        child = rect { width = "fill", height = "fill", children = grips },
    }, {
        id = props.id,
        title = props.title,
        app_id = props.app_id,
        min_size = props.min_size,
        max_size = props.max_size,
        on_close = props.on_close,
    }))
end

return M
