-- Liquid Glass on Mantle: every control of the glass library, page by page, in a Liquid Glass window.
-- Run: mantle -c /mnt/Work/1Progs/glass-demo
fonts { "Inter", "lucide", "Noto Sans", "Noto Color Emoji" }

local glass = require("glass")

local theme, overlay = glass.theme, glass.overlay

local PAGES = {
    { name = "buttons", label = "Buttons", icon = "square-mouse-pointer", page = "demo.pages.buttons" },
    { name = "toggles", label = "Toggles", icon = "toggle-right", page = "demo.pages.toggles" },
    { name = "sliders", label = "Sliders & Progress", icon = "sliders-horizontal", page = "demo.pages.sliders" },
    { name = "inputs", label = "Text Input", icon = "text-cursor-input", page = "demo.pages.inputs" },
    { name = "overlays", label = "Menus & Popovers", icon = "panel-top", page = "demo.pages.overlays" },
    { name = "lists", label = "Lists & Forms", icon = "list", page = "demo.pages.lists" },
    { name = "materials", label = "Materials", icon = "layers", page = "demo.pages.materials" },
    { name = "style", label = "Colour & Type", icon = "palette", page = "demo.pages.style" },
}
local BUILT, ITEMS = {}, {}
for i, entry in ipairs(PAGES) do
    BUILT[entry.name] = require(entry.page)
    ITEMS[i] = { name = entry.name, label = entry.label, icon = entry.icon }
end

local stored = state("glass_page", "buttons")
local page = stored:map(function(name) return BUILT[name] and name or "buttons" end)
stored:on_change(overlay.close_all)

local body = page:map(function(name)
    return {
        column {
            id = name,
            width = "fill",
            height = "fill",
            scroll = scroll("glass_scroll_" .. name),
            opacity = 1,
            animate = { scroll = theme.motion.smooth, opacity = { duration = 200, from = 0 } },
            children = { BUILT[name] },
        },
    }
end)

local function toggle_dark() theme.dark:set(not theme.dark:get()) end

local function next_accent()
    local now = theme.accent:get()
    for i, name in ipairs(theme.ACCENTS) do
        if name == now then
            return theme.accent:set(theme.ACCENTS[i % #theme.ACCENTS + 1])
        end
    end
    theme.accent:set(theme.ACCENTS[1])
end

-- Dev hook for screenshots: `mantle call peek <page> <offset>`.
action("peek", function(name, offset)
    stored:set(name)
    scroll("glass_scroll_" .. name):scroll_to(tonumber(offset) or 0)
end)

local TITLES = {}
for _, entry in ipairs(PAGES) do TITLES[entry.name] = entry.label end

return {
    glass.app_window {
        id = "glass",
        title = page:map(function(name) return TITLES[name] end),
        subtitle = "Liquid Glass on Mantle",
        app_id = "mantle-glass-demo",
        min_size = { width = 1100, height = 760 },
        on_close = function() process.detach("mantle", { "stop", "--pid", tostring(mantle.pid) }) end,
        sidebar = glass.sidebar("nav", { value = stored, window = "glass", sections = { { header = "Controls", items = ITEMS } } }),
        trailing = {
            glass.toolbar_group("look", {
                window = "glass",
                items = {
                    { icon = "palette", label = "Next accent colour", on_click = next_accent },
                    { icon = theme.dark:map(function(d) return d and "sun" or "moon" end), label = "Toggle appearance", on_click = toggle_dark },
                },
            }),
        },
        child = rect { width = "fill", height = "fill", children = body },
    },
}
