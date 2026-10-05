-- Table and outline: a header row with sortable, resizable columns over a scrolling list of rows.
-- Built on the engine's `list` node (rows built once, header pinned). Selection is an inset
-- rounded accent fill, grey while the window is inactive. Columns wider than the table scroll
-- sideways with the header; the overlay scrollers show while it scrolls.
local theme = require("glass.theme")
local core = require("glass.core")
local scroller = require("glass.views.scroll_view")
local knob = scroller.knob

local c, FADE = theme.c, theme.motion.fade

-- not in the kit: the kit has no table specs; Liquid Glass's medium table row stands in, and the
-- sidebar's disclosure column and indent for the outline.
local ROW = { height = 24, radius = 6, inset = 4, pad = 10, gap = 8, max_height = 320, header = 28 }
local OUTLINE = { disc = 16, indent = 12, glyph = 11 }
local RESIZE = { grip = 7, min = 40, line = 14 }
local FILL_MIN = 120 -- not in the kit: what a "fill" column asks for before the table scrolls sideways
local TIMING = { double = 400, typeahead = 1000 }
local WHEEL = 39 -- px of one wheel notch
local NONE = {}

local M = {}

-- Column: `width` is px or "fill" (default "fill"); `align` is the text alignment of the default
-- cell and title; `sort_value` maps an item to what sorting compares (default `item[key]`).
---@class glass.TableColumn
---@field key string
---@field title? string
---@field width? number|"fill"
---@field align? "start"|"center"|"end"
---@field sortable? boolean
---@field sort_value? fun(item: any): string|number
---@field cell? fun(item: any, emphasized: Signal<boolean>): Node Default: `item[key]` as text.
---@field [string] "no such property"

---@class glass.TableOpts
---@field columns glass.TableColumn[]
---@field items any[]|Signal<any[]> Outline: items with a `children` array.
---@field key? fun(item: any): string Unique per item; default `item.key`, `item.id` or `item.name`.
---@field value? StateSignal<table<string, boolean>> The selected keys as a set `{ [key] = true }`.
---@field multiple? boolean Several rows may be selected.
---@field sort? StateSignal<{ key?: string, ascending?: boolean }>
---@field alternating? boolean Tint every other row.
---@field max_height? number Default 320; longer tables scroll.
---@field on_sort? fun(sort: { key: string, ascending: boolean })
---@field on_activate? fun(item: any) Return or double-click.
---@field expanded? StateSignal<table<string, boolean>> Outline only: the open items as a set.
---@field window? string
---@field name? string Accessible name; default `id`.
---@field [string] "no such property"

local function less(a, b)
    if type(a) ~= type(b) then
        return tostring(a) < tostring(b)
    end
    return a < b
end

local function sorted_value(col, item)
    local v = col.sort_value and col.sort_value(item) or item[col.key]
    if type(v) == "string" then
        return v:lower()
    end
    return v or ""
end

-- Flat rows in display order: sorted among siblings, children after their open parent.
local function flatten(all, s, open, tree, key, cols)
    local col
    for _, cc in ipairs(cols) do
        if s.key == cc.key then
            col = cc
        end
    end
    local asc = s.ascending ~= false
    local out = {}
    local function walk(nodes, level, parent)
        local group = {}
        for i, item in ipairs(nodes) do
            group[i] = { item = item, i = i, v = col and sorted_value(col, item) }
        end
        if col then
            -- ponytail: re-sorts every group on each change; fine to a few thousand rows.
            table.sort(group, function(a, b)
                if a.v == b.v then
                    return a.i < b.i
                end
                if asc then
                    return less(a.v, b.v)
                end
                return less(b.v, a.v)
            end)
        end
        for _, g in ipairs(group) do
            local kids = tree and g.item.children
            local k = key(g.item)
            out[#out + 1] = { item = g.item, key = k, level = level, parent = parent, kids = kids and #kids > 0, n = #out + 1 }
            if kids and #kids > 0 and open[k] then
                walk(kids, level + 1, k)
            end
        end
    end
    walk(all or {}, 0, nil)
    return out
end

local function build(id, opts, tree)
    local cols, multiple = opts.columns, opts.multiple
    local active = core.active(opts.window)
    local key = opts.key or function(it) return tostring(it.key or it.id or it.name) end
    local pre = "glass_table_" .. id
    ---@type StateSignal<table<string, boolean>>
    local value = opts.value or state(pre .. "_value", {})
    local sort = opts.sort or state(pre .. "_sort", { ascending = true })
    local open = opts.expanded or state(pre .. "_open", {})
    local anchor, cursor = state(pre .. "_anchor", ""), state(pre .. "_cursor", "")
    local offset, view = scroll(pre), geometry(pre .. "_view")
    local across, port = scroll(pre .. "_x"), geometry(pre .. "_port")
    local items = type(opts.items) == "userdata" and opts.items or theme.dark:map(function() return opts.items end)
    local rows = computed({ items, sort, open }, function(all, s, o)
        return flatten(all, s, tree and o or NONE, tree, key, cols)
    end)

    local widths, geoms = {}, {}
    for i, col in ipairs(cols) do
        widths[i] = state(pre .. "_w_" .. col.key, col.width or "fill")
        geoms[i] = geometry(pre .. "_g_" .. col.key)
    end

    -- The columns' width with the row padding; "fill" columns count FILL_MIN.
    local need = computed(widths, function(...)
        local sum = 2 * (ROW.inset + ROW.pad)
        for _, w in ipairs({ ... }) do
            sum = sum + (type(w) == "number" and w or FILL_MIN)
        end
        return sum
    end)
    local inner = computed({ need, port }, function(n, p) return n > p.width and n or "fill" end)

    local function index_of(k)
        for i, e in ipairs(rows:get()) do
            if e.key == k then
                return i
            end
        end
    end

    local function select_range(a, b)
        local i, j = index_of(a), index_of(b)
        local set = {}
        if i and j then
            for n = math.min(i, j), math.max(i, j) do
                set[rows:get()[n].key] = true
            end
        end
        value:set(set)
    end

    local function pick(k, mods)
        if multiple and mods.shift then
            select_range(anchor:get() ~= "" and anchor:get() or k, k)
        elseif multiple and mods.ctrl then
            local set = core.merge({}, value:get())
            set[k] = not set[k] or nil
            value:set(set)
            anchor:set(k)
        else
            value:set({ [k] = true })
            anchor:set(k)
        end
        cursor:set(k)
    end

    local last, stamp = nil, 0
    local function click(entry, mods)
        pick(entry.key, mods or NONE)
        if last == entry.key then
            last = nil
            if opts.on_activate then
                opts.on_activate(entry.item)
            end
            return
        end
        last, stamp = entry.key, stamp + 1
        local mine = stamp
        timer(TIMING.double, function()
            if stamp == mine then
                last = nil
            end
        end)
    end

    local function move(to, extend)
        local all = rows:get()
        if #all == 0 then
            return
        end
        to = math.max(1, math.min(#all, to))
        pick(all[to].key, extend and { shift = true } or NONE)
        cursor:set(all[to].key)
        offset:reveal(to)
    end

    local function toggle(k)
        local set = core.merge({}, open:get())
        set[k] = not set[k] or nil
        open:set(set)
    end

    local buffer, typed = "", 0
    local function typeahead(text)
        buffer, typed = buffer .. text:lower(), typed + 1
        local mine = typed
        timer(TIMING.typeahead, function()
            if typed == mine then
                buffer = ""
            end
        end)
        local first = cols[1].key
        for i, e in ipairs(rows:get()) do
            if tostring(e.item[first] or ""):lower():sub(1, #buffer) == buffer then
                move(i)
                return
            end
        end
    end

    local function on_key(k)
        local m, n = k.modifiers, k.name
        if m.ctrl or m.alt or m.super then
            if multiple and m.ctrl and n == "a" then
                local set = {}
                for _, e in ipairs(rows:get()) do
                    set[e.key] = true
                end
                value:set(set)
                return true
            end
            return
        end
        local all = rows:get()
        local cur = index_of(cursor:get())
        local entry = cur and all[cur]
        local page = math.floor((opts.max_height or ROW.max_height) / ROW.height) - 1
        if n == "Down" then
            move(cur and cur + 1 or 1, m.shift)
        elseif n == "Up" then
            move(cur and cur - 1 or #all, m.shift)
        elseif n == "Page_Down" then
            move((cur or 0) + page, m.shift)
        elseif n == "Page_Up" then
            move((cur or 1) - page, m.shift)
        elseif n == "Home" then
            move(1, m.shift)
        elseif n == "End" then
            move(#all, m.shift)
        elseif n == "Return" or n == "KP_Enter" then
            if entry and opts.on_activate then
                opts.on_activate(entry.item)
            end
        elseif n == "space" and multiple and entry and buffer == "" then
            pick(entry.key, { ctrl = true })
        elseif not tree and (n == "Left" or n == "Right") then
            across:scroll_by(n == "Left" and -WHEEL or WHEEL)
        elseif tree and n == "Right" and entry then
            if entry.kids and not open:get()[entry.key] then
                toggle(entry.key)
            elseif entry.kids then
                move((cur or 0) + 1)
            end
        elseif tree and n == "Left" and entry then
            if entry.kids and open:get()[entry.key] then
                toggle(entry.key)
            elseif entry.parent then
                move(index_of(entry.parent))
            end
        elseif k.text and k.text:byte() >= 32 then
            typeahead(k.text)
        else
            return
        end
        return true
    end

    local function header_cell(i, col)
        local w = widths[i]
        local sorted = sort:map(function(s) return s.key == col.key end)
        local active_title = theme.pick(sorted, "label", "secondary_label")
        local title = core.text(col.title or col.key, active_title, "control_small", {
            width = "fill",
            elide = "end",
            text_align = col.align,
        })
        local arrow = core.icon(sort:map(function(s) return s.ascending == false and "chevron-down" or "chevron-up" end),
            c.secondary_label, 9, { opacity = sorted:map(function(on) return on and 1 or 0 end), animate = { opacity = FADE } })
        local props = {
            width = w,
            height = "fill",
            geometry = geoms[i],
            accessible_name = col.sortable and ("Sort by " .. (col.title or col.key)) or nil,
            children = {
                row {
                    width = "fill",
                    height = "fill",
                    spacing = 4,
                    padding = { right = ROW.gap },
                    align_v = "center",
                    children = col.sortable and { title, arrow } or { title },
                },
            },
        }
        if col.sortable then
            props.on_click = function()
                local s = sort:get()
                sort:set({ key = col.key, ascending = not (s.key == col.key and s.ascending ~= false) })
                if opts.on_sort then
                    opts.on_sort(sort:get())
                end
            end
            core.focusable(pre .. "_h_" .. col.key, props)
        end
        if i < #cols then
            local grab
            props.children[2] = rect {
                width = RESIZE.grip,
                height = "fill",
                align_h = "end",
                cursor = "col-resize",
                on_click = function() end,
                on_drag = function(_, p, phase)
                    if phase == "start" then
                        grab = p.x
                        if w:get() == "fill" then
                            w:set(math.floor(geoms[i]:get().width))
                        end
                    elseif phase == "move" and type(w:get()) == "number" then
                        w:set(math.max(RESIZE.min, w:get() + p.x - grab))
                    end
                end,
                children = { rect { width = 1, height = RESIZE.line, align_h = "end", align_v = "center", background = c.separator } },
            }
        end
        return rect(props)
    end

    local header_cells = {}
    for i, col in ipairs(cols) do
        header_cells[i] = header_cell(i, col)
    end

    local function body_row(entry)
        local k = entry.key
        local selected = value:map(function(v) return v[k] == true end)
        local emphasized = computed({ selected, active }, function(on, a) return on and a end)
        local cells = {}
        for i, col in ipairs(cols) do
            local kids = {}
            if tree and i == 1 then
                local pad = OUTLINE.indent * entry.level
                local chevron = entry.kids and core.icon(
                    open:map(function(set) return set[k] and "chevron-down" or "chevron-right" end),
                    theme.pick(emphasized, "on_accent", "secondary_label"), OUTLINE.glyph, { margin = { left = pad } }) or nil
                kids[1] = rect {
                    width = OUTLINE.disc + pad,
                    height = "fill",
                    on_click = entry.kids and function() toggle(k) end or nil,
                    children = { chevron },
                }
            end
            kids[#kids + 1] = col.cell and col.cell(entry.item, emphasized) or core.text(
                tostring(entry.item[col.key] or ""), theme.pick(emphasized, "on_accent", "label"), "body",
                { width = "fill", elide = "end", text_align = col.align })
            cells[i] = row {
                width = widths[i],
                height = "fill",
                align_v = "center",
                padding = { right = ROW.gap },
                children = kids,
            }
        end
        local striped = opts.alternating and entry.n % 2 == 0
        -- not in the kit: native lists fill a key window's selected row with the accent, else grey.
        return row(core.shape {
            width = "fill",
            height = ROW.height,
            radius = ROW.radius,
            padding = { left = ROW.pad, right = ROW.pad },
            background = computed({ selected, active, theme.scheme }, function(on, a, p)
                return on and (a and p.accent or p.inactive_selected_fill) or striped and p.quaternary_fill or theme.CLEAR
            end),
            animate = { background = FADE },
            on_click = function(_, _, _, mods) click(entry, mods) end,
            children = cells,
        })
    end

    local body = column {
        width = inner,
        children = {
            row {
                width = "fill",
                height = ROW.header,
                padding = { left = ROW.inset + ROW.pad, right = ROW.inset + ROW.pad },
                on_wheel = function(_, steps, mods)
                    if mods.shift then
                        across:scroll_by(-steps * WHEEL)
                    end
                end,
                children = header_cells,
            },
            rect { width = "fill", height = 1, background = c.separator },
            list {
                width = "fill",
                max_height = opts.max_height or ROW.max_height,
                padding = { left = ROW.inset, right = ROW.inset },
                scroll = offset,
                animate = { scroll = scroller.ease(pre) },
                geometry = view,
                source = rows,
                key = function(entry) return entry.key end,
                itemfn = body_row,
            },
        },
    }

    local props = core.shape {
        width = "fill",
        radius = 8,
        clip = "rounded",
        border_width = 1,
        border_color = c.separator,
        accessible_name = opts.name or id,
        on_key = on_key,
        children = {
            row { width = "fill", geometry = port, scroll = across, animate = { scroll = scroller.ease(pre .. "_x") }, children = { body } },
            rect {
                width = "fill",
                height = "fill",
                margin = { top = ROW.header + 1 },
                hittable = false,
                children = { knob(pre, offset, view, rows:map(function(all) return #all * ROW.height end)) },
            },
            knob(pre .. "_x", across, port, need, true),
        },
    }
    core.focusable(pre, props)
    return rect(props)
end

-- Table: sortable, resizable columns; click selects, double-click or Return activates.
-- Keys: Up/Down (Shift extends), Home/End, Page Up/Down, Return, Ctrl+A, Space (toggle) and
-- type-to-select on the first column; Left and Right (Shift+wheel over the header) scroll sideways.
---@param id string
---@param opts glass.TableOpts
---@return Node
function M.table(id, opts)
    return build(id, opts, false)
end

-- Outline: a table whose items nest under `children`; the first column carries the disclosure
-- chevrons. Left collapses (or goes to the parent), Right expands (or goes to the first child).
---@param id string
---@param opts glass.TableOpts
---@return Node
function M.outline(id, opts)
    return build(id, opts, true)
end

return M
