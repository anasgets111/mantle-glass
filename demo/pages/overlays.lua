-- Menus & popovers: menus, pop-up and pull-down buttons in context, popovers, alerts, a sheet,
-- tooltips and notifications. Each opener is a glass.button.
local section = require("demo.section")
local glass = require("glass")

local c = glass.theme.c
local labelled = section.labelled

local last = state("demo_overlays_last", "nothing yet")
local show_toolbar = state("demo_overlays_toolbar", true)
local suppress = state("demo_overlays_suppress", false)
local name_value = state("demo_overlays_name", "Untitled")
local share_on = state("demo_overlays_share", true)

local function say(what) return function() last:set(what) end end

-- A button that opens something under itself: `open(anchor)` gets the button's geometry signal.
local function opener(id, label, open, opts)
    local anchor = geometry("demo_overlays_" .. id)
    return glass.button(id, glass.merge({
        label = label,
        props = { geometry = anchor },
        on_click = function() open(anchor) end,
    }, opts))
end

local function line(children) return row { spacing = 16, align_v = "center", children = children } end

local MENU = {
    { header = "File" },
    { label = "New Window", icon = "app-window", shortcut = "⌘N", on_click = say("New Window") },
    { label = "Open…", icon = "folder-open", shortcut = "⌘O", on_click = say("Open") },
    { label = "Open Recent", icon = "history", submenu = {
        { label = "Report.pdf", on_click = say("Report.pdf") },
        { label = "Notes.txt", on_click = say("Notes.txt") },
        { label = "Budget.xlsx", on_click = say("Budget.xlsx") },
    } },
    { separator = true },
    { label = "Show Toolbar", checked = show_toolbar:get(), on_click = function() show_toolbar:set(not show_toolbar:get()) end },
    { label = "Save", icon = "save", shortcut = "⌘S", disabled = true },
    { separator = true },
    { label = "Close", icon = "x", shortcut = "⌘W", on_click = say("Close") },
}

glass.bind_shortcuts(MENU)

local function open_file_menu(anchor)
    MENU[6].checked = show_toolbar:get()
    glass.open_menu { anchor = anchor, items = MENU, id = "file" }
end

local menus = line {
    opener("menu_file", "File menu", open_file_menu),
    opener("menu_end", "Aligned to the end", function(anchor)
        glass.open_menu { anchor = anchor, items = MENU, width = 200, align = "end" }
    end),
    labelled("last pick", glass.text(last, c.label, "body")),
}

local context = line {
    glass.context_menu("area", {
        items = function()
            return {
                { label = "Get Info", icon = "info", shortcut = "⌘I", on_click = say("Get Info") },
                { label = "Rename", on_click = say("Rename") },
                { separator = true },
                { label = "Copy", icon = "copy", shortcut = "⌘C", on_click = say("Copy") },
                { label = "Move to Trash", icon = "trash-2", on_click = say("Move to Trash") },
            }
        end,
        child = rect(glass.shape {
            width = 320,
            height = 96,
            radius = 12,
            background = c.quaternary_fill,
            border_width = 1,
            border_color = c.separator,
            children = { glass.text("Right-click anywhere in here", c.secondary_label, "body", { align_h = "center" }) },
        }),
    }),
    labelled("last pick", glass.text(last, c.label, "body")),
}

local FRUITS = { "Apple", "Banana", "Cherry" }
local pop_in_context = glass.group_box("ctx", {
    title = "Export",
    content = column {
        spacing = 10,
        children = {
            row { spacing = 12, align_v = "center", children = {
                glass.text("Format", c.label, "body"),
                glass.popup_button("ctx_format", { items = { "PNG", "JPEG", "TIFF", "PDF" }, width = 100 }),
                glass.text("Fruit", c.label, "body"),
                glass.popup_button("ctx_fruit", { items = FRUITS, width = 100 }),
            } },
            row { spacing = 12, align_v = "center", children = {
                glass.pull_down_button("ctx_pull", { label = "Share", width = 100, items = {
                    { label = "Mail", icon = "mail", on_click = say("Mail") },
                    { label = "Chat", icon = "message-circle", on_click = say("Chat") },
                    { separator = true },
                    { label = "Copy Link", icon = "link", on_click = say("Copy Link") },
                } }),
                glass.button("ctx_export", { kind = "default", label = "Export" }),
            } },
        },
    },
})

local function popover(edge)
    return opener("pop_" .. edge, edge, function(anchor)
        glass.open_popover {
            anchor = anchor,
            edge = edge,
            width = 220,
            content = column { spacing = 8, padding = 16, children = {
                glass.text("Opens " .. edge, c.label, "headline"),
                glass.text("A popover points at the control that opened it.", c.secondary_label, "body", { wrap = "word", width = "fill" }),
                glass.button("pop_" .. edge .. "_ok", { kind = "default", label = "Got it", on_click = function() glass.overlay.close("glass_popover") end }),
            } },
        }
    end)
end

local popovers = rect {
    width = "fill",
    height = 200,
    children = { column { align_h = "center", align_v = "center", spacing = 40, children = {
        popover("top"),
        row { spacing = 160, children = { popover("left"), popover("right") } },
        popover("bottom"),
    } } },
}

local function edge_row(align, children) return row { width = "fill", spacing = 16, align_h = align, children = children } end
local edge = column { width = "fill", spacing = 280, children = {
    edge_row("end", {
        opener("edge_pop", "Popover to the right", function(anchor)
            glass.open_popover {
                anchor = anchor,
                edge = "right",
                width = 220,
                content = column { spacing = 8, children = {
                    glass.text("Flipped", c.label, "headline"),
                    glass.text("No room on the right, so it opens on the left.", c.secondary_label, "body", { wrap = "word", width = "fill" }),
                } },
            }
        end),
        opener("edge_menu", "Menu at the edge", open_file_menu),
    }),
    edge_row("start", {
        opener("edge_menu_low", "Menu at the bottom", open_file_menu),
        opener("edge_pop_low", "Popover below", function(anchor)
            glass.open_popover { anchor = anchor, width = 220, content = glass.text("No room below, so it opens above.", c.label, "body", { wrap = "word", width = "fill" }) }
        end),
    }),
} }

local alerts = line {
    opener("alert_two", "Alert", function()
        glass.open_alert {
            icon = "triangle-alert",
            title = "Delete 3 items?",
            message = "This can't be undone.",
            buttons = {
                { label = "Cancel", on_click = say("Cancelled") },
                { label = "Delete", kind = "destructive", on_click = say("Deleted") },
            },
        }
    end),
    opener("alert_three", "Three buttons", function()
        glass.open_alert {
            icon = "save",
            title = "Save changes?",
            message = "Your changes will be lost if you don't save them.",
            buttons = {
                { label = "Save", kind = "default", on_click = say("Saved") },
                { label = "Don't Save", kind = "destructive", on_click = say("Discarded") },
                { label = "Cancel", on_click = say("Cancelled") },
            },
            suppression = { label = "Do not ask again", value = suppress },
        }
    end),
    labelled("suppressed", glass.text(suppress:map(function(v) return v and "yes" or "no" end), c.label, "body")),
}

local function sheet_form(close)
    return column { width = "fill", spacing = 16, children = {
        glass.text("New Document", c.label, "headline", { font_size = 14 }),
        glass.form_section("sheet_form", { rows = {
            glass.form_row("sheet_name", { label = "Name", control = true, trailing = (glass.text_field("sheet_name_field", { value = name_value, width = 160 })) }),
            glass.form_row("sheet_share", { label = "Share with team", control = true, trailing = glass.switch("sheet_share_sw", { value = share_on }) }),
        } }),
        row { spacing = 8, align_h = "end", children = {
            glass.button("sheet_cancel", { label = "Cancel", on_click = close }),
            glass.button("sheet_create", { kind = "default", label = "Create", on_click = function() close(); say("Created " .. name_value:get())() end }),
        } },
    } }
end

local sheets = line {
    opener("sheet", "Show sheet", function() glass.open_sheet { content = sheet_form, width = 390 } end),
    labelled("name", glass.text(name_value, c.label, "body")),
}

local function tip(id, label, child) return glass.tooltip(id, { label = label, child = child }) end
local tooltips = line {
    tip("t_plus", "Add an item", glass.button("tt_plus", { icon = "plus" })),
    tip("t_share", "Share this document", glass.button("tt_share", { icon = "share", label = "Share" })),
    tip("t_star", "Mark as favourite", glass.button("tt_star", { kind = "tinted", icon = "star" })),
    tip("t_sw", "Turns the feature on or off", glass.switch("tt_switch", {})),
}

local notifications = line {
    glass.button("notify", {
        kind = "default",
        label = "Show notification",
        on_click = function() glass.open_notification { title = "Build finished", body = "mantle-glass compiled with no warnings.", icon = "check", app = "Mantle" } end,
    }),
}

return section.page {
    section.section("Menus", "Icons, shortcuts, a checkmark, separators, a header, a disabled item and a submenu. Its shortcuts work with Ctrl standing for ⌘: try Ctrl+N.", menus),
    section.section("Context menu", "Opens at the pointer on a right click.", context),
    section.section("Pop-up and pull-down", "In context: a pop-up picks a value, a pull-down runs an action.", pop_in_context),
    section.section("Popovers", "Open on any edge of the control.", popovers),
    section.section("Alerts", "Two buttons side by side, then three stacked with a suppression checkbox.", alerts),
    section.section("Sheet", "A modal panel with a small form.", sheets),
    section.section("Tooltips", "Rest the pointer on a control.", tooltips),
    section.section("Notifications", "A banner at the top right.", notifications),
    section.section("Near the edge", "A menu, submenu or popover that would run past the window flips or slides to stay inside it. The ones on the left sit at the bottom.", edge, { wide = true }),
}
