-- Liquid Glass push buttons, the icon button and the arrow button, from the kit.
local theme = require("glass.theme")
local core = require("glass.core")
local buttons = require("glass.internal.buttons")

local text, icon = core.text, core.icon

local M = {}

-- Push button.
---@class glass.ButtonOpts: glass.ControlOpts
---@field kind? "primary"|"secondary"|"plain"|"destructive"|"tinted"|"default_destructive"|"toggle" Default "secondary".
---@field label? string|Signal<string>
---@field icon? string|Signal<string> Leading shared icon name or Lucide name; alone makes a square.
---@field value? StateSignal<boolean> Makes it a toggle: a click flips it. A `toggle` kind keeps its own state if omitted.
---@field width? number Fixed width.
---@field on_click? fun() Called after the toggle flips.
---@field name? string Accessible name; default the label, else the icon.
---@field props? table Extra node props.
---@field [string] "no such property"

---@param id string
---@param opts? glass.ButtonOpts
---@return Node
function M.button(id, opts)
    opts = opts or {}
    local kind, size = opts.kind or "secondary", theme.SIZES[opts.size or "m"]
    local on_click = opts.on_click
    local value = opts.value
    if kind == "toggle" or value then
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
        width = opts.width or icon_only and size.height or nil,
        padding = not icon_only and { left = size.inset, right = size.inset } or nil,
        -- not in the kit: Regular destructive is 5; every other size follows the sizes table
        radius = kind == "destructive" and (opts.size or "m") == "m" and 5 or nil,
        name = opts.name or (type(opts.label) == "string" and opts.label) or opts.icon,
        on_click = on_click,
        -- not in the kit: 4 px between glyph and label (the kit's label starts with an SF symbol and a space)
        props = core.merge({ spacing = 4 }, opts.props),
    }, function(label)
        local vib = buttons.vibrant({ kind = kind, on_glass = opts.on_glass })
        local kids = {}
        if opts.icon then
            kids[1] = icon(opts.icon, label, size.icon, vib)
        end
        if opts.label then
            kids[#kids + 1] = text(opts.label, label, size.label, vib)
        end
        -- A fixed width centres the content with a spacer each side: a row's `align_h` would also
        -- centre the button itself in its parent.
        if opts.width or icon_only then
            table.insert(kids, 1, rect { width = "fill" })
            kids[#kids + 1] = rect { width = "fill" }
        end
        return kids
    end)
end

-- Icon button: a button with a glyph and no label, a square of the control's height.
---@class glass.IconButtonOpts: glass.ControlOpts
---@field kind? "primary"|"secondary"|"plain"|"destructive"|"tinted"|"default_destructive"|"toggle" Default "secondary".
---@field icon string|Signal<string> A shared icon name or a Lucide name.
---@field value? StateSignal<boolean> Makes it a toggle: a click flips it.
---@field width? number Fixed width; default the control's height, a square.
---@field name? string Accessible name; default the icon.
---@field on_click? fun() Called after the toggle flips.
---@field props? table Extra node props.
---@field [string] "no such property"

---@param id string
---@param opts glass.IconButtonOpts
---@return Node
function M.icon_button(id, opts)
    return M.button(id, core.merge(core.merge({}, opts), { label = false }))
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
    local size = theme.SIZES[opts.size or "m"]
    return buttons.control(id, {
        size = opts.size,
        kind = "bezel",
        on_glass = opts.on_glass,
        disabled = opts.disabled,
        window = opts.window,
        width = size.height,
        radius = theme.CAPSULE,
        name = opts.name or "Arrows",
        on_click = opts.on_click,
        props = opts.props,
    }, function(label)
        local vib = buttons.vibrant({ kind = "bezel", on_glass = opts.on_glass })
        return { rect { width = size.height, height = size.height, children = {
            icon(opts.icon or "chevrons-up-down", label, opts.size == "xs" and 11 or 13, core.merge({ align_h = "center" }, vib)),
        } } }
    end)
end

return M
