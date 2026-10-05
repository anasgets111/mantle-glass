-- Tables: a sortable multi-select table, an outline and a tab view.
local section = require("demo.section")
local glass = require("glass")

local c, pick = glass.theme.c, glass.theme.pick

local picked = state("demo_tables_selected", { ["Notes.md"] = true })
local tree_picked = state("demo_tables_tree", {})
local tree_open = state("demo_tables_tree_open", { src = true, ["src/glass"] = true })

local FILES = {
    { name = "Desktop", kind = "Folder", size = 0, date = "2026-09-30", icon = "folder" },
    { name = "Documents", kind = "Folder", size = 0, date = "2026-10-01", icon = "folder" },
    { name = "Notes.md", kind = "Markdown", size = 4200, date = "2026-10-02", icon = "file-text" },
    { name = "Budget.xlsx", kind = "Spreadsheet", size = 182000, date = "2026-08-14", icon = "file-spreadsheet" },
    { name = "Holiday.jpg", kind = "JPEG image", size = 3400000, date = "2026-07-21", icon = "image" },
    { name = "Invoice.pdf", kind = "PDF document", size = 96000, date = "2026-09-05", icon = "file" },
    { name = "Slides.odp", kind = "Presentation", size = 24800000, date = "2026-06-30", icon = "presentation" },
    { name = "Mixtape.mp3", kind = "MP3 audio", size = 8700000, date = "2026-05-12", icon = "music" },
    { name = "Resume.docx", kind = "Word document", size = 58000, date = "2026-03-09", icon = "file-text" },
    { name = "backup.zip", kind = "ZIP archive", size = 412000000, date = "2026-09-28", icon = "archive" },
    { name = "script.sh", kind = "Shell script", size = 1300, date = "2026-10-04", icon = "terminal" },
    { name = "Screenshot.png", kind = "PNG image", size = 910000, date = "2026-10-03", icon = "image" },
    { name = "Trailer.mov", kind = "QuickTime movie", size = 143000000, date = "2026-04-18", icon = "film" },
    { name = "todo.txt", kind = "Plain text", size = 380, date = "2026-09-11", icon = "file-text" },
}

local function bytes(n)
    if n == 0 then
        return "--"
    end
    for _, u in ipairs { { 1e9, "GB" }, { 1e6, "MB" }, { 1e3, "KB" } } do
        if n >= u[1] then
            return string.format("%.1f %s", n / u[1], u[2])
        end
    end
    return n .. " bytes"
end

local function secondary(text, emphasized, align)
    return glass.text(text, pick(emphasized, "on_accent", "secondary_label"), "body", { width = "fill", elide = "end", text_align = align })
end

local files = glass.table("files", {
    items = FILES,
    value = picked,
    multiple = true,
    alternating = true,
    max_height = 336,
    sort = state("demo_tables_sort", { key = "name", ascending = true }),
    on_activate = function(f) log.info("open " .. f.name) end,
    columns = {
        { key = "name", title = "Name", width = 190, sortable = true, cell = function(f, e)
            return row { width = "fill", spacing = 6, align_v = "center", children = {
                glass.icon(f.icon, pick(e, "on_accent", "accent"), 13, {}),
                glass.text(f.name, pick(e, "on_accent", "label"), "body", { width = "fill", elide = "end" }),
            } }
        end },
        { key = "kind", title = "Kind", width = 140, sortable = true, cell = function(f, e) return secondary(f.kind, e) end },
        { key = "size", title = "Size", width = 90, align = "end", sortable = true, cell = function(f, e) return secondary(bytes(f.size), e, "end") end },
        { key = "date", title = "Date Modified", sortable = true, cell = function(f, e) return secondary(f.date, e) end },
    },
})

local summary = picked:map(function(set)
    local names = {}
    for name in pairs(set) do
        names[#names + 1] = name
    end
    table.sort(names)
    return #names == 0 and "Selected: nothing" or "Selected: " .. table.concat(names, ", ")
end)

local TREE = {
    { name = "src", icon = "folder", kind = "Folder", children = {
        { name = "main.lua", icon = "file-code", kind = "Lua" },
        { name = "glass", icon = "folder", kind = "Folder", children = {
            { name = "table.lua", icon = "file-code", kind = "Lua" },
            { name = "tab_view.lua", icon = "file-code", kind = "Lua" },
        } },
    } },
    { name = "docs", icon = "folder", kind = "Folder", children = {
        { name = "README.md", icon = "file-text", kind = "Markdown" },
        { name = "spec", icon = "folder", kind = "Folder", children = {
            { name = "tables.md", icon = "file-text", kind = "Markdown" },
        } },
    } },
    { name = "justfile", icon = "file", kind = "Text" },
}
local function with_keys(nodes, prefix)
    for _, n in ipairs(nodes) do
        n.key = prefix .. n.name
        if n.children then
            with_keys(n.children, n.key .. "/")
        end
    end
end
with_keys(TREE, "")

local tree = glass.outline("tree", {
    items = TREE,
    value = tree_picked,
    expanded = tree_open,
    max_height = 336,
    columns = {
        { key = "name", title = "Project", width = 300, cell = function(n, e)
            return row { width = "fill", spacing = 6, align_v = "center", children = {
                glass.icon(n.icon, pick(e, "on_accent", "accent"), 13, {}),
                glass.text(n.name, pick(e, "on_accent", "label"), "body", { width = "fill", elide = "end" }),
            } }
        end },
        { key = "kind", title = "Kind", cell = function(n, e) return secondary(n.kind, e) end },
    },
})

local function note(msg) return glass.text(msg, c.secondary_label, "body") end
local tabs = column { width = 460, children = { glass.tab_view("tabs", {
    height = 90,
    tabs = {
        { name = "general", label = "General", icon = "settings", content = note("General settings live here.") },
        { name = "appearance", label = "Appearance", icon = "palette", content = column { spacing = 8, children = {
            note("Pick a look."),
            glass.radio_group("tab_look", { options = { "Light", "Dark", "Auto" }, horizontal = true }),
        } } },
        { name = "advanced", label = "Advanced", content = note("Tabs build only while selected.") },
    },
}) } }

return section.page {
    section.wide("Table and outline", "Click sorts a column, a divider resizes it. Shift+Up/Down extends, Return opens, typing jumps to a name.", row { wrap = true, spacing = 24, children = {
        column { width = 700, spacing = 8, children = { files, glass.text(summary, c.label, "headline", { width = "fill", elide = "end" }) } },
        column { width = 520, spacing = 8, children = { tree, note("Left and Right collapse and expand.") } },
    } }),
    section.section("Tab view", "A segmented control over a group box; the content swaps in place.", tabs),
}
