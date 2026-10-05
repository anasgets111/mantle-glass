-- Liquid Glass alert and sheet, from docs/spec/overlays.md (Alerts, Dialogs). Both are window modal:
-- the kit's overlay dims the window and blocks it; an alert closes with its buttons or Escape.
local theme = require("glass.theme")
local core = require("glass.core")
local material = require("glass.material")
local overlay = require("glass.overlay")
local checkbox = require("glass.checkbox").checkbox

local c = theme.c
local text, icon = core.text, core.icon

local M = {}

local ALERT = {
    width = 260,
    radius = 26,
    padding = { top = 20, left = 16, right = 16, bottom = 16 },
    inset = 6, -- text inside the panel's padding
    gap = 14, -- text block to buttons
    button = { height = 28, gap = 6, side_gap = 8 },
    icon = { width = 84, height = 72 }, -- the 72 px app icon with a 6 px inset
    title_gap = 10,
}
-- The kit's window-modal overlay: light, dark.
local function dim() return theme.c.modal_dim end

local SHEET = { width = 390, radius = 26, padding = 20 }

---@type table
local spec = {}

-- kind: "default" (preferred, accent), "destructive", anything else is a plain cancel.
local function alert_button(i, b, on_close)
    local look = ({
        default = { fill = c.accent, label = c.on_accent },
        destructive = {
            fill = computed({ c.vibrant_red, theme.dark }, function(red, dark) return theme.alpha(red, dark and 0.25 or 0.23) end),
            label = c.vibrant_red,
        },
    })[b.kind] or { fill = c.vibrant_secondary_fill, label = c.label }
    local props = {
        id = "glass_alert_button" .. i,
        width = "fill",
        height = ALERT.button.height,
        radius = theme.CAPSULE,
        background = look.fill,
        accessible_name = b.label,
        on_click = function()
            on_close()
            if b.on_click then
                b.on_click()
            end
        end,
    }
    core.focusable("alert_" .. i, props)
    local held = core.pressable("alert_" .. i, props)
    props.opacity = held:map(function(h) return h and 0.7 or 1 end)
    props.animate = { opacity = theme.motion.fade }
    props.children = { text(b.label, look.label, "control", { align_h = "center" }) }
    return rect(core.shape(props))
end

overlay.layer("glass_alert", function()
    local buttons = {}
    local close = function() overlay.close("glass_alert") end
    for i, b in ipairs(spec.buttons or {}) do
        buttons[i] = alert_button(i, b, close)
    end
    -- Two buttons sit side by side, more stack.
    local actions = (#buttons == 2 and row or column) {
        width = "fill",
        spacing = #buttons == 2 and ALERT.button.side_gap or ALERT.button.gap,
        children = buttons,
    }
    local words = column {
        width = "fill",
        spacing = ALERT.title_gap,
        padding = { left = spec.icon and 0 or ALERT.inset, right = ALERT.inset },
        children = {
            text(spec.title, c.vibrant_label, "headline", material.vibrant({ width = "fill", wrap = "word" })),
            spec.message and text(spec.message, c.vibrant_label, "body", material.vibrant({ width = "fill", wrap = "word" })) or nil,
        },
    }
    local head = words
    if spec.icon then
        head = row { width = "fill", children = {
            rect { width = ALERT.icon.width, height = ALERT.icon.height, children = { icon(spec.icon, c.accent, 34, { align_h = "center", align_v = "center" }) } },
            words,
        } }
    end
    local kids = { head }
    if spec.suppression then
        -- not in the kit: the checkbox lines up with the text above it.
        kids[#kids + 1] = row {
            width = "fill",
            padding = { left = ALERT.inset + (spec.icon and ALERT.icon.width - ALERT.inset or 0) },
            children = { checkbox("alert_suppression", {
                label = spec.suppression.label or "Do not show this message again",
                value = spec.suppression.value,
                size = "small",
                on_glass = true,
            }) },
        }
    end
    kids[#kids + 1] = actions
    return rect {
        id = "glass_alert",
        width = "fill",
        height = "fill",
        background = dim(),
        opacity = 1,
        on_click = function() end,
        animate = { opacity = { duration = 150, from = 0 }, exit = { duration = 120, opacity = 0 } },
        children = { column(material.glass("large", {
            width = ALERT.width,
            radius = ALERT.radius,
            padding = ALERT.padding,
            spacing = ALERT.gap,
            align_h = "center",
            align_v = "center",
            opacity = 1,
            scale = 1,
            -- not in the kit: alerts scale up a little as they appear
            animate = { opacity = { duration = 150, from = 0 }, scale = theme.motion_with("snappy", { from = 1.06 }) },
            on_click = function() end,
            children = kids,
        })) },
    }
end, {
    -- Escape is the alert's Cancel: the first plain button, as in native apps.
    escape = function()
        overlay.close("glass_alert")
        for _, b in ipairs(spec.buttons or {}) do
            if b.kind ~= "default" and b.kind ~= "destructive" then
                if b.on_click then
                    b.on_click()
                end
                return
            end
        end
    end,
})

-- Alert: window modal; every button closes it, then runs its `on_click`.
---@class glass.AlertButton
---@field label string
---@field kind? "default"|"destructive"|string "default" is the preferred accent button, "destructive" red, anything else plain.
---@field on_click? fun()
---@field [string] "no such property"

---@class glass.AlertOpts
---@field icon? string Lucide name.
---@field title string
---@field message? string
---@field buttons? glass.AlertButton[] In the order shown.
---@field suppression? { label?: string, value?: StateSignal<boolean> } A "do not show again" checkbox.
---@field window? string The window or panel it opens over; default `core.window`.
---@field [string] "no such property"

---@param opts glass.AlertOpts
function M.open_alert(opts)
    spec = opts
    overlay.open("glass_alert", nil, opts.window)
end

overlay.layer("glass_sheet", function()
    local close = function() overlay.close("glass_sheet") end
    local content = type(spec.sheet.content) == "function" and spec.sheet.content(close) or spec.sheet.content
    return rect {
        id = "glass_sheet",
        width = "fill",
        height = "fill",
        background = dim(),
        opacity = 1,
        on_click = function() end,
        animate = { opacity = { duration = 150, from = 0 }, exit = { duration = 120, opacity = 0 } },
        children = { column(core.shape {
            width = spec.sheet.width or SHEET.width,
            radius = SHEET.radius,
            padding = SHEET.padding,
            align_h = "center",
            align_v = "center",
            background = c.window_background,
            border_width = 1,
            border_color = c.window_border,
            shadows = theme.dark:map(function(dark)
                return {
                    { color = "#00000066", offset = { x = 0, y = dark and 16 or 36 }, blur = dark and 33 or 100 },
                    { color = "#000000CC", blur = 1 },
                }
            end),
            opacity = 1,
            translate = { x = 0, y = 0 },
            -- not in the kit: sheets drop in from above
            animate = { opacity = { duration = 150, from = 0 }, translate = theme.motion_with("smooth", { from = { x = 0, y = -24 } }) },
            on_click = function() end,
            children = { content },
        }) },
    }
end)

-- Sheet: laid out with the kit's 20 px padding; close it with the given `close` or `overlay.close("glass_sheet")`.
---@class glass.SheetOpts
---@field content Node|fun(close: fun()): Node
---@field width? number Default 390.
---@field window? string The window or panel it opens over; default `core.window`.
---@field [string] "no such property"

---@param opts glass.SheetOpts
function M.open_sheet(opts)
    spec = { sheet = opts }
    overlay.open("glass_sheet", nil, opts.window)
end

return M
