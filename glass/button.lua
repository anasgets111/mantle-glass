-- Liquid Glass push buttons and the arrow button, from docs/spec/buttons.md.
local theme = require("glass.theme")
local core = require("glass.core")
local buttons = require("glass.internal.buttons")

local text, icon = core.text, core.icon

local M = {}

-- Push button.
---@class glass.ButtonOpts: glass.ControlOpts
---@field kind? "bordered"|"default"|"destructive"|"default_destructive"|"tinted"|"borderless"|"toggle" Default "bordered".
---@field label? string|Signal<string>
---@field icon? string|Signal<string> Leading Lucide name; alone makes a square.
---@field value? StateSignal<boolean> Selected state; a `toggle` keeps its own if omitted.
---@field on_click? fun()
---@field name? string Accessible name; default the label, else the icon.
---@field props? table Extra node props.
---@field [string] "no such property"

---@param id string
---@param opts? glass.ButtonOpts
---@return Node
function M.button(id, opts)
    opts = opts or {}
    local kind, size = opts.kind or "bordered", theme.SIZES[opts.size or "regular"]
    local on_click = opts.on_click
    local value = opts.value
    if kind == "toggle" then
        value = value or state("glass_toggle_" .. id, false)
        on_click = function()
            value:set(not value:get())
            if opts.on_click then
                opts.on_click()
            end
        end
    end
    local icon_only = opts.icon and not opts.label
    return buttons.control(id, {
        size = opts.size,
        kind = kind,
        on_glass = opts.on_glass,
        window = opts.window,
        disabled = opts.disabled,
        on = value,
        -- not in the kit: an icon-only push button is a square of the control's height
        width = icon_only and size.height or nil,
        padding = not icon_only and { left = size.inset, right = size.inset } or nil,
        -- not in the kit: Regular destructive is 5; every other size follows the sizes table
        radius = kind == "destructive" and (opts.size or "regular") == "regular" and 5 or nil,
        name = opts.name or (type(opts.label) == "string" and opts.label) or opts.icon,
        on_click = on_click,
        -- not in the kit: 4 px between glyph and label (the kit's label starts with an SF symbol and a space)
        props = core.merge({ spacing = 4, align_h = "center" }, opts.props),
    }, function(label)
        local vib = buttons.vibrant({ kind = kind, on_glass = opts.on_glass })
        local kids = {}
        if opts.icon then
            kids[1] = icon(opts.icon, label, size.icon, vib)
        end
        if opts.label then
            kids[#kids + 1] = text(opts.label, label, size.label, vib)
        end
        return kids
    end)
end

-- Arrow button: the kit's icon-only capsule, a chevron.up.chevron.down square of the control's
-- height.
---@class glass.ArrowButtonOpts: glass.ControlOpts
---@field icon? string|Signal<string> Default "chevrons-up-down".
---@field on_click? fun()
---@field name? string
---@field props? table
---@field [string] "no such property"

---@param id string
---@param opts? glass.ArrowButtonOpts
---@return Node
function M.arrow_button(id, opts)
    opts = opts or {}
    local size = theme.SIZES[opts.size or "regular"]
    return buttons.control(id, {
        size = opts.size,
        kind = "plain",
        on_glass = opts.on_glass,
        disabled = opts.disabled,
        window = opts.window,
        width = size.height,
        radius = theme.CAPSULE,
        name = opts.name or "Arrows",
        on_click = opts.on_click,
        props = opts.props,
    }, function(label)
        local vib = buttons.vibrant({ kind = "plain", on_glass = opts.on_glass })
        return { rect { width = size.height, height = size.height, children = {
            icon(opts.icon or "chevrons-up-down", label, opts.size == "mini" and 11 or 13, core.merge({ align_h = "center" }, vib)),
        } } }
    end)
end

return M
