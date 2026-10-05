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
glass.theme.appearance:set("light") -- optional; default "system" follows the desktop, as does glass.theme.accent
return { glass.app_window { id = "app", title = "My app", child = column { children = {
    glass.button("save", { label = "Save", kind = "default" }),
} } } }
```

## Conventions

| Rule | Detail |
| :--- | :--- |
| Install | Copy or symlink `glass/` into the config root; modules are `glass.*`, and the engine follows symlinks |
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
| Types | Every `opts` has a LuaLS class (`glass.<Name>Opts`); the editor completes and `just types` checks them |

## Components

One file per component family, in a folder per kind (below); `require("glass")` loads them all, `require("glass.<folder>.<file>")` one.
`internal/` holds shared helpers and is not public API. Every `opts` field is optional unless marked required. Fields marked
"signal" take a plain value or a signal.

Shared fields, used by most controls:

| Field | Meaning |
| :--- | :--- |
| `size` | `"mini"`, `"small"`, `"regular"` (default), `"large"`, `"xl"` |
| `disabled` | signal boolean, default false |
| `on_glass` | boolean; the kit's over-glass colour set |
| `window` | id of the window or panel whose focus the control follows; default `core.window` (only where a table lists it) |
| `name` | accessible name; default the label or `id` |
| `props` | extra node props merged over the control's own |

### Base (root)

Tokens, building blocks, glass and the overlay host; every component uses them.

#### core.lua (`glass.core`, `glass.merge`, `glass.text`, `glass.icon`, `glass.shape`)

Building blocks every component uses.

| Function | Meaning |
| :--- | :--- |
| `core.window` | Field, default `nil`. Set it to the app window's id before building controls; they then follow that window's focus and draw the inactive look while it lacks the keyboard. `opts.window` overrides; a panel passes its panel id |
| `core.active(id?)` | Signal: whether window `id` (default `core.window`) has the keyboard; always true when both are `nil` |
| `merge(into, from)` | Copies `from`'s fields onto `into`, returns `into` |
| `text(content, color, style?, props?)` | Text node; `style` is a `theme.type` key (default `"body"`); `content` and `color` take signals |
| `icon(name, color, size?, props?)` | Lucide glyph by name (string or signal; asserts it exists); `size` is the SF point size (default 16), scaled 1.4x for Lucide |
| `shape(props)` | Adds the kit's continuous corner smoothing to a rounded shape; returns `props` |
| `pressable(name, props)` | Sets `props.on_drag`, returns `held`, a boolean signal true while pressed |
| `focusable(name, props)` | For a Tab stop (needs `on_click` and `accessible_name`): accent focus ring on keyboard focus, in place of the engine outline. `props` must not set `shadows` |
| `focus_ring(accent)` | The ring as a `shadows` list |

#### material.lua (`glass.material`)

| Name | Meaning |
| :--- | :--- |
| `glass(style, props, opts?)` | Spreads `style` (name or signal) onto `props` (`background`, `shadows`, `effect`, `behind_blur`, `corner_smoothing`), following light and dark. `opts.tint`: colour or signal, for `small_tinted`; `opts.shadows`: signal of a shadow list put on top (e.g. a focus ring) |
| `vibrant(props)` | Sets `blend` so `vibrant_*` colours take the glass's tone; returns `props` |
| `LENS` | Path of `lens.frag`; default `<config>/glass/lens.frag`. Set it if `glass/` is not in the config root |
| `STYLES` | Style table. Names: `small`, `small_inactive`, `small_tinted`, `knob`, `large`, `menu`, `notification`, `sidebar`, `sidebar_inactive`, `tooltip`, and the materials `ultra_thick`, `thick`, `regular`, `thin`, `ultra_thin`. `small`, `knob` and `large` refract through the lens |

#### theme.lua (`glass.theme`)

| Name | Meaning |
| :--- | :--- |
| `appearance` | State: `"system"` (default; follows `mantle.appearance`), `"light"` or `"dark"` |
| `dark` | Signal: whether the colours are dark now |
| `accent` | State: `"system"` (default; the desktop's accent, matched to the nearest name) or a name from `ACCENTS` |
| `accent_name` | Signal: the accent in use |
| `high_contrast`, `reduced_motion` | Signals from the desktop: Increase Contrast deepens translucent labels, fills and separators; Reduce Motion swaps springs for quick ones |
| `ACCENTS` | `blue`, `purple`, `pink`, `red`, `orange`, `yellow`, `green`, `gray` |
| `c.<role>` | Live colour signal of one role (`label`, `secondary_fill`, `vibrant_label`, `accent`, `on_accent`, `window_background`, system names such as `red`, ...); follows `dark` and `accent` |
| `scheme` | Signal of the whole palette table, for `computed` |
| `pick(flag, yes, no)` | Signal of role `yes` or `no` chosen by boolean signal `flag` |
| `alpha(color, a)` | `"#RRGGBB[AA]"` at alpha 0..1 (plain string) |
| `type` | Text styles `{ size, weight, line height, tracking }`: `large_title`, `title1..3`, `headline`, `body`, `callout`, `subheadline`, `footnote`, `caption1`, `caption2`, `control`, `control_small`, `control_mini`, `window_title`, `sidebar_title` |
| `SIZES` | Per `size`: `height`, `radius`, `label` (type style), `inset`, `icon` |
| `motion` | Springs and fade: `default`, `smooth`, `snappy`, `bouncy`, `press`, `fade`; for `animate` |
| Others | `SYSTEM`, `vibrancy`, `CLEAR`, `CAPSULE`, `SMOOTHING`, `FONT`, `FONT_DISPLAY`, `WINDOW_RADIUS`, `CONTENT_INSET` |
### Chrome (`chrome/`)

Window frames, toolbar items and desktop chrome.

#### chrome/window.lua (`app_window`, `utility_window`, `window_frame`), chrome/toolbar.lua (`traffic_lights`, `toolbar_group`, `toolbar_button`, `toolbar_navigation`, `sidebar_toggle`)

Liquid Glass window chrome. `app_window` frames an app, registers the window's overlay layers and returns a `window`.

| Function | opts |
| :--- | :--- |
| `app_window(props)` | `id` (required; also the overlay host id), `title`, `subtitle`, `app_id`, `min_size`, `max_size`, `on_close`; `toolbar` (`"unified"` default, `"compact"`, `"titlebar"`); `leading`, `trailing` (lists of toolbar nodes either side of the title); `scroll_edge` (`"soft"` default fade, `"hard"` blurred band with a hairline); `sidebar` (node for the 256 px glass pane; traffic lights move into it); `child` (content; scrolls under the toolbar) |
| `traffic_lights(opts)` | `on_close`, `window`. Minimise and zoom are inert |
| `toolbar_group(id, opts)` | `items` (required; `{ icon, label, on_click, selected }`, `selected` bool or signal), `size` (`"xl"` default, `"medium"`), `window` |
| `toolbar_button(id, opts)` | One item's fields (`icon`, `label`, `on_click`, `selected`) plus `size`, `window` |

A press on empty chrome moves the window, right press opens the window menu, and the edges resize. `window.active` aliases `core.active`.

`app_window` and `window_frame` also take (see `glass.WindowFrameProps`):

| Field | Meaning |
| :--- | :--- |
| `toolbar = "expanded"` | A 33 titlebar over a 44 toolbar row of 36 px items; scroll edge 78, the sidebar list starts at 76 |
| `sidebar_shown` | State boolean, default its own (shown). Collapsing slides the pane away (`theme.motion.smooth`); the traffic lights and a sidebar toggle join the toolbar. The pane's own toggle sits at its trailing edge |
| `inspector`, `inspector_shown`, `inspector_width` | A node for a trailing glass pane (not in the kit: mirrors the sidebar), a state boolean, the opening width (256) |
| edge drag | The sidebar's edge drags between 180 and 400, the inspector's between 200 and 400 (not in the kit: as native apps); widths are named state per window `id` |
| `kind = "utility"`, `tabs`, `tab` | A 15 px utility panel: 10 px lights on a 17 px pitch, a 24 px titlebar, or with `tabs` (`{ icon, label, value }`) a 56 px toolbar with 44x28 tabs, the selected on small glass; `tab` is the selected value state |

| Function | opts |
| :--- | :--- |
| `window_frame(props)` | The framed node `app_window` puts in its surface: chrome, panes, content, corners and shadow, without the `window`, shadow band or resize grips. `preview = true` draws it inline (no drag or menu, looks active; `active` overrides). `id` must be unique per frame |
| `utility_window(props)` | `app_window` with `kind = "utility"` |
| `toolbar_navigation(id, opts)` | Back and forward capsule: `can_back`, `can_forward` (boolean or signal, default true), `on_back`, `on_forward`, `size` (`"xl"` 73x36 default, `"medium"` 55x24), `window`, `active` |
| `sidebar_toggle(id, opts)` | `shown` (required state boolean), `size`, `window`, `active` |

`traffic_lights` also takes `kind = "utility"` and `active`; `toolbar_group`, `toolbar_button` and `sidebar` take `active` (a signal that replaces the window's focus, for previews); a toolbar item takes `disabled`.

#### chrome/desktop.lua (`menu_bar`, `dock`)

Desktop chrome for a shell: put them in a `panel` and return `glass.overlay.popup(<panel id>)` beside it.

| Function | opts |
| :--- | :--- |
| `menu_bar(id, opts)` | `menus` (`{ title?, icon?, bold?, items }`; a click opens one, moving along the bar switches while one is open), `trailing` (status nodes), `ink` (title colour; default white), `window` |
| `dock(id, opts)` | `items` (`{ label?, icon?, color? (a `theme.SYSTEM` name), image?, running?, on_click? }` or `{ separator = true }`; labels show as tooltips), `window` |

### Controls (`controls/`)

Buttons, toggles, sliders and indicators.

#### controls/button.lua (`button`, `arrow_button`)

Push buttons and the arrow button.

| Function | opts |
| :--- | :--- |
| `button(id, opts)` | `kind` (`"bordered"` default, `"default"`, `"destructive"`, `"default_destructive"`, `"tinted"`, `"borderless"`, `"toggle"`), `size`, `label`, `icon` (leading Lucide name; alone makes a square), `value` (selected state; a `toggle` keeps its own boolean state if omitted), `disabled`, `on_glass`, `window`, `on_click`, `name` (default label, else icon), `props` |
| `arrow_button(id, opts)` | `size`, `icon` (default `"chevrons-up-down"`), `disabled`, `on_glass`, `on_click`, `name`, `props` |

#### controls/popup_button.lua (`popup_button`, `pull_down_button`)

A label and chevron that open a menu (`glass.menu`) as wide as the button.

| Function | opts |
| :--- | :--- |
| `popup_button(id, opts)` | `items` (required; strings or `{ label, value, ...menu item }`), `value` (state of the selected value; default first), `on_change(value)`, `size`, `width` (default fits label), `disabled`, `on_glass`, `name`, `props` |
| `pull_down_button(id, opts)` | `label`, `items` (menu items with `on_click`), `size`, `width`, `disabled`, `on_glass`, `name`, `props` |

#### controls/color_well.lua (`color_well`)

| Function | opts |
| :--- | :--- |
| `color_well(id, opts)` | `value` (state, `"#RRGGBB"`; default system green), `size`, `selected` (signal; the active well), `disabled`, `on_click` (open the picker), `name`, `props` |

#### controls/checkbox.lua (`checkbox`, `radio_group`)

| Function | opts |
| :--- | :--- |
| `checkbox(id, opts)` | `value` (state `true`, `false` or `"mixed"`; a click on mixed turns on), `label`, `size`, `disabled`, `on_glass`, `window`, `on_change(value)` |
| `radio_group(id, opts)` | `options` (required; labels), `value` (state of the chosen label; default first), `horizontal`, `size`, `disabled`, `on_glass`, `window`, `on_change(label)` |

#### controls/switch.lua (`switch`)

| Function | opts |
| :--- | :--- |
| `switch(id, opts)` | `value` (state boolean), `size`, `disabled`, `on_glass`, `window`, `label` (accessible name), `on_change(on)` |

#### controls/segmented_control.lua (`segmented_control`)

| Function | opts |
| :--- | :--- |
| `segmented_control(id, opts)` | `items` (required; `{ icon, label, value }`, key is `value`, else `label`, else `icon`), `value` (state of the key; with `multiple`, a set `{ [key] = true }`; default first item), `multiple`, `size`, `disabled`, `on_glass`, `window`, `on_change(value)` |

#### controls/stepper.lua (`stepper`)

| Function | opts |
| :--- | :--- |
| `stepper(id, opts)` | `value` (state number; default `max(min, 0)`), `min`, `max` (unbounded), `step` (1), `size`, `disabled`, `on_glass`, `on_change(value)` |

#### controls/slider.lua (`slider`, `circular_slider`)

| Function | opts |
| :--- | :--- |
| `slider(id, opts)` | `value` (state number; default `neutral` or `min`), `min`, `max` (0, 1), `step`, `width` (140; track is 20 px shorter), `size`, `neutral` (value; fill grows from it), `ticks` (count), `snap` (snap to ticks), `disabled`, `on_glass`, `window`, `label`, `on_change(value)`, `vertical` (upright, minimum at the bottom; `height` is then the length, default 140) |
| `circular_slider(id, opts)` | `value` (state number; default `min`), `min`, `max` (0, 1), `step`, `size`, `disabled`, `on_glass`, `label`, `on_change(value)`. Turns over 270 degrees |

#### controls/progress.lua (`progress_bar`, `progress_ring`, `spinner`)

Fills go grey while the window is inactive. `size` here is only `"small"` or `"regular"`. `id` is unused.

| Function | opts |
| :--- | :--- |
| `progress_bar(_, opts)` | `value` (0..1 number or signal), `indeterminate` (signal boolean), `size` (6 or 10 px), `width` (140), `on_glass`, `window` |
| `progress_ring(_, opts)` | `value` (0..1), `size` (16 or 32 px), `on_glass`, `window` |
| `spinner(_, opts)` | `size` (16 or 32 px), `window` |

#### controls/level_indicator.lua (`level_indicator`)

Bars go green, yellow from `warning` up, red from `critical` up. Colours go grey while the window is inactive.

| Function | opts |
| :--- | :--- |
| `level_indicator(id, opts)` | `style` (`"continuous"` default, `"discrete"` cells, `"rating"` stars), `value` (state or number; default `min`), `min` (0), `max` (1; rating 5 stars), `warning`, `critical`, `cells` (10), `editable` (rating: click or arrows set it), `width` (140), `size`, `disabled`, `window`, `on_change(value)` |

#### controls/image_well.lua (`image_well`)

The kit's 28 px well: `source` (image path), `size`, `fit` (`"contain"` default), `on_click` (makes it focusable), `label`.

### Inputs (`inputs/`)

Text entry and pickers.

#### inputs/text_field.lua, inputs/search_field.lua, inputs/combo_box.lua (`text_field`, `search_field`, `combo_box`)

Each returns `node, { value, focus() }`; wrap the call in parentheses to keep only the node. `value` (state of the text) is shared by all three.

| Function | opts |
| :--- | :--- |
| `text_field(id, opts)` | `value`, `size`, `width` (120), `placeholder`, `disabled`, `max_length`, `on_change(text)`, `on_submit(text)`, `name`, `props`. Escape passes to the window |
| `search_field(id, opts)` | As `text_field`, plus `toolbar` (on small glass; `size` `"regular"` or `"xl"`, width 149 or 159). `placeholder` defaults to `"Search"`; shows a clear button once filled; Escape clears |
| `combo_box(id, opts)` | As `text_field`, plus `items` (strings; a pick fills the field and calls `on_change`) |

#### inputs/token_field.lua (`token_field`)

Text field whose entries (Return or comma) become accent-tinted capsule tokens that wrap onto new lines. Click a token to select it (Backspace or Delete removes it); Backspace in an empty entry removes the last.

| Function | opts |
| :--- | :--- |
| `token_field(id, opts)` | `value` (state of a string list; default empty), `suggestions` (strings shown in a menu while typing, matched on their start), `placeholder` (while empty), `size`, `width` (240), `disabled`, `window`, `name`, `on_change(tokens)` |

#### inputs/date_picker.lua (`date_picker`, `calendar`)

A date is `{ year, month, day }`, plus `hour`, `minute` with `time`. Dates go through `os.time`/`os.date` with explicit times only.

| Function | opts |
| :--- | :--- |
| `date_picker(id, opts)` | `value` (state of a date; default now), `time` (adds 24 h hour and minute), `style` (`"textual"` default: fields and a stepper, Up/Down step the selected part; `"popover"`: a compact field that opens the calendar), `size`, `disabled`, `window`, `on_change(date)` |
| `calendar(id, opts)` | `value` (state of a date), `view` (state `{ year, month }` shown), `disabled`, `window`, `on_change(date)`. Month grid with previous, next and Today; selected day accent, today outlined; arrows move the day, Page Up/Down the month |

#### inputs/path_control.lua (`path_control`)

| Function | opts |
| :--- | :--- |
| `path_control(id, opts)` | `segments` (required; `{ label, icon? }`, root first, fixed at build), `style` (`"standard"` breadcrumb with chevrons, `"popup"` shows the last and lists the path in a menu), `size`, `disabled`, `on_glass`, `window`, `on_select(index)` |

### Views (`views/`)

Containers that lay out or scroll content.

#### views/sidebar.lua (`sidebar`)

Content for `app_window`'s `sidebar`: scrolling rows, folders that open in place.

| Function | opts |
| :--- | :--- |
| `sidebar(id, opts)` | `sections` (required; `{ header?, items = { { name, label, icon?, count?, children? } } }`, `children` nests to any depth), `value` (state of the selected `name`; default first item), `size` (`"small"`, `"medium"` default, `"large"`), `on_select(name)`, `window` |

#### views/disclosure.lua (`disclosure_button`, `disclosure_group`)

| Function | opts |
| :--- | :--- |
| `disclosure_button(id, opts)` | `value` (state boolean, true = expanded), `size`, `disabled`, `on_glass`, `label` (accessible name), `on_change(expanded)` |
| `disclosure_group(id, opts)` | `label`, `content` (node), `value` (state boolean), `on_change(expanded)` |

#### views/form.lua (`form_section`, `form_row`)

| Function | opts |
| :--- | :--- |
| `form_section(_, opts)` | `rows` (required; nodes, usually `form_row`; split by separators), `header`, `footer` (string or signal) |
| `form_row(id, opts)` | `label`, `subtitle`, `icon` (grey 24 px service icon), `trailing` (node, right aligned), `control` (true when `trailing` is a 24 px control: 48 high, else 40; a subtitle makes it 56), `on_click` (makes the row a Tab stop) |

#### views/group_box.lua (`group_box`)

| Function | opts |
| :--- | :--- |
| `group_box(_, opts)` | `content` (node), `title` (string or signal) |

#### views/list.lua (`list`)

Scrolling inset list on the engine's `list` node; selection is an accent fill.

| Function | opts |
| :--- | :--- |
| `list(id, opts)` | `items` (required; array or signal of arrays), `row(item, emphasized, selected)` (required; returns a node; boolean signals: `emphasized` while the row has the accent fill, so content can switch to `on_accent`; `selected` stays true while the window is inactive and the fill is grey), `key(item)` (unique string; default `tostring`), `value` (state of the selected key), `alternating` (tint every other row), `max_height` (320; longer lists scroll), `on_select(item)`, `window` |

#### views/table.lua (`table`, `outline`)

Header over a scrolling list of rows, on the engine's `list` node. Selection is an accent fill, grey while the window is inactive. Keys: Up/Down (Shift extends), Home/End, Page Up/Down, Return, Ctrl+A, Space toggles, type-to-select on the first column; double-click or Return calls `on_activate`. Drag a header divider to resize.

| Function | opts |
| :--- | :--- |
| `table(id, opts)` | `columns` (required; `{ key, title, width (px or "fill"), align ("start", "center", "end"), sortable, sort_value(item), cell(item, emphasized) }`), `items` (required; array or signal; items are tables keyed by column `key`), `key(item)` (default `item.key`, `id` or `name`), `value` (state of the selected keys, a set `{ [key] = true }`), `multiple`, `sort` (state `{ key, ascending }`), `alternating`, `max_height` (320), `on_sort(sort)`, `on_activate(item)`, `window`. Ctrl-click toggles a row and Shift-click extends, with `multiple`, `name` |
| `outline(id, opts)` | The same, for items with a `children` array. Adds `expanded` (state set of open keys); Left collapses or goes to the parent, Right expands or goes to the first child |

#### views/tab_view.lua (`tab_view`)

| Function | opts |
| :--- | :--- |
| `tab_view(id, opts)` | `tabs` (required; `{ name, label, icon, content }`), `value` (state of the tab name; default first), `size`, `height` (minimum box height), `window`, `on_change(name)` |

#### views/scroll_view.lua (`scroll_view`)

A scrolling area that fills its parent, with the native overlay scroller: a 6 px knob at the trailing edge, shown while scrolling.

| Function | opts |
| :--- | :--- |
| `scroll_view(id, opts)` | `child` (the content), `scroll` (a `scroll(name)` signal; default its own), `props` (extra fields for the scrolling column: `padding`, `id`, ...) |

### Overlays (`overlays/`)

Layers opened over a window or panel.

#### overlays/menu.lua, popover.lua, alert.lua, tooltip.lua, notification.lua; overlay.lua (`glass.overlay`)

Layers float over a host: an `app_window` (by id) or a panel. Each opener takes `window` to pick the host (default `core.window`). One menu, popover, alert, sheet and banner is open at a time; a new one replaces it.

A panel hosts layers by returning `glass.overlay.popup("<panel id>")` among its surfaces:

```lua
return { bar, glass.overlay.popup("bar") }
```

| Function | opts |
| :--- | :--- |
| `open_menu(opts)` | `anchor` (a `geometry(name)` signal; opens under it), `items` (`{ label, icon?, shortcut?, checked?, disabled?, submenu? (items), on_click? }`, `{ separator = true }` or `{ header = "..." }`), `on_pick(item)`, `width` (px or `"anchor"`; default 244), `align` (`"start"`, `"end"` to line up with the anchor's trailing edge), `id` (names the opener for `is_menu_open`), `window`, or `at` (`{ x, y }` in host coordinates) instead of `anchor`. Arrow keys, Enter, Escape work |
| `is_menu_open(id)` | Signal: true while the menu opened with `id` shows |
| `context_menu(id, opts)` | Wraps `child`; a right click opens `items` (a list, or a function building one per opening) at the pointer. `on_pick`, `window` |
| `bind_shortcuts(items, window?)` | Makes `items`' `shortcut`s fire their `on_click` while the window has the keyboard and nothing is open. ⌘ and ⌃ are Ctrl, ⌥ Alt, ⇧ Shift (`menu.MODIFIERS`); ⏎ ⌫ ⎋ ⇥ and arrows name keys |
| `open_popover(opts)` | `anchor` (a `geometry` signal; required), `content` (node or function returning one), `edge` (`"bottom"` default, `"top"`, `"left"`, `"right"`: side of the anchor), `width` (230), `window`. Closes on outside click and Escape |
| `open_alert(opts)` | `title` (required), `message`, `icon` (Lucide), `buttons` (`{ label, kind?, on_click? }`; `kind` `"default"` accent, `"destructive"` red, else plain; each closes the alert then runs `on_click`; Escape runs the first plain one), `suppression` (`{ label?, value? }`; "do not show again" checkbox, `value` a state), `window` |
| `open_sheet(opts)` | `content` (node, or `function(close)` returning one), `width` (390), `window`. Close with `close` or `overlay.close("glass_sheet")` |
| `open_notification(opts)` | `title`, `body`, `icon` (default `"bell"`), `app` (right caption, default `"now"`), `window`. Dismisses after 5 s or on click |
| `tooltip(id, opts)` | `child` (wrapped node), `label`, `window`. Shows 750 ms after the pointer rests; one at a time |

`glass.overlay`:

| Function | Meaning |
| :--- | :--- |
| `close(id)` | Closes layer `id` (`"glass_menu"`, `"glass_popover"`, `"glass_alert"`, `"glass_sheet"`, `"glass_notify"`) on every host |
| `close_all()` | Closes every layer and the tooltip |
| `is_open(id)` | Signal: whether layer `id` is open |
| `bounds(host)` | The `geometry` signal of host `host`'s root |
| `popup(parent)` | The panel surface above |
| `layer(id, build, handlers?)`, `open(id, data, host)` | Register and show a custom layer; `handlers.escape()`, `handlers.key(key)` |
