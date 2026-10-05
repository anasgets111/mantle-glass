-- Lists & forms: grouped forms, a group box, disclosure groups and a selectable list.
local section = require("demo.section")
local glass = require("glass")

local c = glass.theme.c

local wifi = state("demo_lists_wifi", true)
local bluetooth = state("demo_lists_bluetooth", false)
local airdrop = state("demo_lists_airdrop", "Contacts Only")
local volume = state("demo_lists_volume", 5)
local device = state("demo_lists_device", "Laptop")
local picked = state("demo_lists_selected", "Mail")
local open_a = state("demo_lists_open_a", true)
local open_b = state("demo_lists_open_b", false)
local open_c = state("demo_lists_open_c", false)

local function sw(id, value) return glass.switch(id, { value = value }) end

local network = glass.form_section("net", {
    header = "Network",
    footer = "Known networks are joined automatically.",
    rows = {
        glass.form_row("wifi", { icon = "wifi", label = "Wi-Fi", control = true, trailing = sw("wifi_sw", wifi) }),
        glass.form_row("bt", { icon = "bluetooth", label = "Bluetooth", subtitle = "Not connected", trailing = sw("bt_sw", bluetooth) }),
        glass.form_row("airdrop", { icon = "radio", label = "Nearby sharing", control = true, trailing = glass.popup_button("airdrop_pop", {
            items = { "No One", "Contacts Only", "Everyone" }, value = airdrop, width = 130,
        }) }),
    },
})

local sound = glass.form_section("snd", {
    header = "Sound",
    rows = {
        glass.form_row("vol", { icon = "volume-2", label = "Alert volume", control = true, trailing = row { spacing = 8, align_v = "center", children = {
            glass.text(volume:map(tostring), c.secondary_label, "body"),
            glass.stepper("vol_step", { value = volume, min = 0, max = 10 }),
        } } }),
        glass.form_row("dev", { label = "Device name", control = true, trailing = (glass.text_field("dev_field", { value = device, width = 160 })) }),
        glass.form_row("plain", { label = "A plain row", subtitle = "Rows without an icon or control are 40 high, 56 with a subtitle" }),
        glass.form_row("tap", { icon = "info", label = "A clickable row", on_click = function() picked:set("Info") end }),
    },
})

local box = column { width = 620, children = { glass.group_box("box", {
    title = "Group box",
    content = column { spacing = 6, children = {
        glass.text("Related content shares one quaternary-filled box.", c.label, "body"),
        glass.text("The title sits above it, like an NSBox.", c.secondary_label, "callout"),
        row { spacing = 8, children = {
            glass.button("box_a", { label = "Reset" }),
            glass.button("box_b", { kind = "default", label = "Apply" }),
        } },
    } },
}) } }

local function note(msg) return glass.text(msg, c.secondary_label, "body") end
local disclosures = column { spacing = 8, width = "fill", children = {
    glass.disclosure_group("dg_a", { label = "General", value = open_a, content = column { spacing = 4, children = {
        note("Starts expanded."), note("Content slides in place."),
    } } }),
    glass.disclosure_group("dg_b", { label = "Advanced", value = open_b, content = column { spacing = 8, children = {
        note("Groups nest."),
        glass.disclosure_group("dg_c", { label = "Experimental", value = open_c, content = note("Three levels deep.") }),
    } } }),
} }

local APPS = {
    { label = "Mail", icon = "mail" }, { label = "Calendar", icon = "calendar" }, { label = "Notes", icon = "notebook-pen" },
    { label = "Photos", icon = "image" }, { label = "Music", icon = "music" }, { label = "Maps", icon = "map" },
    { label = "Chat", icon = "message-circle" }, { label = "Weather", icon = "cloud-sun" },
}
local picker = column { width = 620, spacing = 8, children = {
    glass.list("apps", {
        items = APPS,
        value = picked,
        alternating = true,
        max_height = 210,
    }),
    glass.text(picked:map(function(v) return "Selected: " .. v end), c.label, "headline"),
} }

return section.page {
    section.section("Forms", "Inset sections: icons, subtitles, switches, pop-ups, steppers and text fields as trailing controls.", column {
        width = 620, spacing = 20, children = { network, sound },
    }),
    section.section("Group box", "A box around related controls.", box),
    section.section("Disclosure groups", "A chevron and label that reveal content in place.", disclosures),
    section.section("List", "Selection is an inset accent fill with white text; every other row is tinted. Scrolling shows the overlay knob.", picker),
}
