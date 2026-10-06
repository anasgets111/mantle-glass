-- Liquid Glass menu, from the kit: glass panel under an anchor, rows that highlight under
-- the pointer, one level of submenus to the side, keyboard up/down/left/right/Enter/Escape.
-- Callbacks cannot live in named state, so the open menu is a Lua local the layer builder reads.
local theme = require("glass.theme")
local core = require("glass.core")
local material = require("glass.material")
local overlay = require("glass.overlay")

local c = theme.c
local text, icon = core.text, core.icon

local M = {}

-- Regular density, from the kit's menu tables.
local MENU = {
    radius = 12,
    pad = { top = 6, bottom = 5, left = 5, right = 5 },
    row = 24,
    header = 24,
    separator = 11,
    inset = 11, -- highlight edge to content
    gap = 8, -- symbol to label
    symbol = 11,
    check = 12,
    width = 244,
    min_width = 160, -- not in the kit: floor for a menu as wide as its anchor
    below = 4, -- not in the kit: anchor to menu
    edge = 4, -- not in the kit: the least room left between a menu and the window's edge
    sub_width = 120,
}

-- not in the kit: without the plus-lighter/darker blend a tertiary vibrant grey vanishes on the
-- glass, so shortcuts and chevrons take the secondary label.
local faint_role = "vibrant_tertiary_label"

local sel = state("glass_menu_sel", 0)
local sub = state("glass_menu_sub", 0)
local subsel = state("glass_menu_subsel", 0)
local deep = state("glass_menu_deep", false)
local owner = state("glass_menu_owner", "")
local shown = overlay.is_open("glass_menu")
local box, sub_box = geometry("glass_menu_box"), geometry("glass_menu_sub_box")

-- `x` moved so the span `size` stays inside [lo, hi] with the edge margin; it keeps `lo` if too big.
local function clamp(x, size, lo, hi)
    return math.max(lo + MENU.edge, math.min(x, hi - MENU.edge - size))
end

---@type table
local spec = {}

local function selectable(item)
    return not (item.separator or item.header or item.disabled)
end

local function pick(item)
    overlay.close("glass_menu")
    if item.on_click then
        item.on_click()
    end
    if spec.on_pick then
        spec.on_pick(item)
    end
end

-- The highlighted row, in the submenu when it holds the keyboard; nil while no menu is open.
local function current()
    local items = spec.items
    if not items or not shown:get() then
        return nil
    end
    if deep:get() then
        return items[sub:get()].submenu[subsel:get()]
    end
    return items[sel:get()]
end

local never = theme.dark:map(function() return false end)

-- One row. `active` is a boolean signal, `open` marks a submenu parent whose submenu holds the
-- pointer; `on_enter` runs when the pointer arrives.
local function item_row(level, i, item, columns, active, open, on_enter)
    if item.separator then
        return rect {
            width = "fill",
            height = MENU.separator,
            children = { rect(core.shape {
                width = "fill",
                height = 1,
                radius = 1,
                align_v = "center",
                margin = { left = MENU.inset, right = MENU.inset },
                background = c.vibrant_secondary_fill,
            }) },
        }
    end
    if item.header then
        return row {
            width = "fill",
            height = MENU.header,
            padding = { left = MENU.inset, right = MENU.inset },
            children = { text(item.header, c.vibrant_secondary_label, "headline", material.vibrant({ align_v = "center" })) },
        }
    end
    local live = selectable(item)
    local fg = live and theme.pick(active, "on_accent", "vibrant_label") or c.vibrant_tertiary_label
    local kids = {}
    if columns.check then
        local checked = type(item.checked) == "userdata" and item.checked:map(function(on) return on and 1 or 0 end) or item.checked and 1 or 0
        kids[#kids + 1] = rect {
            width = MENU.check,
            height = MENU.row,
            children = { icon("check", fg, 13, material.vibrant({ align_v = "center", opacity = checked })) },
        }
    end
    if columns.icon then
        kids[#kids + 1] = rect {
            width = MENU.symbol,
            height = MENU.row,
            children = { item.icon and icon(item.icon, fg, 13, material.vibrant({ align_v = "center", align_h = "center" })) or nil },
        }
    end
    kids[#kids + 1] = text(item.label, fg, "control", material.vibrant({ width = "fill" }))
    if item.shortcut then
        kids[#kids + 1] = text(item.shortcut, live and theme.pick(active, "on_accent", faint_role) or fg, "control", material.vibrant({}))
    end
    if item.submenu then
        kids[#kids + 1] = icon("chevron-right", theme.pick(active, "on_accent", faint_role), 13, material.vibrant({ align_v = "center" }))
    end
    local over = hover("glass_menu_" .. level .. "_" .. i)
    return row(core.shape {
        id = "glass_menu_" .. level .. "_" .. i,
        width = "fill",
        height = MENU.row,
        radius = 8,
        padding = { left = MENU.inset, right = MENU.inset },
        spacing = MENU.gap,
        hover = over,
        geometry = item.submenu and geometry("glass_menu_row_" .. i) or nil,
        accessible_name = item.label,
        focus_ring = false,
        on_hover = function(inside)
            if inside and live then
                on_enter()
            end
        end,
        on_click = live and not item.submenu and function() pick(item) end or function() end,
        background = computed({ active, open or never, theme.scheme }, function(a, o, p)
            return a and p.menu_highlight or o and p.vibrant_secondary_fill or theme.CLEAR
        end),
        children = kids,
    })
end

local function panel(items, level, props, active_of, open_of, enter)
    local columns = {}
    local rows = {}
    for _, item in ipairs(items) do
        columns.check = columns.check or item.checked ~= nil
        columns.icon = columns.icon or item.icon ~= nil
    end
    for i, item in ipairs(items) do
        rows[i] = item_row(level, i, item, columns, active_of(i), open_of and open_of(i), function() enter(i, item) end)
    end
    return column(material.glass("menu", core.merge({
        radius = MENU.radius,
        padding = MENU.pad,
        hittable = true,
        on_click = function() end,
        origin = { x = 0, y = 0 },
        scale = 1,
        opacity = 1,
        -- not in the kit: native menus fade in at once and pop slightly
        animate = {
            opacity = { duration = 120, from = 0 },
            scale = { duration = 120, easing = "out_quad", from = 0.97 },
        },
        children = rows,
    }, props)))
end

local function move(items, from, step)
    local n, i = #items, from
    for _ = 1, n do
        i = (i - 1 + step) % n + 1
        if selectable(items[i]) then
            return i
        end
    end
    return from
end

-- The open menu's key handler, rebuilt with the menu; the window hands keys to the top layer.
local keys = nil

overlay.layer("glass_menu", function()
    local items, anchor = spec.items, spec.anchor
    if not items then
        return rect { hittable = false } -- a reload cleared the open menu
    end
    local width = spec.width or MENU.width
    local function w_of(r) return math.max(r and r.width or 0, MENU.min_width) end
    local panel_width = width == "anchor" and anchor:map(w_of) or width
    local bounds = overlay.bounds(spec.window or core.window)
    local main = panel(items, 1, {
        width = panel_width,
        geometry = box,
        margin = computed({ anchor, bounds, box }, function(r, b, t)
            if not r then
                return {}
            end
            local w, h = t and t.width or 0, t and t.height or 0
            -- A context menu touches the pointer, above it or below.
            local gap = spec.at and 0 or MENU.below
            local left, top = r.x, r.y + r.height + gap
            if spec.align == "end" then
                left = r.x + r.width - (width == "anchor" and w_of(r) or width)
            end
            if b then
                if top + h > b.y + b.height - MENU.edge and r.y - gap - h >= b.y + MENU.edge then
                    top = r.y - gap - h
                end
                left, top = clamp(left, w, b.x, b.x + b.width), clamp(top, h, b.y, b.y + b.height)
            end
            return { left = left, top = top }
        end),
    }, function(i)
        return computed({ sel, sub, deep }, function(s, p, d) return s == i and not (p == i and d) end)
    end, function(i)
        return computed({ sub, deep }, function(p, d) return p == i and d end)
    end, function(i, item)
        sel:set(i)
        deep:set(false)
        sub:set(item.submenu and i or 0)
    end)
    local subs = {}
    for i, item in ipairs(items) do
        if item.submenu then
            local at = geometry("glass_menu_row_" .. i)
            subs[i] = panel(item.submenu, 2, {
                width = MENU.sub_width,
                geometry = sub_box,
                margin = computed({ at, bounds, sub_box }, function(r, b, t)
                    local h = t and t.height or 0
                    local left, top = r.x + r.width + MENU.pad.right - 2, r.y - MENU.pad.top
                    if b then
                        if left + MENU.sub_width > b.x + b.width - MENU.edge then
                            left = r.x - MENU.pad.left + 2 - MENU.sub_width
                        end
                        left = clamp(left, MENU.sub_width, b.x, b.x + b.width)
                        top = clamp(top, h, b.y, b.y + b.height)
                    end
                    return { left = left, top = top }
                end),
            }, function(j) return computed({ subsel, deep }, function(s, d) return d and s == j end) end, nil,
            function(j)
                subsel:set(j)
                deep:set(true)
            end)
        end
    end
    local function nav(key)
        local top = sel:get()
        local open = sub:get()
        if deep:get() then
            local list = items[open].submenu
            if key == "left" then
                deep:set(false)
            elseif key == "up" or key == "down" then
                subsel:set(move(list, subsel:get() == 0 and (key == "down" and 0 or 1) or subsel:get(), key == "down" and 1 or -1))
            end
        elseif key == "up" or key == "down" then
            sel:set(move(items, top == 0 and (key == "down" and 0 or 1) or top, key == "down" and 1 or -1))
            sub:set(0)
        elseif key == "right" and items[top] and items[top].submenu then
            sub:set(top)
            deep:set(true)
            subsel:set(move(items[top].submenu, 0, 1))
        end
    end
    local NAV = { Up = "up", Down = "down", Left = "left", Right = "right" }
    keys = function(key)
        if NAV[key.name] then
            nav(NAV[key.name])
            return true
        end
        if key.name == "Return" or key.name == "KP_Enter" or key.name == "space" then
            M.pick_highlighted()
            return true
        end
    end
    return rect {
        id = "glass_menu",
        width = "fill",
        height = "fill",
        cursor = "default",
        focus_ring = false,
        on_click = function() overlay.close("glass_menu") end,
        animate = { exit = { duration = 100, opacity = 0 } },
        children = {
            main,
            rect {
                width = "fill",
                height = "fill",
                hittable = false,
                children = sub:map(function(i) return subs[i] and { subs[i] } or {} end),
            },
        },
    }
end, {
    -- Escape closes an open submenu first, then the menu.
    escape = function()
        if sub:get() ~= 0 then
            deep:set(false)
            sub:set(0)
        else
            overlay.close("glass_menu")
        end
    end,
    key = function(key) return keys and keys(key) end,
})

-- Menu: glass panel under an anchor; arrow keys, Enter and Escape work.
---@class glass.MenuItem
---@field label? string
---@field icon? string
---@field shortcut? string
---@field checked? boolean|Signal<boolean>
---@field disabled? boolean
---@field submenu? glass.MenuItem[]
---@field on_click? fun()
---@field separator? boolean
---@field header? string
---@field value? any Opaque to the menu; `dropdown` compares it with its `value`, default the label.
---@field [string] "no such property"

---@class glass.MenuOpts
---@field anchor? Signal<table> A `geometry(name)` signal; the menu opens under it.
---@field at? { x: number, y: number } A point in the host's coordinates instead, as a context menu opens at the pointer.
---@field items glass.MenuItem[]
---@field on_pick? fun(item: glass.MenuItem)
---@field width? number|"anchor" Default 244.
---@field align? "start"|"end" "end" lines up with the anchor's trailing edge.
---@field id? string Names the opener, for `is_menu_open`.
---@field window? string The window or panel it opens over; default `core.window`.
---@field [string] "no such property"

---@param opts glass.MenuOpts
function M.open_menu(opts)
    spec = opts
    if opts.at then
        local at = { x = opts.at.x, y = opts.at.y, width = 0, height = 0 }
        spec = core.merge(core.merge({}, opts), { anchor = never:map(function() return at end) })
    end
    sel:set(0)
    sub:set(0)
    subsel:set(0)
    deep:set(false)
    owner:set(opts.id or "")
    overlay.open("glass_menu", nil, opts.window)
end

-- Wraps `opts.child` so a right click on it opens `opts.items` at the pointer.
---@class glass.ContextMenuOpts
---@field child Node
---@field items glass.MenuItem[]|fun(): glass.MenuItem[] A function builds them at each opening.
---@field on_pick? fun(item: glass.MenuItem)
---@field window? string The window or panel it opens over; default `core.window`.
---@field [string] "no such property"

---@param id string
---@param opts glass.ContextMenuOpts
---@return Node
function M.context_menu(id, opts)
    return rect {
        cursor = "default",
        on_click = function(r, button, p)
            if button ~= "right" then
                return
            end
            M.open_menu({
                at = { x = r.x + p.x, y = r.y + p.y },
                items = type(opts.items) == "function" and opts.items() or opts.items --[[@as glass.MenuItem[] ]],
                on_pick = opts.on_pick,
                id = "context_" .. id,
                window = opts.window,
            })
        end,
        children = { opts.child },
    }
end

-- The row the open menu highlights, or nil: for an opener whose own keys steer the menu.
---@return glass.MenuItem?
function M.menu_highlighted()
    return current()
end

-- Picks the highlighted row as Return does; false when none is, or the open menu is not `id`'s.
---@param id? string
---@return boolean
function M.pick_highlighted(id)
    local item = current()
    if (id and owner:get() ~= id) or not item or not selectable(item) or item.submenu then
        return false
    end
    pick(item)
    return true
end

-- native menu glyphs and the modifier each one means here: ⌘ is Ctrl, as Super belongs to the
-- compositor. Key glyphs name keysyms.
M.MODIFIERS = { ["⌘"] = "ctrl", ["⌃"] = "ctrl", ["⌥"] = "alt", ["⇧"] = "shift" }
local KEYS = { ["⏎"] = "Return", ["↩"] = "Return", ["⌫"] = "BackSpace", ["⌦"] = "Delete", ["⎋"] = "Escape",
    ["⇥"] = "Tab", ["←"] = "Left", ["→"] = "Right", ["↑"] = "Up", ["↓"] = "Down", ["Space"] = "space" }

-- A shortcut string such as "⌘⇧N" as { mods = { ctrl = true, shift = true }, key = "n" }.
local function parse(shortcut)
    local mods, rest = {}, shortcut
    while true do
        local found
        for glyph, mod in pairs(M.MODIFIERS) do
            if rest:sub(1, #glyph) == glyph then
                mods[mod], rest, found = true, rest:sub(#glyph + 1), true
            end
        end
        if not found then
            break
        end
    end
    return { mods = mods, key = (KEYS[rest] or rest):lower() }
end

local function matches(sc, key)
    for _, mod in ipairs({ "ctrl", "alt", "shift", "super" }) do
        if (sc.mods[mod] or false) ~= key.modifiers[mod] then
            return false
        end
    end
    return key.name:lower() == sc.key
end

-- Makes `items`' shortcuts work while `window` has the keyboard and no menu or layer is open:
-- the matching item runs as if picked. Bind the same items a menu shows, so both stay in step.
---@param items glass.MenuItem[]
---@param window? string Default `core.window`.
function M.bind_shortcuts(items, window)
    local bound = {}
    local function collect(list)
        for _, item in ipairs(list) do
            if item.submenu then
                collect(item.submenu)
            elseif item.shortcut and selectable(item) then
                bound[#bound + 1] = { sc = parse(item.shortcut), item = item }
            end
        end
    end
    collect(items)
    overlay.on_key(assert(window or core.window, "glass: bind_shortcuts needs a window"), function(key)
        if key["repeat"] then
            return false
        end
        for _, b in ipairs(bound) do
            if matches(b.sc, key) then
                if b.item.on_click then
                    b.item.on_click()
                end
                return true
            end
        end
        return false
    end)
end

-- A signal: true while the menu opened with `id` is showing.
---@param id string
---@return Signal<boolean>
function M.is_menu_open(id)
    return computed({ shown, owner }, function(open, who) return open and who == id end)
end

return M
