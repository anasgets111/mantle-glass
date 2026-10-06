-- Disclosure: the kit's chevron button (a glyph swap between collapsed and expanded) and a
-- disclosure group, a chevron and label that open and close content in place.
local theme = require("glass.theme")
local core = require("glass.core")
local material = require("glass.material")
local tg = require("glass.internal.toggles")
local reveal = require("glass.internal.sidebar").reveal

local c, FADE = theme.c, theme.motion.fade

-- Glyph size per button size; the box and radius are `theme.SIZES`.
local GLYPH = { xs = 10, s = 10, m = 13, l = 13, xl = 13 }
local SLOT = { width = 18, height = 16 } -- the group's chevron slot, from the kit

local M = {}

-- Disclosure button.
---@class glass.DisclosureButtonOpts
---@field value? StateSignal<boolean> True = expanded.
---@field size? glass.Size
---@field disabled? boolean|Signal<boolean>
---@field on_glass? boolean
---@field name? string Accessible name.
---@field on_change? fun(expanded: boolean)
---@field [string] "no such property"

---@param id string
---@param opts? glass.DisclosureButtonOpts
---@return Node
function M.disclosure_button(id, opts)
    opts = opts or {}
    local size = opts.size or "m"
    local box = theme.SIZES[size]
    local n = tg.role(opts)
    local disabled = tg.sig(opts.disabled)
    ---@type StateSignal<boolean>
    local value = opts.value or state("glass_disclosure_" .. id, false)
    local props = { accessible_name = opts.name or id, width = box.height, height = box.height, radius = box.radius }
    local held, focused = tg.interact("disc_" .. id, props, opts, function()
        value:set(not value:get())
        if opts.on_change then
            opts.on_change(value:get())
        end
    end)
    -- not in the kit: over-glass is two layers (overlay + vibrant); one alpha stands in for both.
    local rest, down = opts.on_glass and 0.17 or 0.075, opts.on_glass and 0.25 or 0.16
    props.background = computed({ held, disabled, theme.scheme }, function(pressed, off, p)
        return theme.alpha(p.label, off and 0.04 or pressed and down or rest)
    end)
    props.shadows = tg.ring(focused)
    props.animate = { background = FADE }
    local glyph = computed({ disabled, theme.scheme }, function(off, p)
        return off and theme.alpha(p[n("label")], 0.25) or p[n("label")]
    end)
    props.children = {
        core.icon(value:map(function(v) return v and "chevron-down" or "chevron-up" end), glyph, GLYPH[size],
            material.vibrant({ align_h = "center" })),
    }
    return rect(core.shape(props))
end

-- Disclosure group.
---@class glass.DisclosureGroupOpts
---@field label? string|Signal<string>
---@field content? Node
---@field value? StateSignal<boolean> True = expanded.
---@field on_change? fun(expanded: boolean)
---@field [string] "no such property"

---@param id string
---@param opts? glass.DisclosureGroupOpts
---@return Node
function M.disclosure_group(id, opts)
    opts = opts or {}
    ---@type StateSignal<boolean>
    local value = opts.value or state("glass_disclosure_" .. id, false)
    local props = {
        height = SLOT.height,
        spacing = 0,
        accessible_name = opts.label,
        on_click = function()
            value:set(not value:get())
            if opts.on_change then
                opts.on_change(value:get())
            end
        end,
        children = {
            rect {
                width = SLOT.width,
                height = SLOT.height,
                children = {
                    core.icon(value:map(function(v) return v and "chevron-down" or "chevron-right" end), c.label, 13,
                        { align_v = "center" }),
                },
            },
            core.text(opts.label, c.label, "control"),
        },
    }
    core.focusable("dg_" .. id, props)
    local header = row(props)
    -- not in the kit: 8 px between the header and its content.
    return column {
        width = "fill",
        children = { header, reveal(value, opts.content, { top = 8, left = SLOT.width }) },
    }
end

return M
