-- Windows & toolbars: every chrome style as an inline `window_frame` preview, the navigation group,
-- sidebar collapse, the inspector and the utility panel.
local section = require("demo.section")
local glass = require("glass")

local c = glass.theme.c

local W, H = 560, 320
local inactive = glass.theme.dark:map(function() return false end)

-- A frame on the wallpaper, so its shadow and glass have something to show.
local function stage(frame, width)
    return rect(glass.shape {
        width = (width or W) + 40,
        height = H + 40,
        radius = 12,
        clip = "rounded",
        children = {
            image { source = section.WALL, width = "fill", height = "fill", fit = "cover" },
            rect { width = width or W, height = H, margin = 20, children = { frame } },
        },
    })
end

local function cell(caption, frame, width)
    return section.labelled(caption, stage(frame, width))
end

local function wrap(children) return row { width = "fill", wrap = true, spacing = 24, line_spacing = 24, children = children } end

local function body(heading)
    return column {
        width = "fill",
        padding = glass.theme.CONTENT_INSET,
        spacing = 8,
        children = {
            glass.text(heading, c.label, "title3"),
            glass.text("Content scrolls under the floating toolbar.", c.secondary_label, "body"),
            glass.text("The scroll edge keeps the bar legible over it.", c.secondary_label, "body"),
        },
    }
end

local function sidebar(id, active)
    return glass.sidebar("pv_sb_" .. id, {
        active = active,
        sections = { { header = "Library", items = {
            { name = "photos", label = "Photos", icon = "images" },
            { name = "albums", label = "Albums", icon = "folder" },
            { name = "people", label = "People", icon = "users" },
        } } },
    })
end

local function tool(id, icon, label, props)
    return glass.toolbar_button("pv_" .. id, glass.merge({ icon = icon, label = label }, props))
end

-- A preview window: `extra` overrides the defaults.
local function frame(id, title, extra)
    local off = extra and extra.active == false
    local props = {
        id = "pv_" .. id,
        title = title,
        preview = true,
        child = body(title),
        trailing = { tool(id .. "_share", "share", "Share", { active = off and inactive or nil, size = extra and (extra.toolbar == "compact" or extra.toolbar == "titlebar") and "medium" or nil }) },
    }
    return glass.window_frame(glass.merge(props, extra))
end

local function nav(id, extra)
    return glass.toolbar_navigation("pv_nav_" .. id, glass.merge({ can_forward = false, size = id:find("compact") and "medium" or nil }, extra))
end

local STYLES = {
    { "titlebar", "Titlebar, 33" },
    { "compact", "Compact toolbar, 40" },
    { "unified", "Unified toolbar, 52" },
    { "expanded", "Expanded toolbar, 33 + 44" },
}
local styles = {}
for i, entry in ipairs(STYLES) do
    local name = entry[1]
    styles[i] = cell(entry[2], frame("style_" .. name, "Photos", {
        toolbar = name,
        scroll_edge = name == "expanded" and "hard" or nil,
        leading = name ~= "titlebar" and { nav("style_" .. name) } or nil,
    }))
end

-- Sidebar collapse: one shared state drives both previews and the button.
local shown = state("demo_windows_sidebar", true)
local inspector = state("demo_windows_inspector", true)

local function sidebar_frame(id, toolbar, extra)
    return frame(id, "Photos", glass.merge({
        toolbar = toolbar,
        sidebar = sidebar(id, extra and extra.active == false and inactive or nil),
        sidebar_shown = state("demo_windows_sb_" .. id, true),
    }, extra))
end

local function toggler(id, label, value)
    return glass.button("pv_btn_" .. id, { label = label, on_click = function() value:set(not value:get()) end })
end

local utility_tab = state("demo_windows_utility_tab", "general")
local utility_tabs = {
    { icon = "settings", label = "General", value = "general" },
    { icon = "palette", label = "Appearance", value = "appearance" },
    { icon = "users", label = "Accounts", value = "accounts" },
    { icon = "bell", label = "Alerts", value = "alerts" },
    { icon = "shield", label = "Privacy", value = "privacy" },
}

return section.page {
    section.wide("Toolbar styles", "Titlebar, compact, unified and expanded; items are 24 high in compact and 36 elsewhere. Expanded puts the title over a second row.", wrap(styles)),
    section.section("Navigation group", "A 73x36 glass capsule; a button dims while it cannot go.", section.on_wall({
        section.labelled("both", glass.toolbar_navigation("nav_a", {})),
        section.labelled("no forward", glass.toolbar_navigation("nav_b", { can_forward = false })),
        section.labelled("none", glass.toolbar_navigation("nav_c", { can_back = false, can_forward = false })),
        section.labelled("inactive", glass.toolbar_navigation("nav_d", { active = inactive })),
        section.labelled("medium", glass.toolbar_navigation("nav_e", { size = "medium" })),
    }, 110)),
    section.wide("Sidebar toggle and collapse", "The toggle sits at the pane's trailing edge; collapsing slides the pane away and the lights and toggle move into the toolbar. Drag the pane's edge to resize (180 to 400).", wrap({
        cell("unified", frame("collapse_unified", "Photos", { sidebar = sidebar("collapse_unified"), sidebar_shown = shown, leading = { nav("collapse_unified") } })),
        cell("compact", sidebar_frame("collapse_compact", "compact")),
        cell("expanded", sidebar_frame("collapse_expanded", "expanded")),
        cell("titlebar", sidebar_frame("collapse_titlebar", "titlebar")),
        section.labelled("drive the first from outside", toggler("collapse", "Toggle sidebar", shown)),
    })),
    section.section("Inspector", "A trailing glass pane, 256 wide, with its own draggable edge (200 to 400).", wrap({
        cell("sidebar and inspector", frame("inspector", "Photos", {
            sidebar = sidebar("inspector"),
            inspector = column { width = "fill", padding = 12, spacing = 8, children = {
                glass.text("Inspector", c.label, "headline"),
                glass.text("Details of the selection.", c.secondary_label, "body"),
            } },
            inspector_shown = inspector,
            trailing = { glass.toolbar_button("pv_inspector_toggle", { icon = "panel-right", label = "Toggle inspector", on_click = function() inspector:set(not inspector:get()) end }) },
        }), 720),
    })),
    section.section("Inactive window", "Without the keyboard the chrome greys and the shadow weakens.", wrap({
        cell("expanded, inactive", sidebar_frame("inactive", "expanded", { active = false })),
    })),
    section.wide("Utility panel", "A 15 px panel with 10 px lights on a 17 px pitch: a 24 px titlebar, or a 56 px toolbar with tabs whose selected tab is small glass.", wrap({
        cell("titlebar", glass.window_frame({ id = "pv_utility", kind = "utility", preview = true, title = "Inspector", child = body("Utility") }), 280),
        cell("toolbar with tabs", glass.window_frame({
            id = "pv_utility_tabs", kind = "utility", preview = true, title = "Settings", tabs = utility_tabs, tab = utility_tab, child = body("Tabs"),
        }), 280),
        cell("inactive", glass.window_frame({ id = "pv_utility_off", kind = "utility", preview = true, title = "Inspector", active = false, tabs = utility_tabs, child = body("Utility") }), 280),
    })),
}
