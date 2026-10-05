-- Liquid Glass search field, from docs/spec/overlays.md (4.3 of foundations.md for the toolbar).
local theme = require("glass.theme")
local core = require("glass.core")
local fields = require("glass.internal.fields")
local buttons = require("glass.internal.buttons")

local c = theme.c
local icon = core.icon

local M = {}

-- Magnifier x, text x, magnifier glyph and clear button's right inset, per size. The toolbar
-- variant is 24 or 36 tall and sets them by foundations.md 4.3.
local SIZES = {
    mini = { 6, 26, 11, 2 },
    small = { 6, 30, 12.2, 2.5 },
    regular = { 8, 32, 12.2, 4 },
    large = { 8, 32, 12.2, 6 },
    xl = { 10, 34, 12.2, 8 },
}
local TOOLBAR = {
    regular = { 6, 26, 13, 6, 149 },
    xl = { 10, 32, 13, 10, 159 },
}

-- Search field: a capsule with a magnifier, a clear button once it holds text. opts: size,
-- width (default 120; toolbar 149 or 159), value (state of the text), placeholder ("Search"),
-- disabled, toolbar (sits on small glass in a toolbar; size "regular" or "xl"), max_length,
-- on_change(text), on_submit(text), name, props. Returns the node and { value, focus() }.
function M.search_field(id, opts)
    opts = opts or {}
    local size = opts.size or "regular"
    local g = opts.toolbar and TOOLBAR[size] or SIZES[size]
    local input, handle = fields.input(id, core.merge({
        escape = "clear",
        vibrant = true,
        placeholder = "Search",
        name = "Search",
    }, opts))
    local held_props = {}
    local disabled = buttons.signal(opts.disabled or false)
    local filled = handle.value:map(function(v) return (v or "") ~= "" end)
    local held = core.pressable("clear_" .. id, held_props)
    core.focusable("clear_" .. id, held_props)
    local function tone(rest, down)
        return computed({ theme.scheme, disabled, held }, function(p, off, pressed)
            return p[off and "vibrant_tertiary_label" or pressed and down or rest]
        end)
    end
    return fields.box(id, {
        size = size,
        width = opts.width or g[5] or 120,
        padding = { left = g[1], right = g[4] },
        disabled = opts.disabled,
        focus = handle.focus,
        glass = opts.toolbar,
        props = opts.props,
    }, {
        rect { width = g[2] - g[1], height = "fill", children = {
            icon("search", tone("vibrant_label"), g[3], { align_v = "center" }),
        } },
        input,
        rect(core.merge(held_props, {
            width = 16,
            height = 16,
            radius = 8,
            align_v = "center",
            accessible_name = "Clear",
            visible = computed({ filled, disabled }, function(on, off) return on and not off end),
            on_click = function()
                if not disabled:get() then
                    handle.value:set("")
                    handle.focus()
                end
            end,
            children = { icon("circle-x", tone("vibrant_secondary_label", "vibrant_label"), g[3], { align_h = "center" }) },
        })),
    }), handle
end

return M
