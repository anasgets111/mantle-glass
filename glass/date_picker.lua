-- Date pickers after NSDatePicker: the textual style (date and time fields in the kit's text field
-- with a stepper), the graphical calendar, and a compact field that opens the calendar in a popover.
local theme = require("glass.theme")
local core = require("glass.core")
local fields = require("glass.internal.fields")
local tg = require("glass.internal.toggles")
local popover = require("glass.popover")
local stepper = require("glass.stepper").stepper
local button = require("glass.button").button

local c = theme.c

local MONTHS = { "January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December" }
local WEEKDAYS = { "S", "M", "T", "W", "T", "F", "S" }
-- not in the kit: the calendar's day cell (a 28 px circle in a 32 x 30 slot) and the year range
local CELL, DAY, ROW = 32, 28, 30
local YEARS = { 1900, 2999 }
local CAL_WIDTH = 7 * CELL
-- not in the kit: the popover's inner padding is 16
local POPOVER_WIDTH = CAL_WIDTH + 32

-- Part name -> lowest, highest (nil: the month's length), printf format.
local PARTS = {
    month = { 1, 12, "%d" },
    day = { 1, nil, "%d" },
    year = { YEARS[1], YEARS[2], "%d" },
    hour = { 0, 23, "%02d" },
    minute = { 0, 59, "%02d" },
}

local M = {}

-- Noon of a date, explicitly: `month` and `day` overflow into neighbours (day 0 is the last of the previous month).
local function stamp(y, m, d) return os.time { year = y, month = m, day = d, hour = 12 } end
local function days_in(y, m) return os.date("*t", stamp(y, m + 1, 0)).day end
local function key_of(y, m, d) return y * 10000 + m * 100 + d end

local function now()
    local t = os.date("*t", os.time())
    return { year = t.year, month = t.month, day = t.day, hour = t.hour, minute = t.min }
end

-- `v` with `part` moved by `dir`, wrapping except the year, the day kept inside its month.
local function step(v, part, dir)
    local lo, hi = PARTS[part][1], PARTS[part][2] or days_in(v.year, v.month)
    local out = core.merge({}, v)
    local x = (out[part] or lo) + dir
    if x > hi then
        x = part == "year" and hi or lo
    elseif x < lo then
        x = part == "year" and lo or hi
    end
    out[part] = x
    out.day = math.min(out.day, days_in(out.year, out.month))
    return out
end

-- Today as a `key_of` number; 0 until the clock's first push.
local today = mantle.system:map(function(s)
    if not s then
        return 0
    end
    local t = os.date("*t", s.time)
    return key_of(t.year, t.month, t.day)
end)

-- Calendar: a month grid with previous, next and Today. Arrow keys move the day, Page Up and Down the month.
---@class glass.CalendarOpts
---@field value? StateSignal<glass.Date> Default today. Hour and minute pass through untouched.
---@field view? StateSignal<{ year: integer, month: integer }> The month shown; default the value's. Browsing leaves `value` alone.
---@field disabled? boolean|Signal<boolean>
---@field window? string
---@field on_change? fun(value: glass.Date)
---@field [string] "no such property"

---@class glass.Date
---@field year integer
---@field month integer 1..12
---@field day integer
---@field hour? integer
---@field minute? integer

---@param id string
---@param opts? glass.CalendarOpts
---@return Node
function M.calendar(id, opts)
    opts = opts or {}
    local value = opts.value or state("glass_cal_" .. id, now())
    local seed = value:get() or now()
    local view = opts.view or state("glass_calv_" .. id, { year = seed.year, month = seed.month })
    local disabled = tg.sig(opts.disabled)
    local active = core.active(opts.window)
    local focused = focus_visible("glass_focus_cal_" .. id)

    local grid = view:map(function(v)
        local first = os.date("*t", stamp(v.year, v.month, 1)).wday
        local out = { month = v.month }
        for i = 1, 42 do
            local t = os.date("*t", stamp(v.year, v.month, i - first + 1))
            out[i] = { year = t.year, month = t.month, day = t.day }
        end
        return out
    end)

    local function show(y, m) view:set({ year = y, month = m }) end
    local function shift(delta)
        local v = view:get()
        local t = os.date("*t", stamp(v.year, v.month + delta, 1))
        show(t.year, t.month)
    end
    local function pick(y, m, d)
        local out = core.merge({}, value:get() or {})
        out.year, out.month, out.day = y, m, d
        value:set(out)
        show(y, m)
        if opts.on_change then
            opts.on_change(out)
        end
    end

    local function cell(i)
        local at = grid:map(function(g) return g[i] end)
        local look = computed({ at, grid, value, today, disabled, active, focused, theme.scheme }, function(d, g, v, t, off, a, fv, p)
            local key = key_of(d.year, d.month, d.day)
            local picked = v and key == key_of(v.year, v.month, v.day)
            local text = p[off and "tertiary_label" or d.month ~= g.month and "tertiary_label" or "label"]
            local fill = theme.CLEAR
            if picked then
                fill = a and p.accent or p.inactive_selected_fill
                text = a and p.on_accent or p.label
            end
            return {
                text = d.day,
                fill = fill,
                label = text,
                border = key == t and not picked and 1.5 or 0,
                accent = a and p.accent or p.inactive_glyph,
                ring = picked and fv and core.focus_ring(p.accent) or {},
            }
        end)
        local props = {
            width = DAY,
            height = DAY,
            align_h = "center",
            align_v = "center",
            radius = theme.CAPSULE,
            background = look:map(function(l) return l.fill end),
            border_width = look:map(function(l) return l.border end),
            border_color = look:map(function(l) return l.accent end),
            shadows = look:map(function(l) return l.ring end),
            hittable = disabled:map(function(d) return not d end),
            animate = { background = theme.motion.fade },
            on_click = function()
                local d = grid:get()[i]
                pick(d.year, d.month, d.day)
            end,
            children = { core.text(look:map(function(l) return tostring(l.text) end), look:map(function(l) return l.label end), "body", { align_h = "center" }) },
        }
        return rect { width = CELL, height = ROW, children = { rect(core.shape(props)) } }
    end

    local weeks = {}
    for w = 0, 5 do
        local days = {}
        for d = 1, 7 do
            days[d] = cell(w * 7 + d)
        end
        weeks[#weeks + 1] = row { children = days }
    end
    local heads = {}
    for d = 1, 7 do
        heads[d] = rect { width = CELL, height = 20, children = { core.text(WEEKDAYS[d], c.tertiary_label, "caption2", { align_h = "center" }) } }
    end

    local function move(days)
        local v = value:get() or now()
        local t = os.date("*t", stamp(v.year, v.month, v.day + days))
        pick(t.year, t.month, t.day)
    end
    local function month(delta)
        local v = value:get() or now()
        local t = os.date("*t", stamp(v.year, v.month + delta, 1))
        pick(t.year, t.month, math.min(v.day, days_in(t.year, t.month)))
    end
    local KEYS = {
        Left = function() move(-1) end,
        Right = function() move(1) end,
        Up = function() move(-7) end,
        Down = function() move(7) end,
        Page_Up = function() month(-1) end,
        Page_Down = function() month(1) end,
    }

    return column {
        width = CAL_WIDTH,
        spacing = 4,
        accessible_name = id,
        on_click = function() end,
        focus_visible = focused,
        focus_ring = false,
        on_key = function(k)
            local go = KEYS[k.name]
            if go and not disabled:get() and not (k.modifiers.ctrl or k.modifiers.alt) then
                go()
                return true
            end
        end,
        children = {
            row { width = "fill", align_v = "center", spacing = 2, padding = { left = 4 }, children = {
                core.text(view:map(function(v) return MONTHS[v.month] .. " " .. v.year end), c.label, "headline", { width = "fill" }),
                button(id .. "_prev", { icon = "chevron-left", kind = "borderless", size = "small", disabled = disabled, window = opts.window, name = "Previous month", on_click = function() shift(-1) end }),
                button(id .. "_today", { label = "Today", kind = "borderless", size = "small", disabled = disabled, window = opts.window, on_click = function()
                    local t = now()
                    pick(t.year, t.month, t.day)
                end }),
                button(id .. "_next", { icon = "chevron-right", kind = "borderless", size = "small", disabled = disabled, window = opts.window, name = "Next month", on_click = function() shift(1) end }),
            } },
            row { children = heads },
            column { children = weeks },
        },
    }
end

-- Date picker. `style = "textual"` is the fields and stepper; `"popover"` a compact field that opens the calendar.
---@class glass.DatePickerOpts
---@field value? StateSignal<glass.Date> Default now.
---@field time? boolean Adds hour and minute (24 h).
---@field style? "textual"|"popover" Default "textual".
---@field size? glass.Size
---@field disabled? boolean|Signal<boolean>
---@field window? string
---@field on_change? fun(value: glass.Date)
---@field [string] "no such property"

---@param id string
---@param opts? glass.DatePickerOpts
---@return Node
function M.date_picker(id, opts)
    opts = opts or {}
    local size = opts.size or "regular"
    local inset = fields.SIZES[size].inset
    local kind = fields.SIZES[size].type
    local time = opts.time
    local value = opts.value or state("glass_date_" .. id, now())
    local disabled = tg.sig(opts.disabled)
    local active = core.active(opts.window)
    local function commit(v)
        value:set(v)
        if opts.on_change then
            opts.on_change(v)
        end
    end

    if opts.style == "popover" then
        local anchor = geometry("glass_anchor_" .. id)
        local view = state("glass_calv_" .. id, { year = now().year, month = now().month })
        local label = value:map(function(v)
            v = v or now()
            local s = string.format("%s %d, %d", MONTHS[v.month]:sub(1, 3), v.day, v.year)
            return time and string.format("%s  %02d:%02d", s, v.hour or 0, v.minute or 0) or s
        end)
        local function tone(role, off_role) return computed({ disabled, theme.scheme }, function(off, p) return p[off and off_role or role] end) end
        return fields.box(id, {
            size = size,
            padding = { left = inset, right = inset },
            disabled = opts.disabled,
            geometry = anchor,
            focus = function()
                local v = value:get() or now()
                view:set({ year = v.year, month = v.month })
                popover.open_popover {
                    anchor = anchor,
                    width = POPOVER_WIDTH,
                    window = opts.window,
                    content = function()
                        return M.calendar(id .. "_cal", { value = value, view = view, window = opts.window, on_change = opts.on_change })
                    end,
                }
            end,
            props = { accessible_name = id, spacing = 6 },
        }, {
            core.text(label, tone("label", "tertiary_label"), kind),
            core.icon("calendar", tone("secondary_label", "tertiary_label"), 13),
        })
    end

    local sel = state("glass_date_part_" .. id, "day")
    local order = time and { "month", "/", "day", "/", "year", " ", "hour", ":", "minute" } or { "month", "/", "day", "/", "year" }
    local focus = {}
    local any = {}
    for _, name in ipairs(order) do
        if PARTS[name] then
            focus[name] = focused("glass_dp_focus_" .. id .. name)
            any[#any + 1] = focus[name]
        end
    end
    local anyfocus = computed(any, function(...)
        for _, f in ipairs { ... } do
            if f then
                return true
            end
        end
        return false
    end)
    local kids = {}
    for _, name in ipairs(order) do
        local text_for = function(v) return string.format(PARTS[name] and PARTS[name][3] or "%s", v and v[name] or 0) end
        if not PARTS[name] then
            kids[#kids + 1] = core.text(name, c.label, kind)
        else
            local props = {
                accessible_name = id .. " " .. name,
                padding = { left = 2, right = 2 },
                radius = 3,
                align_v = "center",
                focused = focus[name],
                on_key = function(k)
                    local dir = ({ Up = 1, Down = -1 })[k.name]
                    if dir and not disabled:get() then
                        sel:set(name)
                        commit(step(value:get() or now(), name, dir))
                        return true
                    end
                end,
            }
            tg.interact("dp_" .. id .. name, props, opts, function() sel:set(name) end)
            local look = computed({ focus[name], anyfocus, sel, disabled, active, theme.scheme }, function(f, any_f, s, off, a, p)
                local on = f or (not any_f and s == name)
                if on and not off then
                    return { fill = a and p.accent or p.inactive_selected_fill, label = a and p.on_accent or p.label }
                end
                return { fill = theme.CLEAR, label = p[off and "tertiary_label" or "label"] }
            end)
            props.background = look:map(function(l) return l.fill end)
            props.children = { core.text(value:map(text_for), look:map(function(l) return l.label end), kind) }
            kids[#kids + 1] = rect(core.shape(props))
        end
    end

    local tick = state("glass_date_tick_" .. id, 0)
    local last = tick:get()
    return row { spacing = 4, align_v = "center", children = {
        fields.box(id, { size = size, padding = { left = inset - 2, right = inset - 2 }, disabled = opts.disabled }, { row { align_v = "center", children = kids } }),
        stepper(id .. "_step", {
            size = size,
            disabled = opts.disabled,
            value = tick,
            on_change = function(v)
                local dir = v > last and 1 or -1
                last = v
                commit(step(value:get() or now(), sel:get(), dir))
            end,
        }),
    } }
end

return M
