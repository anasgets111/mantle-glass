# glass: Liquid Glass for Mantle

Liquid Glass controls for a Mantle config, built from Apple's UI kit. Every
size, colour, glass layer and shadow comes from the kit; the extracted values are in
`docs/spec/*.md` (regenerate with `docs/spec/kitdump.py` against the unzipped kit).

## Requirements

A Mantle build with `effect` (backdrop blur and saturate), layered `background` and `shadows` with
per-layer `blend`, inset shadows, node `blend` and `effect.shader` with `input = "backdrop"`
(refraction, `glass/lens.frag`; set `glass.material.LENS` if `glass/` is not in the config root). Fonts: Inter (stands in for SF
Pro) and Lucide (`ttf-lucide-font`, stands in for SF Symbols).

## Setup

```lua
fonts { "Inter", "lucide", "Noto Sans" }
local glass = require("glass")
glass.theme.dark:set(false)        -- optional; also glass.theme.accent ("blue", "purple", ...)
return { glass.app_window { id = "app", title = "My app", child = column { children = {
    glass.button("save", { label = "Save", kind = "default" }),
} } } }
```

## Conventions

| Rule | Detail |
| :--- | :--- |
| Call shape | `glass.<name>(id, opts)`. `id` is unique per instance and names the component's own state. `opts` is a table; every field is optional unless the doc says so |
| Values | A component holding a value takes `opts.value`, a `state(...)` signal it reads and writes. Omit it and the component keeps its own |
| Callbacks | `opts.on_<event>` (`on_click`, `on_change`, `on_close`) |
| Signals | Any display field (`label`, `icon`, `disabled`, ...) takes a plain value or a signal |
| Variants | `opts.kind` picks the native style; `opts.size` the control size: `"mini"`, `"small"`, `"regular"` (default), `"large"`, `"xl"` (`theme.SIZES`) |
| Over glass | `opts.on_glass = true` picks the kit's "Over-glass" colour set, for controls placed on glass |
| Colours | Only `glass.theme.c.<role>` signals; components never take raw colours |
| Glass | `glass.material.glass(style, props)` is the only way to make glass; components never build glass layers themselves |
| Vibrancy | Text and glyphs on glass use `vibrant_*` roles through `material.vibrant(props)` |
| Press | native controls have no hover state; `core.pressable` gives `held` for the clicked look |
| Icons | Lucide names (lucide.dev/icons) through `core.icon` |
| Layers | Openers are functions, `glass.open_<thing>(opts)`; Escape and `glass.overlay.close_all()` close them |

## Components

One file per component family; `require("glass")` loads them all, `require("glass.<file>")` one.
`internal/` holds shared helpers and is not public API.
