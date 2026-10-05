-- Liquid Glass for Mantle. `local glass = require("glass")` gives every component as
-- `glass.<name>(id, opts)`, plus `glass.theme`, `glass.material`, `glass.overlay` and `glass.icons`.
-- One component family per file: `require("glass.slider")` loads one. See glass/README.md.
return {
    theme = require("glass.theme"),
    material = require("glass.material"),
    overlay = require("glass.overlay"),
    icons = require("glass.icons"),
    -- Core
    merge = require("glass.core").merge,
    text = require("glass.core").text,
    icon = require("glass.core").icon,
    shape = require("glass.core").shape,
    -- Window
    app_window = require("glass.window").app_window,
    traffic_lights = require("glass.window").traffic_lights,
    toolbar_group = require("glass.window").toolbar_group,
    toolbar_button = require("glass.window").toolbar_button,
    -- Buttons
    button = require("glass.button").button,
    arrow_button = require("glass.button").arrow_button,
    popup_button = require("glass.popup_button").popup_button,
    pull_down_button = require("glass.popup_button").pull_down_button,
    color_well = require("glass.color_well").color_well,
    -- Toggles
    checkbox = require("glass.checkbox").checkbox,
    radio_group = require("glass.checkbox").radio_group,
    switch = require("glass.switch").switch,
    segmented_control = require("glass.segmented_control").segmented_control,
    stepper = require("glass.stepper").stepper,
    -- Sliders and progress
    slider = require("glass.slider").slider,
    circular_slider = require("glass.slider").circular_slider,
    progress_bar = require("glass.progress").progress_bar,
    progress_ring = require("glass.progress").progress_ring,
    spinner = require("glass.progress").spinner,
    -- Text input
    text_field = require("glass.text_field").text_field,
    search_field = require("glass.search_field").search_field,
    combo_box = require("glass.combo_box").combo_box,
    -- Sidebar, forms and lists
    sidebar = require("glass.sidebar").sidebar,
    disclosure_button = require("glass.disclosure").disclosure_button,
    disclosure_group = require("glass.disclosure").disclosure_group,
    form_section = require("glass.form").form_section,
    form_row = require("glass.form").form_row,
    group_box = require("glass.group_box").group_box,
    list = require("glass.list").list,
    -- Menus, popovers, alerts and notifications
    open_menu = require("glass.menu").open_menu,
    menu_open = require("glass.menu").menu_open,
    open_popover = require("glass.popover").open_popover,
    open_alert = require("glass.alert").open_alert,
    open_sheet = require("glass.alert").open_sheet,
    tooltip = require("glass.tooltip").tooltip,
    notify = require("glass.notification").notify,
}
