-- Shared by the sidebar and the disclosure group: content that opens and closes in place.
local theme = require("glass.theme")

local M = {}

-- not in the kit: the kit has no motion for disclosure; 200 ms ease-out, as native apps animate it.
local OPEN = { duration = 200, easing = "out_quad" }

-- `node` shown while the state `open` is true: the box eases to the content's height, which is
-- cut to it, and the content fades. `padding` is inside the box, so it opens and closes too.
function M.reveal(open, node, padding)
    return rect {
        width = "fill",
        clip = "box",
        animate = { height = OPEN },
        children = {
            column {
                width = "fill",
                padding = padding,
                visible = open,
                opacity = open:map(function(o) return o and 1 or 0 end),
                animate = { opacity = theme.motion.fade },
                children = { node },
            },
        },
    }
end

return M
