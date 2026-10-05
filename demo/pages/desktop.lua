-- Menu bar & Dock: the desktop's own chrome over a wallpaper. In a shell they live in panels.
local section = require("demo.section")
local glass = require("glass")

local c = glass.theme.c

local last = state("demo_desktop_last", "nothing yet")
local function say(what) return function() last:set(what) end end

local function items(names)
    local out = {}
    for i, name in ipairs(names) do
        out[i] = name == "-" and { separator = true } or { label = name, on_click = say(name) }
    end
    return out
end

local clock = mantle.system:map(function(s)
    local t = s and s.time or 0
    return os.date("%a ", t) .. tonumber(os.date("%d", t)) .. os.date(" %b  %H:%M", t)
end)

local bar = glass.menu_bar("demo", {
    menus = {
        { icon = "command", title = "System", items = items({ "About This Computer", "System Settings…", "-", "Sleep", "Restart…", "Shut Down…" }) },
        { title = "Files", bold = true, items = items({ "About Files", "-", "Settings…", "-", "Empty Trash…" }) },
        { title = "File", items = items({ "New Window", "New Folder", "-", "Get Info", "Rename" }) },
        { title = "Edit", items = items({ "Undo", "Redo", "-", "Cut", "Copy", "Paste", "Select All" }) },
        { title = "View", items = items({ "as Icons", "as List", "as Columns", "as Gallery" }) },
        { title = "Go", items = items({ "Back", "Forward", "-", "Home", "Downloads" }) },
        { title = "Window", items = items({ "Minimise", "Zoom", "-", "Bring All to Front" }) },
        { title = "Help", items = items({ "Files Help" }) },
    },
    trailing = {
        glass.icon("wifi", "#FFFFFF", 15),
        glass.icon("battery-full", "#FFFFFF", 15),
        glass.icon("search", "#FFFFFF", 15),
        glass.text(clock, "#FFFFFF", "control", { font_weight = 600 }),
    },
})

local dock = glass.dock("demo", {
    items = {
        { label = "Files", icon = "smile", color = "blue", running = true, on_click = say("Files") },
        { label = "Firefox", icon = "compass", color = "cyan", running = true, on_click = say("Firefox") },
        { label = "Mail", icon = "mail", color = "blue", on_click = say("Mail") },
        { label = "Chat", icon = "message-circle", color = "green", running = true, on_click = say("Chat") },
        { label = "Music", icon = "music", color = "pink", on_click = say("Music") },
        { label = "Photos", icon = "flower-2", color = "orange", on_click = say("Photos") },
        { label = "Notes", icon = "notebook-pen", color = "yellow", on_click = say("Notes") },
        { label = "Settings", icon = "settings", color = "gray", running = true, on_click = say("Settings") },
        { separator = true },
        { label = "Downloads", icon = "download", color = "teal", on_click = say("Downloads") },
        { label = "Trash", icon = "trash-2", color = "gray", on_click = say("Trash") },
    },
})

local desktop = rect(glass.shape {
    width = "fill",
    height = 560,
    radius = 12,
    clip = "rounded",
    children = {
        image { source = section.WALL, width = "fill", height = "fill", fit = "cover" },
        column { width = "fill", children = { bar } },
        rect { align_h = "center", align_v = "end", margin = { bottom = 8 }, children = { dock } },
    },
})

return section.page {
    section.wide("Desktop", "A transparent menu bar whose menus switch as the pointer moves along it, and the Dock with running dots.",
        column { width = "fill", spacing = 12, children = {
            desktop,
            section.labelled("last pick", glass.text(last, c.label, "body")),
        } }),
}
