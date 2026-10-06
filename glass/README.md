# glass

The `glass` module of [mantle-glass](../README.md): Liquid Glass controls for a
Mantle config. Sizes, colours, glass layers and shadows follow Liquid Glass's design; values that had to
be chosen are marked `not in the kit` where they are set.

## Requirements

Mantle newer than v0.4.0 (main at `0ae7b857` or later): the glass, focus, multiline and edit features
it uses are not in a release yet. Fonts: Inter and Inter Display (standing in for SF Pro) and Lucide
(`ttf-lucide-font`, standing in for SF Symbols). Set `glass.material.LENS` if `glass/` is not in the
config root.

## Setup

```lua
fonts { "Inter", "lucide", "Noto Sans" }
local glass = require("glass")
glass.theme.appearance:set("light") -- optional; default "system" follows the desktop, as does glass.theme.accent
return { glass.app_window { id = "app", title = "My app", child = column { children = {
    glass.button("save", { label = "Save", kind = "primary" }),
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
| Variants | `opts.kind` picks the native style; `opts.size` the control size: `"xs"`, `"s"`, `"m"` (default), `"l"`, `"xl"` (`theme.SIZES`) |
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
| `size` | `"xs"`, `"s"`, `"m"` (default), `"l"`, `"xl"` |
| `disabled` | signal boolean, default false |
| `on_glass` | boolean; the kit's over-glass colour set |
| `window` | id of the window or panel whose focus the control follows; default `core.window` (only where a table lists it) |
| `name` | accessible name; default the label or `id` |
| `props` | extra node props merged over the control's own |

### Base (root)

Tokens, building blocks, glass and the overlay host; every component uses them.

#### core.lua (`glass.core`, `glass.merge`, `glass.text`, `glass.icon`, `glass.focusable`; `glass.core.shape` is the corner-smoothing helper)

Building blocks every component uses.

| Function | Meaning |
| :--- | :--- |
| `core.window` | Field, default `nil`. Set it to the app window's id before building controls; they then follow that window's focus and draw the inactive look while it lacks the keyboard. `opts.window` overrides; a panel passes its panel id |
| `core.active(id?)` | Signal: whether window `id` (default `core.window`) has the keyboard; always true when both are `nil` |
| `merge(into, from)` | Copies `from`'s fields onto `into`, returns `into` |
| `text(content, color, style?, props?)` | Text node; `style` is a `theme.type` key (default `"body"`); `content` and `color` take signals |
| `icon(name, color, size?, props?)` | Lucide glyph by name (string or signal; asserts it exists). The names shared with `m3` (`close`, `add`, `delete`, `home`, `more`, `warning`, `chevron_down`, ... `SHARED` in `core.lua`) resolve first; `size` is the SF point size (default 16), scaled 1.4x for Lucide |
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
| `c.<role>` | Live colour signal of one role (`label`, `secondary_fill`, `vibrant_label`, `accent`, `on_accent`, `window_background`, system names such as `red`, ...); follows `dark` and `accent`. Roles shared with `m3`: `accent`, `on_accent`, `text` (`label`), `text_secondary` (`secondary_label`), `text_disabled` (`tertiary_label`), `background` (`window_background`), `container` (`secondary_fill` over `background`, opaque), `container_raised` (`fill`), `separator`, `error` (`red`), `on_error` (`on_accent`), `success` (`green`), `warning` (`orange`) |
| `scheme` | Signal of the whole palette table, for `computed` |
| `pick(flag, yes, no)` | Signal of role `yes` or `no` chosen by boolean signal `flag` |
| `alpha(color, a)` | `"#RRGGBB[AA]"` at alpha 0..1 (plain string) |
| `type` | Text styles `{ size, weight, line height, tracking }`: `large_title`, `title1..3`, `headline`, `body`, `callout`, `subheadline`, `footnote`, `caption1`, `caption2`, `control`, `control_small`, `control_mini`, `window_title`, `sidebar_title`. Shared with `m3`: `title` (`title1`), `headline`, `body`, `label` (`control`), `caption` (`caption1`) |
| `SIZES` | Per `size`: `height`, `radius`, `label` (type style), `inset`, `icon` |
| `motion` | Springs and fade: `default`, `smooth`, `snappy`, `bouncy`, `press`, `fade`, and the shared `fast` (`snappy`), `slow` (`smooth`); for `animate` |
| Others | `SYSTEM`, `vibrancy`, `CLEAR`, `CAPSULE`, `SMOOTHING`, `FONT`, `FONT_DISPLAY`, `WINDOW_RADIUS`, `CONTENT_INSET` |
### Chrome (`chrome/`)

Window frames, toolbar items and desktop chrome.

#### chrome/window.lua (`app_window`, `utility_window`, `window_frame`), chrome/toolbar.lua (`traffic_lights`, `toolbar_group`, `toolbar_button`, `toolbar_navigation`, `sidebar_toggle`)

Liquid Glass window chrome. `app_window` frames an app, registers the window's overlay layers and returns a `window`.

| Function | opts |
| :--- | :--- |
| `app_window(props)` | `id` (required; also the overlay host id), `title`, `subtitle`, `app_id`, `min_size`, `max_size`, `on_close`; `toolbar` (`"unified"` default, `"compact"`, `"titlebar"`); `leading`, `trailing` (lists of toolbar nodes either side of the title); `scroll_edge` (`"soft"` default fade, `"hard"` blurred band with a hairline); `sidebar` (node for the 256 px glass pane; traffic lights move into it); `child` (content; scrolls under the toolbar) Shared with m3: `navigation = { items = { { name, label?, icon?, badge? } }, value, header?, on_select? }` draws the sidebar (unless `sidebar` is given), and `actions = { { icon, label?, on_click?, menu? } }` a toolbar group at the end. |
| `traffic_lights(opts)` | `on_close`, `window`. Minimise and zoom are inert |
| `toolbar_group(id, opts)` | `items` (required; `{ icon, label, on_click, selected }`, `selected` bool or signal), `size` (`"xl"` default, `"m"`), `window` Items also take `menu` (menu items opened under the button) and `disabled`. |
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
| `min_content` | Default 500 (not in the kit). When the window leaves less than this beside the sidebar, the sidebar hides as if toggled and returns when widened; `sidebar_shown` stays the user's own choice, and while narrow the toggle opens the pane on its own. 0 turns it off |
| `tabs`, `tab`, `on_new_tab`, `on_close_tab` | On any other window: a native window tab bar (34 px, not in the kit) under the toolbar. `tabs` is `{ name, title }[]` or a signal of one; equal-width tabs on a fill strip, the selected raised on small glass, a close button on the hovered tab, a + after the strip. `tab` is the selected name (state; default the first), `on_close_tab(name)` and `on_new_tab()` change the list: the app edits `tabs` and picks the next `tab`, and switches its content on `tab` |

| Function | opts |
| :--- | :--- |
| `window_frame(props)` | The framed node `app_window` puts in its surface: chrome, panes, content, corners and shadow, without the `window`, shadow band or resize grips. `preview = true` draws it inline (no drag or menu, looks active; `active` overrides). `id` must be unique per frame |
| `utility_window(props)` | `app_window` with `kind = "utility"` |
| `toolbar_navigation(id, opts)` | Back and forward capsule: `can_back`, `can_forward` (boolean or signal, default true), `on_back`, `on_forward`, `size` (`"xl"` 73x36 default, `"m"` 55x24), `window`, `active` |
| `sidebar_toggle(id, opts)` | `shown` (required state boolean), `size`, `window`, `active` |

`traffic_lights` also takes `kind = "utility"` and `active`; `toolbar_group`, `toolbar_button` and `sidebar` take `active` (a signal that replaces the window's focus, for previews); a toolbar item takes `disabled`.

#### chrome/desktop.lua (`menu_bar`, `dock`)

Desktop chrome for a shell: put them in a `panel` and return `glass.overlay.popup(<panel id>)` beside it.

| Function | opts |
| :--- | :--- |
| `menu_bar(id, opts)` | `menus` (`{ title?, icon?, bold?, items }`; a click opens one, moving along the bar switches while one is open), `trailing` (status nodes), `ink` (title colour; default white), `window` |
| `dock(id, opts)` | `items` (`{ label?, icon?, color? (a `theme.SYSTEM` name), image?, running?, bouncing?, on_click? }` or `{ separator = true }`; labels show as tooltips; `bouncing`, boolean or signal, hops the icon while true), `magnify` (icons near the pointer swell to 1.6x, neighbours less, and the shelf grows; the icon under the pointer stays put), `window` |

### Controls (`controls/`)

Buttons, toggles, sliders and indicators.

#### controls/button.lua (`button`, `arrow_button`)

Push buttons, the icon button and the arrow button.

| Function | opts |
| :--- | :--- |
| `button(id, opts)` | `kind` (`"secondary"` default, `"primary"`, `"destructive"`, `"tinted"`, `"plain"`, `"default_destructive"`, `"toggle"`), `size`, `label`, `icon` (leading shared icon name or Lucide name; alone makes a square), `value` (makes it a toggle: a click flips it; the `toggle` kind keeps its own boolean state if omitted), `width` (fixed px), `disabled`, `on_glass`, `window`, `on_click`, `name` (default label, else icon), `props` |
| `icon_button(id, opts)` | Required `icon` (shared icon name or Lucide name), no label: a square of the control's height. `kind`, `size`, `value`, `width`, `name` (default the icon), `disabled`, `on_glass`, `window`, `on_click`, `props` |
| `arrow_button(id, opts)` | `size`, `icon` (default `"chevrons-up-down"`), `disabled`, `on_glass`, `on_click`, `name`, `props` |

#### controls/dropdown.lua (`dropdown`, `pull_down_button`)

A label and chevron that open a menu (`glass.menu`) as wide as the button.

| Function | opts |
| :--- | :--- |
| `dropdown(id, opts)` | `items` (required; strings or `{ label, value, ...menu item }`), `value` (state of the selected value; default first), `on_change(value)`, `size`, `width` (default fits label), `disabled`, `on_glass`, `name`, `props` |
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
| `switch(id, opts)` | `value` (state boolean), `size`, `disabled`, `on_glass`, `window`, `name`, `on_change(on)` |

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
| `slider(id, opts)` | `value` (state number; default `neutral` or `min`), `min`, `max` (0, 1), `step`, `width` (140; track is 20 px shorter), `size`, `neutral` (value; fill grows from it), `ticks` (count), `snap` (snap to ticks), `disabled`, `on_glass`, `window`, `name`, `on_change(value)`, `vertical` (upright, minimum at the bottom; `height` is then the length, default 140) |
| `circular_slider(id, opts)` | `value` (state number; default `min`), `min`, `max` (0, 1), `step`, `size`, `disabled`, `on_glass`, `name`, `on_change(value)`. Turns over 270 degrees |

#### controls/progress.lua (`progress_bar`, `progress_ring`, `spinner`)

Fills go grey while the window is inactive. `size` here is only `"s"` or `"m"`. `id` is unused.

| Function | opts |
| :--- | :--- |
| `progress_bar(_, opts)` | `value` (0..1 number or signal), `indeterminate` (signal boolean), `size` (6 or 10 px), `width` (140), `on_glass`, `window` |
| `progress_ring(_, opts)` | `value` (0..1), `size` (16 or 32 px), `on_glass`, `window` `indeterminate` (boolean or signal) shows the spinner instead, as this platform draws indefinite waits. |
| `spinner(_, opts)` | `size` (16 or 32 px), `window` |

#### controls/level_indicator.lua (`level_indicator`)

Bars go green, yellow from `warning` up, red from `critical` up. Colours go grey while the window is inactive.

| Function | opts |
| :--- | :--- |
| `level_indicator(id, opts)` | `style` (`"continuous"` default, `"discrete"` cells, `"rating"` stars), `value` (state or number; default `min`), `min` (0), `max` (1; rating 5 stars), `warning`, `critical`, `cells` (10), `editable` (rating: click or arrows set it), `width` (140), `size`, `disabled`, `window`, `on_change(value)` |

#### controls/image_well.lua (`image_well`)

The kit's 28 px well: `source` (image path), `size`, `fit` (`"contain"` default), `on_click` (makes it focusable), `name`.

### Inputs (`inputs/`)

Text entry and pickers.

#### inputs/text_field.lua, inputs/search_field.lua, inputs/combo_box.lua (`text_field`, `search_field`, `combo_box`)

Each returns `node, { value, focus, clear, set }`; wrap the call in parentheses to keep only the node. `value` (state of the text) is shared by all three.

| Function | opts |
| :--- | :--- |
| `text_field(id, opts)` | `value`, `size`, `width` (120; `"fill"` when `multiline`), `placeholder`, `disabled`, `max_length`, `multiline` (several lines in a box that grows), `min_lines` (3), `max_lines` (0, no limit; past it the text scrolls), `submit_key` (`"ctrl+return"` default: Return breaks the line; `"return"`: Return submits and Shift+Return breaks, for a chat box), `window`, `on_change(text)`, `on_submit(text)`, `name`, `props`. Escape passes to the window |
| `search_field(id, opts)` | As `text_field`, plus `toolbar` (on small glass; `size` `"m"` or `"xl"`, width 149 or 159). `placeholder` defaults to `"Search"`; shows a clear button once filled; Escape clears |
| `combo_box(id, opts)` | As `text_field`, plus `items` (strings; a pick fills the field and calls `on_change`) |

#### inputs/token_field.lua (`token_field`)

Text field whose entries (Return or comma) become accent-tinted capsule tokens that wrap onto new lines. Click a token to select it (Backspace or Delete removes it); Backspace in an empty entry removes the last.

| Function | opts |
| :--- | :--- |
| `token_field(id, opts)` | `value` (state of a string list; default empty), `suggestions` (strings shown in a menu while typing, matched on their start; Up/Down highlight one, Return or Tab picks it), `placeholder` (while empty), `size`, `width` (240), `disabled`, `window`, `name`, `on_change(tokens)` |

#### inputs/date_picker.lua (`date_picker`, `calendar`)

A date is `{ year, month, day }`, plus `hour`, `minute` with `time`. Dates go through `os.time`/`os.date` with explicit times only.

| Function | opts |
| :--- | :--- |
| `date_picker(id, opts)` | `value` (state of a date; default now), `time` (adds 24 h hour and minute), `style` (`"textual"` default: fields and a stepper, Up/Down step the selected part, digits fill it and move on once it is full or the next digit could not fit, Backspace empties it; `"popover"`: a compact field that opens the calendar), `size`, `disabled`, `window`, `on_change(date)` |
| `calendar(id, opts)` | `value` (state of a date), `view` (state `{ year, month }` shown), `disabled`, `window`, `on_change(date)`. Month grid with previous, next and Today; selected day accent, today outlined; arrows move the day, Page Up/Down the month |

#### inputs/path_control.lua (`path_control`)

| Function | opts |
| :--- | :--- |
| `path_control(id, opts)` | `segments` (required; `{ label, icon? }`, root first; a list or a signal of one), `style` (`"standard"` breadcrumb with chevrons, `"popup"` shows the last and lists the path in a menu), `size`, `disabled`, `on_glass`, `window`, `on_select(index)` |

### Views (`views/`)

Containers that lay out or scroll content.

#### views/sidebar.lua (`sidebar`)

Content for `app_window`'s `sidebar`: scrolling rows, folders that open in place.

| Function | opts |
| :--- | :--- |
| `sidebar(id, opts)` | `sections` (required; `{ header?, items = { { name, label, icon?, count?, children? } } }`, `children` nests to any depth), `value` (state of the selected `name`; default first item), `size` (`"s"`, `"m"` default, `"l"`), `on_select(name)`, `window` |

#### views/disclosure.lua (`disclosure_button`, `disclosure_group`)

| Function | opts |
| :--- | :--- |
| `disclosure_button(id, opts)` | `value` (state boolean, true = expanded), `size`, `disabled`, `on_glass`, `name`, `on_change(expanded)` |
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

#### views/divider.lua (`divider`)

| Function | opts |
| :--- | :--- |
| `divider(id?, opts)` | A 1 px hairline in `c.separator`. `vertical` (default horizontal), `inset` (px trimmed from both ends), `props` |

#### views/list.lua (`list`)

Scrolling inset list on the engine's `list` node; selection is an accent fill. The overlay scroller knob shows while it scrolls.

| Function | opts |
| :--- | :--- |
| `list(id, opts)` | `items` (required; array or signal of arrays), `row(item, emphasized, selected)` (returns a node; default draws a string or `{ label, icon? }` item; boolean signals: `emphasized` while the row has the accent fill, so content can switch to `on_accent`; `selected` stays true while the window is inactive and the fill is grey), `key(item)` (unique string; default the item's `label`, else `tostring`), `value` (state of the selected key), `alternating` (tint every other row), `max_height` (320; longer lists scroll), `on_select(item)`, `window` |

#### views/table.lua (`table`, `outline`)

Header over a scrolling list of rows, on the engine's `list` node. Selection is an accent fill, grey while the window is inactive. Keys: Up/Down (Shift extends), Home/End, Page Up/Down, Return, Ctrl+A, Space toggles, type-to-select on the first column; double-click or Return calls `on_activate`. Drag a header divider to resize. Columns wider than the table (`"fill"` counts 120 px) scroll sideways, header and rows together, with a horizontal knob; Left and Right (table) or Shift+wheel over the header scroll it. Both overlay knobs show while scrolling.

| Function | opts |
| :--- | :--- |
| `table(id, opts)` | `columns` (required; `{ key, title, width (px or "fill"), align ("start", "center", "end"), sortable, sort_value(item), cell(item, emphasized) }`), `items` (required; array or signal; items are tables keyed by column `key`), `key(item)` (default `item.key`, `id` or `name`), `value` (state of the selected keys, a set `{ [key] = true }`), `multiple`, `sort` (state `{ key, ascending }`), `alternating`, `max_height` (320), `on_sort(sort)`, `on_activate(item)`, `window`. Ctrl-click toggles a row and Shift-click extends, with `multiple`, `name` |
| `outline(id, opts)` | The same, for items with a `children` array. Adds `expanded` (state set of open keys); Left collapses or goes to the parent, Right expands or goes to the first child |

#### views/tabs.lua (`tabs`)

| Function | opts |
| :--- | :--- |
| `tabs(id, opts)` | `items` (required; `{ name, label, icon, content }`), `value` (state of the tab name; default first), `size`, `height` (minimum box height), `window`, `on_change(name)` |

#### views/scroll_view.lua (`scroll_view`)

A scrolling area that fills its parent, scrolling smoothly as native apps do, with the overlay scroller: a 6 px knob at the trailing edge, shown while scrolling or while the pointer is in its 12 px strip, where it widens over a faint track; the knob drags and a track click pages. `table` and `list` share it.

| Function | opts |
| :--- | :--- |
| `scroll_view(id, opts)` | `child` (the content), `scroll` (a `scroll(name)` signal; default its own), `props` (extra fields for the scrolling column: `padding`, `id`, ...) |
| `knob(name, scroll, view, content, horizontal?)` | The scroller node for your own scroller: a unique `name`, the `scroll` signal, the viewport's `geometry` signal and a signal of the content's length on the axis. Put it in a stacking parent beside the viewport; build it once, not in a map |
| `ease(name)` | The scroll ease for your own viewport (`animate = { scroll = ease(name) }`): native smooth scrolling, instant while knob `name` is held. `scroll_view`, `list` and `table` use it |
| `dragging(name)` | State: true while knob `name` is held |

### Overlays (`overlays/`)

Layers opened over a window or panel.

#### overlays/menu.lua, popover.lua, dialog.lua, tooltip.lua, notification.lua; overlay.lua (`glass.overlay`)

Layers float over a host: an `app_window` (by id) or a panel. Each opener takes `window` to pick the host (default `core.window`). One menu, popover, dialog, sheet and banner is open at a time; a new one replaces it.

A panel hosts layers by returning `glass.overlay.popup("<panel id>")` among its surfaces:

```lua
return { bar, glass.overlay.popup("bar") }
```

| Function | opts |
| :--- | :--- |
| `open_menu(opts)` | `anchor` (a `geometry(name)` signal; opens under it), `items` (`{ label, icon?, shortcut?, checked?, disabled?, submenu? (items), on_click? }`, `{ separator = true }` or `{ header = "..." }`), `on_pick(item)`, `width` (px or `"anchor"`; default 244), `align` (`"start"`, `"end"` to line up with the anchor's trailing edge), `id` (names the opener for `is_menu_open`), `window`, or `at` (`{ x, y }` in host coordinates) instead of `anchor`. Arrow keys, Enter, Escape work. A menu that would pass the window's edge flips above its anchor (or slides up) and slides left; a submenu opens to the left when the right has no room |
| `menu_highlighted()` | The row the open menu highlights, or nil: for an opener whose own keys steer the menu |
| `pick_highlighted(id?)` | Picks the highlighted row as Enter does; false when none is, or the open menu is not `id`'s |
| `is_menu_open(id)` | Signal: true while the menu opened with `id` shows |
| `context_menu(id, opts)` | Wraps `child`; a right click opens `items` (a list, or a function building one per opening) at the pointer. `on_pick`, `window` |
| `bind_shortcuts(items, window?)` | Makes `items`' `shortcut`s fire their `on_click` while the window has the keyboard and nothing is open. ⌘ and ⌃ are Ctrl, ⌥ Alt, ⇧ Shift (`menu.MODIFIERS`); ⏎ ⌫ ⎋ ⇥ and arrows name keys |
| `open_popover(opts)` | `anchor` (a `geometry` signal; required), `content` (node or function returning one), `edge` (`"bottom"` default, `"top"`, `"left"`, `"right"`: side of the anchor; it flips to the opposite side when only that has room in the window, and slides, the arrow keeping to the anchor, to stay inside it), `width` (230), `window`. Closes on outside click and Escape |
| `open_dialog(opts)` | `title` (required), `message`, `icon` (Lucide), `buttons` (`{ label, kind?, on_click? }`; `kind` `"primary"` accent, `"destructive"` red, `"plain"` default; each closes the dialog then runs `on_click`; Escape runs the first plain one), `suppression` (`{ label?, value? }`; "do not show again" checkbox, `value` a state), `window` |
| `open_sheet(opts)` | `content` (node, or `function(close)` returning one), `width` (390), `window`. Close with `close` or `overlay.close("glass_sheet")` |
| `notify(opts)` | `title`, `body`, `icon` (default `"bell"`), `app` (right caption, default `"now"`), `window`. Dismisses after 5 s or on click |
| `tooltip(id, opts)` | `child` (wrapped node), `label`, `window`. Shows 750 ms after the pointer rests; one at a time |

`glass.overlay`:

| Function | Meaning |
| :--- | :--- |
| `close(id)` | Closes layer `id` (`"glass_menu"`, `"glass_popover"`, `"glass_dialog"`, `"glass_sheet"`, `"glass_notify"`) on every host |
| `close_all()` | Closes every layer and the tooltip |
| `is_open(id)` | Signal: whether layer `id` is open |
| `bounds(host?)` | The `geometry` signal of host `host`'s root (default the first window built) |
| `popup(parent)` | The panel surface above |
| `layer(id, build, handlers?)`, `open(id, data, host)` | Register and show a custom layer; `handlers.escape()`, `handlers.key(key)` |
