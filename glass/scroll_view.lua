-- Liquid Glass overlay scroller, from docs/spec/foundations.md 5: a 6 px capsule knob in a 12 px strip
-- at the trailing edge, over the content, shown while it scrolls and faded out after. No track.
local theme = require("glass.theme")
local core = require("glass.core")

local M = {}

local KNOB = {
    width = 6,
    inset = 3,
    min = 24, -- not in the kit: the shortest knob, so a long document keeps one to see
    linger = 1000, -- not in the kit: how long it stays after the content stops
}

-- A scrolling area that fills its parent. Build it once, not inside a map: a rebuilt one restarts
-- its fade timer every frame.
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
    local knob = computed({ view, body, offset }, function(v, b, off)
        local track = v.height - 2 * KNOB.inset
        if b.height <= v.height + 0.5 or track <= 0 then
            return false
        end
        local h = math.max(KNOB.min, track * v.height / b.height)
        return { height = h, top = KNOB.inset + (track - h) * off / (b.height - v.height) }
    end)
    return rect {
        width = "fill",
        height = "fill",
        children = {
            column(core.merge({
                width = "fill",
                height = "fill",
                scroll = offset,
                geometry = view,
                children = { rect { width = "fill", geometry = body, children = { opts.child } } },
            }, opts.props)),
            rect {
                width = KNOB.width,
                height = knob:map(function(k) return k and k.height or 0 end),
                radius = theme.CAPSULE,
                align_h = "end",
                margin = knob:map(function(k) return { right = KNOB.inset, top = k and k.top or 0 } end),
                background = theme.c.scroll_knob,
                hittable = false,
                opacity = computed({ knob, pulse(offset, KNOB.linger) }, function(k, moving) return k and moving and 1 or 0 end),
                animate = { opacity = theme.motion.fade },
            },
        },
    }
end

return M
