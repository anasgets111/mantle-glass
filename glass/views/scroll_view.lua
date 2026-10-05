-- Liquid Glass overlay scroller, from the kit: a 6 px capsule knob in a 12 px strip at the trailing
-- edge, over the content, shown while it scrolls and faded out after. As native apps do beyond the kit,
-- the pointer in the strip brings it up and widens it over a faint track; the knob drags and a click
-- on the track pages.
local theme = require("glass.theme")
local core = require("glass.core")

local M = {}

local INSTANT = { duration = 1 }

local KNOB = {
    strip = 12,
    width = 6,
    inset = 3,
    min = 24, -- not in the kit: the shortest knob, so a long document keeps one to see
    linger = 1000, -- not in the kit: how long it stays after the content stops
    wide = 8, -- not in the kit: the knob under the pointer, as native apps widen it
    page = 0.9, -- not in the kit: a track click scrolls this much of the view
    notch = 48, -- not in the kit: px per wheel notch over the strip, which sits above the content
}

-- True while scroller `name`'s knob is held.
---@param name string
---@return StateSignal<boolean>
function M.dragging(name)
    return state("glass_knob_drag_" .. name, false)
end

-- The scroll ease for scroller `name`'s viewport: the native smooth scrolling for the wheel, keys and
-- paging, at once while its knob is held. Build it once per viewport.
---@param name string
---@return Signal<table>
function M.ease(name)
    return computed({ M.dragging(name), theme.motion.smooth }, function(held, smooth) return held and INSTANT or smooth end)
end

-- The overlay scroller over a scrolling viewport: `view` is the viewport's `geometry`, `content` a
-- signal of the content's length on the scroll axis, `name` unique per scroller. Build it once, not
-- inside a map: a rebuilt one restarts its fade timer every frame. Put it in a stacking parent
-- beside the viewport.
-- Give the viewport `animate = { scroll = ease(name) }`, or a held knob drags behind its own ease.
---@param name string
---@param offset ScrollSignal
---@param view Signal<Rect>
---@param content Signal<number>
---@param horizontal? boolean The strip runs along the bottom edge.
---@return Node
function M.knob(name, offset, view, content, horizontal)
    local axis, coord = horizontal and "width" or "height", horizontal and "x" or "y"
    local geo = computed({ view, content, offset }, function(v, total, off)
        local len = v[axis]
        local track = len - 2 * KNOB.inset
        if total <= len + 0.5 or track <= 0 then
            return false
        end
        local size = math.max(KNOB.min, track * len / total)
        return { size = size, at = KNOB.inset + (track - size) * off / (total - len), len = len, total = total, track = track }
    end)
    local over = hover("glass_knob_" .. name)
    local dragging = M.dragging(name)
    local open = computed({ over, dragging }, function(h, d) return h or d end)
    local shown = computed({ geo, pulse(offset, KNOB.linger), open }, function(k, moving, o) return k and (moving or o) or false end)
    local thick = open:map(function(o) return o and KNOB.wide or KNOB.width end)
    local size = geo:map(function(k) return k and k.size or 0 end)
    local grab
    local function scroll_at(k, at)
        local frac = math.max(0, math.min(1, (at - KNOB.inset) / (k.track - k.size)))
        offset:scroll_to(frac * (k.total - k.len))
    end
    local knob = rect {
        width = horizontal and size or thick,
        height = horizontal and thick or size,
        radius = theme.CAPSULE,
        align_h = horizontal and "start" or "center",
        align_v = horizontal and "center" or "start",
        margin = geo:map(function(k)
            local at = k and k.at or 0
            return horizontal and { left = at } or { top = at }
        end),
        background = theme.c.scroll_knob,
        animate = { width = theme.motion.fade, height = theme.motion.fade },
    }
    return rect {
        width = horizontal and "fill" or KNOB.strip,
        height = horizontal and KNOB.strip or "fill",
        align_h = not horizontal and "end" or nil,
        align_v = horizontal and "end" or nil,
        hover = over,
        hittable = geo:map(function(k) return k ~= false end),
        cursor = "default",
        background = computed({ open, theme.scheme }, function(o, p) return o and p.quinary_fill or theme.CLEAR end),
        opacity = shown:map(function(on) return on and 1 or 0 end),
        animate = { opacity = theme.motion.fade, background = theme.motion.fade },
        on_wheel = function(_, steps) offset:scroll_by(-steps * KNOB.notch) end,
        on_drag = function(_, pointer, phase)
            local k = geo:get()
            if not k then
                return
            end
            local p = pointer[coord]
            if phase == "start" then
                dragging:set(true)
                if p >= k.at and p <= k.at + k.size then
                    grab = p - k.at
                else
                    grab = nil
                    offset:scroll_by((p < k.at and -1 or 1) * k.len * KNOB.page)
                end
            elseif phase == "move" then
                if grab then
                    scroll_at(k, p - grab)
                end
            else
                dragging:set(false)
                grab = nil
            end
        end,
        children = { knob },
    }
end

-- A scrolling area that fills its parent, with the knob. Build it once, not inside a map.
---@class glass.ScrollViewOpts
---@field child? Node The content.
---@field scroll? ScrollSignal Default its own.
---@field props? table More fields for the scrolling column: id, padding, animate...
---@field [string] "no such property"

---@param id string
---@param opts glass.ScrollViewOpts
---@return Node
function M.scroll_view(id, opts)
    local offset = opts.scroll or scroll("glass_scroll_" .. id)
    local view, body = geometry("glass_scroller_" .. id), geometry("glass_scroller_body_" .. id)
    local props = core.merge({
        width = "fill",
        height = "fill",
        scroll = offset,
        geometry = view,
        children = { rect { width = "fill", geometry = body, children = { opts.child } } },
    }, opts.props)
    props.animate = core.merge({ scroll = M.ease(id) }, props.animate)
    return rect {
        width = "fill",
        height = "fill",
        children = {
            column(props),
            M.knob(id, offset, view, body:map(function(g) return g.height end)),
        },
    }
end

return M
