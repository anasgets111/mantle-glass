-- Layers over the window: menus, popovers, alerts, sheets and the tooltip. `M.layer(id, build)`
-- registers a builder, `M.open(id, data)` shows it on top, `M.close(id)` removes it with its `exit`.
-- `build(data)` returns a node whose `id` is the layer's own, usually a full-window rect whose
-- `on_click` closes it.
local M = {}

local shown = state("glass_layers", {})
local builders, escapes, key_handlers = {}, {}, {}
-- A reload rebuilds the builders and the data they close over, so layers left open by the last
-- generation close instead of building from stale data.
if #(shown:get() or {}) > 0 then
    shown:set({})
end

-- `handlers` (optional): `escape()` replaces the default close when Escape reaches this layer;
-- `key(key)` receives the window's unhandled keys while this layer is on top.
function M.layer(id, build, handlers)
    builders[id] = build
    escapes[id] = handlers and handlers.escape
    key_handlers[id] = handlers and handlers.key
end

function M.close(id)
    local kept = {}
    for _, layer in ipairs(shown:get() or {}) do
        if layer.id ~= id then
            kept[#kept + 1] = layer
        end
    end
    shown:set(kept)
end

function M.open(id, data)
    M.close(id)
    local layers = { table.unpack(shown:get() or {}) }
    layers[#layers + 1] = { id = id, data = data or {} }
    shown:set(layers)
end

function M.is_open(id)
    return shown:map(function(layers)
        for _, layer in ipairs(layers or {}) do
            if layer.id == id then
                return true
            end
        end
        return false
    end)
end

-- Tooltip: one at a time, over everything. `build(anchor)` gets the anchor's `geometry` signal and
-- returns the tip node; the layer lets the pointer through.
---@type StateSignal<table|false>
local tip = state("glass_tip", false)
local tip_builders = {}
if tip:get() then
    tip:set(false)
end

function M.show_tip(id, anchor_name, build)
    tip_builders[id] = build
    tip:set({ id = id, anchor = anchor_name })
end

function M.hide_tip(id)
    local now = tip:get()
    if now and now.id == id then
        tip:set(false)
    end
end

local tip_layer = tip:map(function(t)
    if not t then
        return nil
    end
    local build = tip_builders[t.id]
    if not build then
        return nil
    end
    return rect {
        id = "tip_" .. t.id,
        width = "fill",
        height = "fill",
        hittable = false,
        children = { build(geometry(t.anchor)) },
    }
end)

-- Closes every layer, e.g. when the page changes under them.
function M.close_all()
    shown:set({})
    tip:set(false)
end

-- Escape closes the topmost layer.
function M.escape()
    local layers = shown:get() or {}
    local top = layers[#layers]
    if top then
        (escapes[top.id] or function() M.close(top.id) end)()
    end
end

-- A key no focused control took: the top layer's key handler gets it.
function M.key(key)
    local layers = shown:get() or {}
    local top = layers[#layers]
    local handle = top and key_handlers[top.id]
    return handle and handle(key) or false
end

-- The root's children: `base`, then layers in opening order, the tooltip on top.
function M.root(base)
    return computed({ shown, tip_layer }, function(layers, tip_node)
        local kids = { base }
        for _, layer in ipairs(layers or {}) do
            local build = builders[layer.id]
            if build then
                kids[#kids + 1] = build(layer.data)
            end
        end
        kids[#kids + 1] = tip_node
        return kids
    end)
end

return M
