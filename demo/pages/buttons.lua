-- Buttons: push buttons, icon buttons, arrow, pop-up, pull-down, colour wells, toolbar groups.
local section = require("demo.section")
local glass = require("glass")

local c = glass.theme.c
local on_wall = section.on_wall

-- Every cell is as tall as the biggest control, so controls of any size share a centre line and caption row.
local CELL = 36
local function labelled(caption, node, height)
    return section.labelled(caption, rect { height = height or CELL, children = { row { align_v = not height and "center" or nil, children = { node } } } })
end

local KINDS = { "bordered", "default", "destructive", "default_destructive", "tinted", "borderless" }
local SIZES = { "mini", "small", "regular", "large", "xl" }
local FRUITS = { "Apple", "Banana", "Cherry", "Dragonfruit" }

local function line(children) return row { spacing = 16, align_v = "start", children = children } end

local function each(list, make)
    local out = {}
    for i, v in ipairs(list) do out[i] = make(v) end
    return out
end

local kinds = each(KINDS, function(kind)
    return labelled(kind, glass.button("kind_" .. kind, { kind = kind, label = "Button" }))
end)
kinds[#kinds + 1] = labelled("toggle", glass.button("kind_toggle", { kind = "toggle", label = "Toggle", value = state("demo_buttons_toggle", false) }))
kinds[#kinds + 1] = labelled("disabled", glass.button("kind_disabled", { label = "Button", disabled = true }))

local sizes = each(SIZES, function(size)
    return labelled(size, glass.button("size_" .. size, { kind = "default", size = size, label = "Save", icon = "save" }))
end)

local icons = each(SIZES, function(size)
    return labelled(size, glass.button("icon_" .. size, { size = size, icon = "plus" }))
end)

local arrows = each(SIZES, function(size)
    return labelled(size, glass.arrow_button("arrow_" .. size, { size = size }))
end)

local picked = state("demo_buttons_fruit", "Apple")
local last_action = state("demo_buttons_action", "none")
local menus = {
    labelled("pop-up", glass.popup_button("popup", { items = FRUITS, value = picked, width = 120 })),
    labelled("pop-up, small", glass.popup_button("popup_small", { items = FRUITS, size = "small", width = 100 })),
    labelled("pull-down", glass.pull_down_button("pull", {
        label = "Actions",
        items = {
            { label = "Copy", on_click = function() last_action:set("Copy") end },
            { label = "Paste", on_click = function() last_action:set("Paste") end },
            { label = "Delete", on_click = function() last_action:set("Delete") end },
        },
    })),
    labelled("pop-up, disabled", glass.popup_button("popup_off", { items = FRUITS, disabled = true, width = 100 })),
    labelled("selection", glass.text(picked, c.label, "body")),
    labelled("last action", glass.text(last_action, c.label, "body")),
}

local wells = {}
for i, size in ipairs({ "small", "regular", "large", "xl" }) do
    wells[i] = labelled(size, glass.color_well("well_" .. size, { size = size, value = state("demo_buttons_well_" .. size, glass.theme.SYSTEM[({ "red", "orange", "blue", "purple" })[i]][1]) }))
end
wells[#wells + 1] = labelled("selected", glass.color_well("well_sel", { selected = true }))
wells[#wells + 1] = labelled("disabled", glass.color_well("well_off", { disabled = true }))

local glass_kinds = each({ "bordered", "default", "tinted", "borderless" }, function(kind)
    return glass.button("wall_" .. kind, { kind = kind, label = kind, on_glass = true })
end)

local function noop() end
local toolbars = {
    glass.toolbar_group("tb_xl", { items = { { icon = "chevron-left", label = "Back", on_click = noop }, { icon = "chevron-right", label = "Forward", on_click = noop } } }),
    glass.toolbar_group("tb_xl3", { items = { { icon = "share", label = "Share", on_click = noop }, { icon = "tag", label = "Tag", on_click = noop }, { icon = "star", label = "Favourite", on_click = noop, selected = state("demo_buttons_fav", true) } } }),
    glass.toolbar_group("tb_med", { size = "medium", items = { { icon = "bold", label = "Bold", on_click = noop }, { icon = "italic", label = "Italic", on_click = noop }, { icon = "underline", label = "Underline", on_click = noop } } }),
    glass.toolbar_button("tb_one", { icon = "plus", label = "Add", on_click = noop }),
}

return section.page {
    section.section("Push buttons", "Every kind at regular size; toggle keeps its own state.", line(kinds)),
    section.section("Sizes", "Mini to extra large, with a leading symbol.", line(sizes)),
    section.section("Icon buttons", "Icon-only push buttons are a square of the control's height.", line(icons)),
    section.section("Arrow button", "The chevron capsule used next to fields.", line(arrows)),
    section.section("Pop-up and pull-down", "A pop-up shows its selection; a pull-down runs an action.", line(menus)),
    section.section("Colour wells", "A swatch in a capsule; the well reads its colour from state.", line(wells)),
    section.section("Over glass", "Buttons on a wallpaper use the vibrant blend (on_glass).", on_wall({ section.glass_pane({
        row { spacing = 16, children = glass_kinds },
        row { spacing = 16, children = {
            glass.popup_button("wall_popup", { items = FRUITS, width = 120, on_glass = true }),
            glass.arrow_button("wall_arrow", { on_glass = true }),
            glass.color_well("wall_well", {}),
        } },
    }) }, 200)),
    section.section("Toolbar groups", "Glass capsules of toolbar buttons, as in the window's toolbar.", on_wall({ row { spacing = 24, align_v = "center", children = toolbars } }, 100)),
}
