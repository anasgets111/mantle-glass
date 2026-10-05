-- Token field after NSTokenField: the kit's text field that turns each committed entry (Return or
-- comma) into a capsule token. Tokens wrap onto new lines; suggestions open in a menu while typing.
local theme = require("glass.theme")
local core = require("glass.core")
local fields = require("glass.internal.fields")
local tg = require("glass.internal.toggles")
local menu = require("glass.overlays.menu")
local overlay = require("glass.overlay")

local c = theme.c

-- not in the kit: the token is 6 px shorter than the field, 8 px of label inset, 4 px between
-- tokens, 2 px between lines; the entry keeps at least 80 px
local TOKEN = { shrink = 6, inset = 8, gap = 4, lines = 2, entry = 80 }

local M = {}

-- Token field.
---@class glass.TokenFieldOpts
---@field value? StateSignal<string[]> The tokens in order; default empty.
---@field suggestions? string[] Entries offered in a menu while typing, matched on their start.
---@field placeholder? string Shown while there are no tokens.
---@field size? glass.Size
---@field width? number Default 240.
---@field disabled? boolean|Signal<boolean>
---@field window? string
---@field name? string Accessible name.
---@field on_change? fun(tokens: string[])
---@field [string] "no such property"

---@param id string
---@param opts? glass.TokenFieldOpts
---@return Node
function M.token_field(id, opts)
    opts = opts or {}
    local size = opts.size or "regular"
    local s, g = fields.SIZES[size], theme.SIZES[size]
    local chip = g.height - TOKEN.shrink
    local value = opts.value or state("glass_tokens_" .. id, {})
    local picked = state("glass_token_pick_" .. id, 0)
    local draft = state("glass_token_draft_" .. id, "")
    local disabled = tg.sig(opts.disabled)
    local active = core.active(opts.window)
    local anchor = geometry("glass_anchor_" .. id)
    local target = focus_target("glass_field_" .. id)
    local focus = focused("glass_focus_" .. id)
    local menu_id = "glass_tokens_" .. id
    local type = theme.type[s.type]

    local function set(list)
        value:set(list)
        if opts.on_change then
            opts.on_change(list)
        end
    end
    local function add(text)
        text = text:match("^%s*(.-)%s*$")
        if text ~= "" then
            local list = { table.unpack(value:get() or {}) }
            list[#list + 1] = text
            set(list)
        end
    end
    local function remove(i)
        local list = { table.unpack(value:get() or {}) }
        table.remove(list, i)
        picked:set(0)
        set(list)
    end
    local function suggest(text)
        local items, q, have = {}, text:lower(), {}
        for _, t in ipairs(value:get() or {}) do
            have[t] = true
        end
        for _, name in ipairs(q ~= "" and opts.suggestions or {}) do
            if name:lower():sub(1, #q) == q and not have[name] then
                items[#items + 1] = { label = name }
            end
        end
        if #items > 0 then
            menu.open_menu({
                id = menu_id,
                anchor = anchor,
                items = items,
                width = "anchor",
                window = opts.window,
                on_pick = function(item)
                    add(item.label)
                    draft:set("")
                    target:set_text("")
                    target:request()
                end,
            })
        elseif menu.is_menu_open(menu_id):get() then
            overlay.close("glass_menu")
        end
    end

    local function on_key(k)
        if k.name == "Tab" and menu.pick_highlighted(menu_id) then
            return true
        end
        if k.name == "BackSpace" or k.name == "Delete" then
            local sel, list = picked:get(), value:get() or {}
            if sel > 0 and sel <= #list then
                remove(sel)
                return true
            elseif k.name == "BackSpace" and draft:get() == "" and #list > 0 then
                remove(#list)
                return true
            end
        end
    end

    local function entry_color(p, off) return p[off and "tertiary_label" or "label"] end
    local entry = textfield {
        width = TOKEN.entry,
        height = chip,
        font = theme.FONT,
        font_size = s.font,
        font_weight = type[2],
        letter_spacing = type[4],
        foreground = computed({ theme.scheme, disabled }, entry_color),
        placeholder = value:map(function(list) return #(list or {}) == 0 and opts.placeholder or "" end),
        placeholder_color = c.tertiary_label,
        caret = { color = c.accent, width = 2, radius = 1 },
        escape = "pass",
        on_key = on_key,
        focus_ring = false,
        focus_target = target,
        disabled = disabled,
        accessible_name = opts.name or opts.placeholder or id,
        on_change = function(t)
            picked:set(0)
            local head, rest = t:match("^(.*),([^,]*)$")
            if head then
                for piece in head:gmatch("[^,]+") do
                    add(piece)
                end
                t = rest
                target:set_text(rest)
            end
            draft:set(t)
            suggest(t)
        end,
        on_submit = function(t)
            if menu.pick_highlighted(menu_id) then
                return
            end
            add(t)
            draft:set("")
            if menu.is_menu_open(menu_id):get() then
                overlay.close("glass_menu")
            end
        end,
    }

    local tokens = computed({ value, picked, active, disabled, theme.scheme }, function(list, sel, a, off, p)
        local out = {}
        for i, label in ipairs(list or {}) do
            local on = i == sel and not off
            out[i] = rect(core.shape {
                id = "token" .. i,
                height = chip,
                padding = { left = TOKEN.inset, right = TOKEN.inset },
                radius = theme.CAPSULE,
                align_v = "center",
                background = on and (a and p.accent or p.inactive_selected_fill) or theme.alpha(a and p.accent or p.label, off and 0.1 or 0.2),
                hittable = not off,
                accessible_name = label,
                on_click = function() picked:set(i) end,
                children = { core.text(label, on and a and p.on_accent or entry_color(p, off), s.type) },
            })
        end
        out[#out + 1] = entry
        return out
    end)

    return row(core.shape {
        id = id,
        width = opts.width or 240,
        min_height = g.height,
        wrap = true,
        spacing = TOKEN.gap,
        line_spacing = TOKEN.lines,
        padding = { left = s.inset, right = s.inset, top = (g.height - chip) / 2, bottom = (g.height - chip) / 2 },
        align_v = "center",
        radius = s.radius,
        focused = focus,
        geometry = anchor,
        on_click = function()
            if not disabled:get() then
                target:request()
            end
        end,
        on_key = on_key,
        border_width = focus:map(function(on) return on and 1 or 0 end),
        border_color = theme.scheme:map(function(p) return theme.alpha(p.accent, 0.5) end),
        background = computed({ theme.scheme, theme.dark, disabled }, function(p, dark, off)
            return off and theme.alpha(p.input_background, dark and 0.25 or 0.5) or p.input_background
        end),
        shadows = computed({ focus, theme.scheme, disabled }, function(on, p, off)
            return on and { { color = theme.alpha(p.accent, 0.5), spread = 3.5 } } or { { color = off and "#0000000A" or p.input_border, spread = 1 } }
        end),
        children = tokens,
    })
end

return M
