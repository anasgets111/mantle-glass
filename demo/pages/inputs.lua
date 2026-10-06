-- Text input: text fields, text views, search fields and combo boxes.
local section = require("demo.section")
local glass = require("glass")

local c = glass.theme.c
local material = glass.material
local on_wall = section.on_wall

local notes = state("demo_inputs_notes", "Line one\nLine two")
local draft = state("demo_inputs_draft", "")
local sent = state("demo_inputs_sent", "")

-- Every cell is as tall as the biggest control, so controls of any size share a centre line and caption row.
local CELL = 36
local function labelled(caption, node, height)
    return section.labelled(caption, rect { height = height or CELL, children = { row { align_v = not height and "center" or nil, children = { node } } } })
end

local SIZES = { "mini", "small", "regular", "large", "xl" }
local FRUITS = { "Apple", "Banana", "Cherry", "Dragonfruit" }

local function line(children) return row { spacing = 16, align_v = "start", children = children } end

local function each(list, make)
    local out = {}
    for i, v in ipairs(list) do out[i] = make(v) end
    return out
end

local name = state("demo_inputs_name", "")
local query = state("demo_inputs_query", "")
local fruit = state("demo_inputs_fruit", "")

local fields = each(SIZES, function(size)
    return labelled(size, (glass.text_field("tf_" .. size, { size = size, placeholder = "Text", value = state("demo_inputs_tf_" .. size, "") })))
end)

local searches = each(SIZES, function(size)
    return labelled(size, (glass.search_field("sf_" .. size, { size = size, value = state("demo_inputs_sf_" .. size, "") })))
end)

local combos = each({ "small", "regular", "large" }, function(size)
    return labelled(size, (glass.combo_box("cb_" .. size, { size = size, items = FRUITS, width = 140, placeholder = "Fruit", value = state("demo_inputs_cb_" .. size, "") })))
end)

return section.page {
    section.section("Text fields", "Click and type; the readout follows.", column { spacing = 16, children = {
        line({
            labelled("placeholder", (glass.text_field("tf", { value = name, placeholder = "Name", width = 200 }))),
            labelled("you typed", glass.text(name:map(function(v) return v == "" and "nothing" or v end), c.secondary_label, "body")),
            labelled("filled", (glass.text_field("tf_filled", { value = state("demo_inputs_filled", "Hello"), width = 160 }))),
            labelled("disabled", (glass.text_field("tf_off", { value = state("demo_inputs_off", "Disabled"), disabled = true, width = 160 }))),
            labelled("disabled, empty", (glass.text_field("tf_off_empty", { value = state("demo_inputs_off_e", ""), placeholder = "Placeholder", disabled = true, width = 160 }))),
        }),
        line(fields),
    } }),
    section.section("Search fields", "A capsule with a magnifier; a clear button appears once it holds text.", column { spacing = 16, children = {
        line({
            labelled("search", (glass.search_field("sf", { value = query, width = 200 }))),
            labelled("query", glass.text(query:map(function(v) return v == "" and "empty" or v end), c.secondary_label, "body")),
            labelled("disabled", (glass.search_field("sf_off", { value = state("demo_inputs_sf_off", ""), disabled = true, width = 160 }))),
        }),
        line(searches),
    } }),
    section.section("Toolbar search", "The variant that sits on small glass in a window toolbar.", on_wall({
        row(material.glass("small", { radius = glass.theme.CAPSULE, padding = 4, children = { (glass.search_field("tb_sf", { toolbar = true, size = "xl", width = 159 })) } })),
        row(material.glass("small", { radius = glass.theme.CAPSULE, padding = 4, children = { (glass.search_field("tb_sf_r", { toolbar = true, size = "regular", width = 149 })) } })),
    }, 100)),
    section.section("Combo boxes", "A text field with a menu of suggestions; picking one fills the field.", column { spacing = 16, children = {
        line({
            labelled("regular", (glass.combo_box("cb", { items = FRUITS, value = fruit, width = 160, placeholder = "Fruit" }))),
            labelled("value", glass.text(fruit:map(function(v) return v == "" and "empty" or v end), c.secondary_label, "body")),
            labelled("disabled", (glass.combo_box("cb_off", { items = FRUITS, value = state("demo_inputs_cb_off", "Apple"), width = 160, disabled = true }))),
        }),
        line(combos),
    } }),
    section.section("Text views", "Several lines that grow to a limit, then scroll. Return breaks the line and Ctrl+Return sends; the chat one sends on Return.", column { spacing = 16, children = {
        (glass.text_view("tv_notes", { value = notes, placeholder = "Notes", min_lines = 3, max_lines = 6 })),
        line({
            labelled("chat", column { width = 320, spacing = 6, children = {
                (glass.text_view("tv_chat", {
                    value = draft,
                    placeholder = "Message",
                    min_lines = 1,
                    max_lines = 4,
                    submit_key = "return",
                    on_submit = function(t)
                        if t:match("%S") then
                            sent:set(t)
                            draft:set("")
                        end
                    end,
                })),
            } }),
            labelled("last sent", glass.text(sent:map(function(t) return t == "" and "nothing yet" or t end), c.secondary_label, "body", { wrap = "word", width = 280 })),
        }),
    } }),
}
