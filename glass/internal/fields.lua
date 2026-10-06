-- Shared by text_field.lua, search_field.lua and combo_box.lua: the kit's input box (fill, border,
-- focus ring) and the engine textfield inside it.
local theme = require("glass.theme")
local core = require("glass.core")
local material = require("glass.material")
local buttons = require("glass.internal.buttons")
local menu = require("glass.overlays.menu")

local M = {}

-- Text fields per size: corner radius, text size and text inset (heights are `theme.SIZES`).
M.SIZES = {
    mini = { radius = 4, font = 10, inset = 6, type = "control_mini" },
    small = { radius = 5, font = 11, inset = 6, type = "control_small" },
    regular = { radius = 6, font = 13, inset = 6, type = "control" },
    large = { radius = 7, font = 13, inset = 8, type = "control" },
    xl = { radius = 9, font = 13, inset = 10, type = "control" },
}

-- Text, placeholder and disabled roles; `vibrant` is the search field's set.
local ROLES = {
    plain = { "label", "tertiary_label", "tertiary_label" },
    vibrant = { "vibrant_label", "vibrant_secondary_label", "vibrant_tertiary_label" },
}

-- The engine textfield. o: size, value (state), placeholder, disabled, max_length, vibrant, name,
-- on_change, on_submit, and for several lines multiline, min_lines, max_lines, submit_key.
-- Returns the node and { value, focus() }.
function M.input(id, o)
    local style = theme.type[M.SIZES[o.size or "regular"].type]
    local name = "glass_field_" .. id
    local value = o.value or state(name, "")
    local target = focus_target(name)
    local selected = has_selection(name)
    local disabled = buttons.signal(o.disabled or false)
    local roles = ROLES[o.vibrant and "vibrant" or "plain"]
    local draft = value:get() or ""
    local kept = false
    -- A write from outside (a menu pick, a clear button) reaches the engine's draft here.
    value:on_change(function(v)
        if v ~= draft then
            draft = v
            target:set_text(v)
        end
    end)
    local function role(i)
        return computed({ theme.scheme, disabled }, function(p, off) return p[roles[off and 3 or i]] end)
    end
    local node = textfield {
        width = "fill",
        height = not o.multiline and "fill" or nil,
        multiline = o.multiline,
        min_lines = o.min_lines,
        max_lines = o.max_lines,
        submit_key = o.submit_key,
        font = theme.FONT,
        font_size = M.SIZES[o.size or "regular"].font,
        font_weight = style[2],
        letter_spacing = style[4],
        line_height = o.multiline and style[3] / style[1] or nil,
        foreground = role(1),
        placeholder = o.placeholder,
        placeholder_color = role(2),
        caret = { color = theme.c.accent, width = 2, radius = 1 },
        -- not in the kit: native fields tint a key window's selection with the accent, else greys it.
        selection = {
            background = computed({ core.active(o.window), theme.scheme, theme.dark }, function(on, p, dark)
                return on and theme.alpha(p.accent, dark and 0.45 or 0.3) or p.inactive_selected_fill
            end),
        },
        -- native: Escape belongs to the window (it closes the sheet or popover); search fields clear.
        escape = o.escape or "pass",
        initial_text = value,
        disabled = disabled,
        max_length = o.max_length,
        accessible_name = o.name or o.placeholder or id,
        focus_ring = false,
        focus_target = target,
        -- The native Edit menu on a right click; Cut and Copy need a selection.
        on_click = function(r, button, p)
            if button ~= "right" or disabled:get() then
                return
            end
            target:request()
            local function act(verb)
                return function()
                    target:request()
                    target[verb](target)
                end
            end
            local has = selected:get()
            menu.open_menu({
                at = { x = r.x + p.x, y = r.y + p.y },
                id = "edit_" .. id,
                window = o.window,
                items = {
                    { label = "Cut", shortcut = "⌘X", disabled = not has, on_click = act("cut") },
                    { label = "Copy", shortcut = "⌘C", disabled = not has, on_click = act("copy") },
                    { label = "Paste", shortcut = "⌘V", on_click = act("paste") },
                    { separator = true },
                    { label = "Select All", shortcut = "⌘A", on_click = act("select_all") },
                },
            })
        end,
        on_change = function(t)
            if kept and t == "" then
                kept = false
                return
            end
            kept = false
            draft = t
            value:set(t)
            if o.on_change then
                o.on_change(t)
            end
        end,
        -- Enter clears the engine's draft, with an on_change(""); a field keeps its text.
        on_submit = function(t)
            if o.on_submit then
                o.on_submit(t)
            end
            kept = t ~= ""
            target:set_text(t)
        end,
    }
    return node, { value = value, focus = function() target:request() end }
end

-- The input box: a row of `children` with the kit's fill, 1 px outside border and focus ring (3.5
-- px outside and 1 px inside, accent at 50%). o: size, width, padding, disabled, focus (the
-- `focus` of `input`), glass (sits on `material.glass("small")`: the toolbar search), geometry,
-- grow (the height follows a multiline field instead of the control size).
function M.box(id, o, children)
    local disabled = buttons.signal(o.disabled or false)
    local focus = focused("glass_focus_" .. id)
    local size = o.size or "regular"
    local props = {
        id = id,
        width = o.width,
        height = not o.grow and theme.SIZES[size].height or nil,
        radius = o.glass and theme.CAPSULE or M.SIZES[size].radius,
        padding = o.padding,
        align_v = o.grow and "start" or "center",
        focused = focus,
        geometry = o.geometry,
        on_click = function()
            if not disabled:get() and o.focus then
                o.focus()
            end
        end,
        border_width = focus:map(function(on) return on and 1 or 0 end),
        border_color = theme.scheme:map(function(p) return theme.alpha(p.accent, 0.5) end),
        children = children,
    }
    local function ring(p) return { { color = theme.alpha(p.accent, 0.5), spread = 3.5 } } end
    if o.glass then
        material.glass("small", props, {
            shadows = computed({ focus, theme.scheme }, function(on, p) return on and ring(p) or {} end),
        })
    else
        props.background = computed({ theme.scheme, theme.dark, disabled }, function(p, dark, off)
            return off and theme.alpha(p.input_background, dark and 0.25 or 0.5) or p.input_background
        end)
        props.shadows = computed({ focus, theme.scheme, disabled }, function(on, p, off)
            return on and ring(p) or { { color = off and "#0000000A" or p.input_border, spread = 1 } }
        end)
    end
    return row(core.shape(core.merge(props, o.props)))
end

return M
