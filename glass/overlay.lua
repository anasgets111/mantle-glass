-- Layers over a window or panel: menus, popovers, alerts, sheets and the tooltip. `M.layer(id, build)`
-- registers a builder, `M.open(id, data, host)` shows it on top of `host`'s stack, `M.close(id)`
-- removes it with its `exit`. `build(data)` returns a node whose `id` is the layer's own, usually a
-- full-host rect whose `on_click` closes it. A host is an `app_window` (its own id) or a panel that
-- returns `M.popup(id)` among its surfaces; `host` defaults to `core.window`. One layer per kind
-- is open at a time across hosts: opening a menu on one host closes the menu on another.
local core = require("glass.core")

local M = {}

local shown = state("glass_layers", {})
local builders, escapes, key_handlers, fallbacks = {}, {}, {}, {}
-- A reload rebuilds the builders and the data they close over, so layers left open by the last
-- generation close instead of building from stale data.
if #(shown:get() or {}) > 0 then
    shown:set({})
end

-- `handlers` (optional): `escape()` replaces the default close when Escape reaches this layer;
-- `key(key)` receives the window's unhandled keys while this layer is on top.
---@param id string
---@param build fun(data: table): Node
---@param handlers? { escape?: fun(), key?: fun(key: KeyPress): boolean? }
function M.layer(id, build, handlers)
    builders[id] = build
    escapes[id] = handlers and handlers.escape
    key_handlers[id] = handlers and handlers.key
end

---@param id string
function M.close(id)
    local kept = {}
    for _, layer in ipairs(shown:get() or {}) do
        if layer.id ~= id then
            kept[#kept + 1] = layer
        end
    end
    shown:set(kept)
end

---@param id string
---@param data? table
---@param host? string
function M.open(id, data, host)
    M.close(id)
    local layers = { table.unpack(shown:get() or {}) }
    layers[#layers + 1] = { id = id, data = data or {}, host = host or core.window }
    shown:set(layers)
end

---@param id string
---@return Signal<boolean>
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

-- A layer opened with no host shows on the first window root built.
local first_root
local function on(layer, host)
    return layer.host == host or (layer.host == nil and host == first_root)
end

-- The `geometry` handle of host `id`'s root, for a layer to keep inside it.
---@param host string
---@return Signal<table>
function M.bounds(host)
    return geometry("glass_root_" .. host)
end

-- Tooltip: one at a time, over everything. `build(anchor, bounds)` gets the anchor's and the host's
-- `geometry` signals and returns the tip node; the layer lets the pointer through.
---@type StateSignal<table|false>
local tip = state("glass_tip", false)
local tip_builders = {}
if tip:get() then
    tip:set(false)
end

function M.show_tip(id, anchor_name, build, host)
    tip_builders[id] = build
    tip:set({ id = id, anchor = anchor_name, host = host or core.window })
end

function M.hide_tip(id)
    local now = tip:get()
    if now and now.id == id then
        tip:set(false)
    end
end

local function tip_layer(t, host)
    local build = t and on(t, host) and tip_builders[t.id]
    if not build then
        return nil
    end
    return rect {
        id = "tip_" .. t.id,
        width = "fill",
        height = "fill",
        hittable = false,
        children = { build(geometry(t.anchor), M.bounds(host)) },
    }
end

-- Closes every layer, e.g. when the page changes under them.
function M.close_all()
    shown:set({})
    tip:set(false)
end

local function top_of(host)
    local layers = shown:get() or {}
    for i = #layers, 1, -1 do
        if on(layers[i], host) then
            return layers[i]
        end
    end
end

-- Escape closes `host`'s topmost layer.
function M.escape(host)
    local top = top_of(host)
    if top then
        (escapes[top.id] or function() M.close(top.id) end)()
    end
end

-- A key no focused control took: `host`'s top layer's key handler gets it.
function M.key(host, key)
    local top = top_of(host)
    local handle = top and key_handlers[top.id]
    if handle and handle(key) then
        return true
    end
    for _, fallback in ipairs(top and {} or fallbacks[host] or {}) do
        if fallback(key) then
            return true
        end
    end
    return false
end

-- `fn(key)` sees `host`'s keys that no control or open layer took, e.g. menu shortcuts.
---@param host string
---@param fn fun(key: KeyPress): boolean?
function M.on_key(host, fn)
    fallbacks[host] = fallbacks[host] or {}
    table.insert(fallbacks[host], fn)
end

local function stack(host, base)
    return computed({ shown, tip }, function(layers, t)
        local kids = { base }
        for _, layer in ipairs(layers or {}) do
            local build = on(layer, host) and builders[layer.id]
            if build then
                kids[#kids + 1] = build(layer.data)
            end
        end
        kids[#kids + 1] = tip_layer(t, host)
        return kids
    end)
end

-- Window `host`'s root children: `base`, then its layers in opening order, the tooltip on top.
-- Give the root `geometry = overlay.bounds(host)`.
function M.root(base, host)
    first_root = first_root or host
    return stack(host, base)
end

-- A transparent popup over panel `parent` that draws its layers past the panel's bounds. Return it
-- with the panel's surfaces: `return { bar, glass.overlay.popup("bar") }`.
---@param parent string
---@return Surface
function M.popup(parent)
    local mine = computed({ shown, tip }, function(layers, t)
        local any, modal = false, false
        for _, layer in ipairs(layers or {}) do
            if on(layer, parent) then
                any, modal = true, true
            end
        end
        return { any = any or (t and on(t, parent)) or false, modal = modal }
    end)
    -- The popup hangs from the panel's top left corner, a screen in size so layers place in the
    -- panel's coordinates.
    local size = mantle.screens:map(function(screens)
        local w, h = 1920, 1080
        for _, s in ipairs(screens or {}) do
            w, h = math.max(w, s.width), math.max(h, s.height)
        end
        return { width = w, height = h }
    end)
    return popup {
        id = "glass_overlay_" .. parent,
        parent = parent,
        anchor_rect = { x = 0, y = 0, width = 1, height = 1 },
        anchor = "top_left",
        gravity = "bottom_right",
        constraint_adjustment = {},
        background = "#00000000",
        visible = mine:map(function(m) return m.any end),
        grab = mine:map(function(m) return m.modal end),
        on_escape = function() M.escape(parent) end,
        on_dismiss = function()
            local kept = {}
            for _, layer in ipairs(shown:get() or {}) do
                if not on(layer, parent) then
                    kept[#kept + 1] = layer
                end
            end
            shown:set(kept)
            M.hide_tip((tip:get() or {}).id)
        end,
        child = rect {
            width = size:map(function(s) return s.width end),
            height = size:map(function(s) return s.height end),
            geometry = M.bounds(parent),
            on_key = function(key) return M.key(parent, key) end,
            children = stack(parent, nil),
        },
    }
end

return M
