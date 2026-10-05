-- Liquid Glass window chrome: traffic lights, the glass toolbar and its items, and `app_window`, which
-- frames an app with an optional edge-to-edge sidebar. Metrics from the kit.
local theme = require("glass.theme")
local core = require("glass.core")
local material = require("glass.material")
local overlay = require("glass.overlay")
local toolbar = require("glass.chrome.toolbar")
local sig = require("glass.internal.toggles").sig

local c, CLEAR = theme.c, theme.CLEAR
local merge, text, icon = core.merge, core.text, core.icon

local M = {}

M.active = core.active
local ON = theme.dark:map(function() return true end)

-- Chrome per toolbar style: bar height, traffic-light origin, toolbar item size, the sidebar
-- toggle (size, y in the toolbar, y in the sidebar) and where the sidebar's list starts.
-- not in the kit: the toggle's y in the titlebar style (centred).
local CHROME = {
    titlebar = { height = 33, lights = { 9, 9.5 }, toggle = { 24, 4.5, 4.5 } },
    compact = { height = 40, lights = { 13, 13 }, item = 24, toggle = { 24, 8, 8 } },
    unified = { height = 52, lights = { 18, 19 }, item = 36, toggle = { 36, 8, 8 } },
    expanded = { height = 77, bar = 33, lights = { 9, 9.5 }, item = 36, toggle = { 36, 33, 32 }, list = 76 },
}
local UTILITY = { radius = 15, header = 24, tabs_header = 56, lights = { 8, 8 }, tab = { 44, 28 }, tab_top = 23 }
-- Resizable panes, 256 wide as in the kit. not in the kit: the drag ranges, as native apps.
local PANE = {
    sidebar = { default = 256, min = 180, max = 400 },
    inspector = { default = 256, min = 200, max = 400 },
}
local GRAB = 6

-- Window drop shadows: a wide ambient one and a 1 px rim. Dark without
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
local UTILITY_BAND = { left = 33, right = 33, top = 17, bottom = 49 }
-- Utility panels: light has the one soft shadow; dark takes `active_tight` and `inactive`.
SHADOWS.utility = { { color = "#0000004C", offset = { x = 0, y = 5 }, blur = 20 } }

-- The band per side: none on a tiled side, none at all maximised or fullscreen.
local function band(s, b)
    if s.maximized or s.fullscreen then
        return 0
    end
    local t = s.tiled
    return {
        left = t.left and 0 or b.left,
        right = t.right and 0 or b.right,
        top = t.top and 0 or b.top,
        bottom = t.bottom and 0 or b.bottom,
    }
end

local function title_block(props, active)
    local title_color = theme.pick(active, "vibrant_label", "vibrant_tertiary_label")
    local kids = { text(props.title, title_color, props.sidebar and "sidebar_title" or "window_title", material.vibrant({})) }
    if props.subtitle then
        kids[2] = text(props.subtitle, c.vibrant_tertiary_label, "control_small", material.vibrant({}))
    end
    return column { align_v = "center", spacing = 2, children = kids }
end

-- A press on empty chrome moves the window; a right press opens the compositor's window menu.
-- Drag areas sit behind the chrome's controls, never around them, so a control's press stays its own.
-- An inline preview (no `id`) has none.
local function drag_area(id)
    return rect {
        width = "fill",
        height = "fill",
        on_press = id and function(_, button)
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

-- The soft edge's blur, faded out top to bottom. The kit's r100 is past what a crossfade keeps
-- legible, so it is less (not in the kit).
local SOFT_BLUR = 20
local SOFT_MASK = { gradient = "linear", angle = 180, stops = { { 0, "#FFFFFFFF" }, { 1, "#FFFFFF00" } } }

-- The band under the toolbar: "soft" fades the window's colour out,
-- "hard" is the window's colour over a blur, with a hairline.
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
        effect = { backdrop = { blur = SOFT_BLUR, mask = SOFT_MASK } },
    }
end


-- A side pane of glass: its box eases to its width (or to nothing) and the glass slides with it.
-- A drag on the divider resizes without the ease.
local function pane(p)
    local ease = computed({ p.dragging, theme.motion.smooth }, function(d, m) return d and {} or { width = m, translate = m } end)
    local away = p.right and 1 or -1
    return rect {
        height = "fill",
        clip = "box",
        width = computed({ p.shown, p.width }, function(on, px) return on and px or 0 end),
        animate = ease,
        children = {
            column(material.glass(material.by_activity("sidebar", p.active), {
                width = p.width,
                height = "fill",
                align_h = p.right and "end" or "start",
                translate = computed({ p.shown, p.width }, function(on, px) return { x = on and 0 or away * px } end),
                animate = ease,
                children = p.children,
            })),
        },
    }
end

-- A strip on a pane's edge that resizes it within its range: the width at the grab plus how far the
-- pointer has gone since, in surface coordinates.
local function divider(range, width, shown, dragging, right)
    local grab, from = 0, 0
    return rect {
        width = GRAB,
        height = "fill",
        align_h = right and "end" or "start",
        cursor = "ew-resize",
        visible = shown,
        on_drag = function(r, pointer, phase)
            local x = r.x + pointer.x
            if phase == "start" then
                grab, from = x, width:get()
                dragging:set(true)
            elseif phase == "move" then
                local next = from + (right and grab - x or x - grab)
                width:set(math.max(range.min, math.min(range.max, next)))
            else
                dragging:set(false)
            end
        end,
    }
end

-- Utility panel tabs: 44x28 buttons in a row, the selected one on small glass.
local function utility_tabs(id, props, active)
    local tab = props.tab or state("glass_win_" .. id .. "_tab", props.tabs[1].value or props.tabs[1].label)
    local kids = {}
    for i, item in ipairs(props.tabs) do
        local key = item.value or item.label
        local selected = tab:map(function(v) return v == key end)
        local button = {
            width = UTILITY.tab[1],
            height = UTILITY.tab[2],
            radius = theme.CAPSULE,
            accessible_name = item.label,
            on_click = function() tab:set(key) end,
            children = {
                rect(material.glass(material.by_activity("small", active), {
                    width = "fill",
                    height = "fill",
                    radius = theme.CAPSULE,
                    hittable = false,
                    opacity = selected:map(function(on) return on and 1 or 0 end),
                    animate = { opacity = theme.motion.fade },
                })),
                icon(item.icon, theme.pick(computed({ selected, active }, function(s, a) return s and a end), "vibrant_accent", "vibrant_secondary_label"), 16,
                    material.vibrant({ align_h = "center" })),
            },
        }
        core.focusable("glass_win_" .. id .. "_tab_" .. i, button)
        kids[i] = rect(core.shape(button))
    end
    return row { height = UTILITY.tab[2], margin = { top = UTILITY.tab_top }, align_h = "center", children = kids }
end

-- The body of a utility panel: a 24 px titlebar, or a 56 px toolbar with tabs, over the content.
local function utility_body(props, active, lights)
    local id = props.id
    local tabs = props.tabs
    local head = {
        rect {
            width = "fill",
            height = UTILITY.header,
            children = {
                text(props.title, theme.pick(active, "vibrant_label", "vibrant_tertiary_label"), "control_small",
                    material.vibrant({ align_h = "center", letter_spacing = 0 })),
            },
        },
    }
    if tabs then
        head[2] = utility_tabs(id, props, active)
    end
    return rect {
        width = "fill",
        height = "fill",
        background = c.window_background,
        children = {
            column {
                width = "fill",
                height = "fill",
                children = {
                    rect {
                        width = "fill",
                        height = tabs and UTILITY.tabs_header or UTILITY.header,
                        border_width = tabs and { bottom = 1 } or nil,
                        border_color = tabs and { bottom = c.chrome_border } or nil,
                        children = { drag_area(not props.preview and id or nil), table.unpack(head) },
                    },
                    rect { width = "fill", height = "fill", children = { props.child } },
                },
            },
            rect { margin = { left = UTILITY.lights[1], top = UTILITY.lights[2] }, children = { lights } },
        },
    }
end

local CHROME_PROPS = {
    subtitle = true, toolbar = true, leading = true, trailing = true, scroll_edge = true, sidebar = true, child = true,
    sidebar_shown = true, inspector = true, inspector_shown = true, inspector_width = true, kind = true, tabs = true,
    tab = true, preview = true, active = true,
}

-- The chrome fields, shared by `app_window` and the inline `window_frame`.
---@class glass.WindowFrameProps
---@field id string Names the window and the state of its panes; unique per frame.
---@field title? string|Signal<string>
---@field subtitle? string|Signal<string>
---@field toolbar? "unified"|"compact"|"titlebar"|"expanded" Default "unified"; "expanded" is a 33 titlebar over a 44 toolbar row.
---@field kind? "window"|"utility" Default "window"; "utility" is a 15 px panel with 10 px lights and no toolbar styles.
---@field leading? Node[] Toolbar nodes left of the title (the toolbar row's left end when expanded).
---@field trailing? Node[] Toolbar nodes right of the title.
---@field scroll_edge? "soft"|"hard" Default "soft" fade; "hard" is a blurred band with a hairline.
---@field sidebar? Node The glass pane at the left, 256 px by default; its edge drags between 180 and 400.
---@field sidebar_shown? StateSignal<boolean> Default its own, shown. Collapsing slides the pane away and the traffic lights and a toggle join the toolbar.
---@field inspector? Node The glass pane at the right (not in the kit: mirrors the sidebar).
---@field inspector_shown? StateSignal<boolean> Default its own, shown.
---@field inspector_width? number Opening width, default 256; its edge drags between 200 and 400.
---@field tabs? { icon: string, label: string, value?: string }[] A utility panel's toolbar with tabs.
---@field tab? StateSignal<string> The selected tab's value (else label); default the first.
---@field child? Node The content, which scrolls under the floating toolbar.
---@field on_close? fun()
---@field preview? boolean Inline preview: no window behind it, so no drag, menu or focus; looks active unless `active` says otherwise.
---@field active? boolean|Signal<boolean> Overrides the window's focus.

-- The framed window `app_window` puts in its surface: chrome, panes, content, rounded and shadowed.
-- It needs no window, so it also draws inline as a preview (`preview = true`).
---@param props glass.WindowFrameProps
---@return Node
function M.window_frame(props)
    local id, preview = props.id, props.preview
    local utility = props.kind == "utility"
    local active = props.active ~= nil and sig(props.active) or (preview and ON or M.active(id))
    local lights = toolbar.traffic_lights({ on_close = props.on_close, window = id, active = active, kind = props.kind })
    local has_sidebar = props.sidebar ~= nil and not utility
    local has_inspector = props.inspector ~= nil and not utility
    local grab_id = not preview and id or nil
    local body
    if utility then
        body = utility_body(props, active, lights)
    else
        local style = CHROME[props.toolbar or "unified"]
        local expanded = style.bar ~= nil
        local shown = props.sidebar_shown or state("glass_win_" .. id .. "_sidebar", true)
        local lights_end = style.lights[1] + 68 + 12
        local tw = style.toggle[1] + 8
        local size = style.toggle[1] == 24 and "medium" or "xl"
        local function toggle(name)
            return toolbar.sidebar_toggle("glass_win_" .. id .. "_" .. name, { shown = shown, size = size, active = active })
        end
        -- The first toolbar row's left padding: past the lights and toggle while the sidebar is away.
        local function inset(first, extra)
            if not has_sidebar then
                return { left = first, right = 8 }
            end
            return shown:map(function(on) return { left = on and 8 or first + extra, right = 8 } end)
        end
        local function items(first, last)
            local list = {}
            for _, node in ipairs(first) do list[#list + 1] = node end
            for _, node in ipairs(last) do list[#list + 1] = node end
            return list
        end
        local title = title_block(props, active)
        local bar
        if expanded then
            local lead = items({}, props.leading or {})
            lead[#lead + 1] = rect { width = "fill" }
            bar = column {
                width = "fill",
                height = style.height,
                children = {
                    row { width = "fill", height = style.bar, padding = inset(lights_end, 0), animate = { padding = theme.motion.smooth }, children = { title } },
                    row {
                        width = "fill",
                        height = style.height - style.bar,
                        align_v = "start",
                        spacing = 8,
                        padding = inset(8, tw),
                        animate = { padding = theme.motion.smooth },
                        children = items(lead, props.trailing or {}),
                    },
                },
            }
        else
            local lead = items(props.leading or {}, { title })
            lead[#lead + 1] = rect { width = "fill" }
            bar = row {
                width = "fill",
                height = style.height,
                spacing = 8,
                padding = inset(lights_end, tw),
                animate = { padding = theme.motion.smooth },
                children = items(lead, props.trailing or {}),
            }
        end
        local sidebar_w = has_sidebar and state("glass_win_" .. id .. "_sidebar_w", PANE.sidebar.default) or nil
        local sidebar_drag = has_sidebar and state("glass_win_" .. id .. "_sidebar_drag", false) or nil
        local inspector_shown = has_inspector and (props.inspector_shown or state("glass_win_" .. id .. "_inspector", true)) or nil
        local inspector_w = has_inspector and state("glass_win_" .. id .. "_inspector_w", props.inspector_width or PANE.inspector.default) or nil
        local inspector_drag = has_inspector and state("glass_win_" .. id .. "_inspector_drag", false) or nil
        -- The content runs under the toolbar; the scroll edge keeps the bar legible over it.
        local content = rect {
            width = "fill",
            height = "fill",
            background = c.window_background,
            children = {
                rect { width = "fill", height = "fill", padding = { top = style.height }, children = { props.child } },
                scroll_edge(props.scroll_edge, style.height + 1),
                rect { width = "fill", height = style.height, children = { drag_area(grab_id) } },
                bar,
            },
        }
        local panes = { content }
        if has_sidebar then
            table.insert(panes, 1, pane {
                shown = shown,
                width = sidebar_w,
                dragging = sidebar_drag,
                active = active,
                children = {
                    rect {
                        width = "fill",
                        height = style.list or style.height,
                        children = {
                            drag_area(grab_id),
                            rect { align_h = "end", margin = { top = style.toggle[3], right = 8 }, children = { toggle("sidebar_toggle") } },
                        },
                    },
                    props.sidebar,
                },
            })
            content.children[#content.children + 1] = rect {
                margin = { left = expanded and 8 or lights_end, top = style.toggle[2] },
                visible = shown:map(function(on) return not on end),
                opacity = shown:map(function(on) return on and 0 or 1 end),
                animate = { opacity = theme.motion.fade },
                children = { toggle("toolbar_toggle") },
            }
            content.children[#content.children + 1] = divider(PANE.sidebar, sidebar_w, shown, sidebar_drag, false)
        end
        if has_inspector then
            panes[#panes + 1] = pane {
                right = true,
                shown = inspector_shown,
                width = inspector_w,
                dragging = inspector_drag,
                active = active,
                children = {
                    rect { width = "fill", height = style.list or style.height, children = { drag_area(grab_id) } },
                    props.inspector,
                },
            }
            content.children[#content.children + 1] = divider(PANE.inspector, inspector_w, inspector_shown, inspector_drag, true)
        end
        body = rect {
            width = "fill",
            height = "fill",
            children = {
                row { width = "fill", height = "fill", children = panes },
                rect { margin = { left = style.lights[1], top = style.lights[2] }, children = { lights } },
            },
        }
    end
    local window_state = not preview and toplevel(id):state() or nil
    local R = utility and UTILITY.radius or theme.WINDOW_RADIUS
    -- Square the corners the window shares with a screen edge or a neighbour, and all of them maximised.
    return rect(core.shape {
        width = "fill",
        height = "fill",
        radius = window_state and window_state:map(function(s)
            local t = s.tiled
            if s.maximized or s.fullscreen then
                return 0
            end
            return {
                top_left = (t.top or t.left) and 0 or R,
                top_right = (t.top or t.right) and 0 or R,
                bottom_right = (t.bottom or t.right) and 0 or R,
                bottom_left = (t.bottom or t.left) and 0 or R,
            }
        end) or R,
        clip = "rounded",
        border_width = 1,
        border_color = c.window_border,
        shadows = computed({ active, theme.dark }, function(on, dark)
            if utility and not dark then
                return SHADOWS.utility
            end
            if not on then
                return SHADOWS.inactive
            end
            return dark and (utility or not has_sidebar) and SHADOWS.active_tight or SHADOWS.active
        end),
        geometry = not preview and overlay.bounds(id) or nil,
        children = preview and { body } or overlay.root(body, id),
    })
end

-- An app window in Liquid Glass chrome: any `window` field plus the chrome fields of `window_frame`.
---@class glass.AppWindowProps: WindowProps, glass.WindowFrameProps
---@field preview? nil

---@param props glass.AppWindowProps
---@return Surface
function M.app_window(props)
    local own = {}
    for k, v in pairs(props) do
        if not CHROME_PROPS[k] then
            own[k] = v
        end
    end
    local id = props.id
    local grips = resize_grips(id)
    table.insert(grips, 1, M.window_frame(props))
    local inset = toplevel(id):state():map(function(s) return band(s, props.kind == "utility" and UTILITY_BAND or BAND) end)
    return window(merge({
        background = CLEAR,
        decorations = "client",
        geometry_inset = inset,
        on_escape = function() overlay.escape(id) end,
        on_key = function(key) return overlay.key(id, key) end,
        child = rect {
            width = "fill",
            height = "fill",
            padding = inset,
            children = { rect { width = "fill", height = "fill", children = grips } },
        },
    }, own))
end

-- A utility panel: `app_window` with `kind = "utility"` (280 wide in the kit).
---@param props glass.AppWindowProps
---@return Surface
function M.utility_window(props)
    return M.app_window(merge({ kind = "utility" }, props))
end

return M
