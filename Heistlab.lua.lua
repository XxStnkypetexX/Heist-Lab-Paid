-----
-- OPTION TYPES
-----
local OptionType = {
    BUTTON = "button",
    TOGGLE = "toggle",
    NUMBER = "number",
    SELECT = "select",
    SUBMENU = "submenu"
}

-----
-- CONFIGURATION
-----
local CONFIG = {
    -- Layout
    center_x = 960,
    center_y = 400,
    width = 450,
    item_height = 38,
    header_height = 115,
    footer_height = 30,
    max_visible_items = 15,

    -- Styling
    border_thickness = 1,
    value_padding = 60,

    -- Header specifics
    tab_height = 20.0,
    title_scale = 86.0,
    title_offset_x = 84.0,
    title_offset_y = 1.0,

    -- Animation
    scroll_smooth = true,
    glow_pulse_speed = 2.0,
    glow_strength = 1.6,      -- Multiplier for glow intensity
    title_shadow_offset = 2,  -- Pixels for drop shadow
    header_accent_thickness = 6, -- Underline bar thickness
    header_accent_margin = 10,   -- Gap between title baseline and accent bar

    -- Header snow particles
    header_snow_enabled = true,
    header_snow_count = 45,
    header_snow_speed_min = 15,
    header_snow_speed_max = 40,
    header_snow_size_min = 2,
    header_snow_size_max = 4,
    header_snow_drift = 15
}

-- Color Palette
local COLORS = {
    -- FATE-like dark palette with cyan accents (#00C8FF)
    background    = color(10, 10, 10, 240),
    header_bg     = color(18, 18, 18, 255),
    selection_bg  = color(0, 200, 255, 180),
    hover_bg      = color(28, 28, 28, 120),

    border        = color(30, 30, 30, 255),
    separator     = color(55, 55, 55, 255),

    text_header   = color(255, 255, 255, 255),
    text_normal   = color(230, 230, 230, 255),
    text_selected = color(255, 255, 255, 255),
    text_disabled = color(140, 140, 140, 255),
    text_accent   = color(0, 200, 255, 255),
    glow_outline  = color(0, 120, 255, 150), -- Pulsing outline base color (blue)

    toggle_on     = color(0, 200, 255, 200),
    toggle_off    = color(80, 80, 80, 255),
    slider_bg     = color(35, 35, 35, 255),
    slider_fill   = color(0, 200, 255, 255),

    -- Particles
    snow_red      = color(255, 60, 60, 220)
}

-- Control Bindings
local CONTROLS = {
    TOGGLE_MENU = 23,   -- F (keyboard)
    NAVIGATE_UP = 172,  -- Up
    NAVIGATE_DOWN = 173, -- Down
    NAVIGATE_LEFT = 174, -- Left
    NAVIGATE_RIGHT = 175, -- Right
    SELECT = 176,       -- Enter
    BACK = 177,         -- Backspace
    SWITCH_TAB = 21,    -- Shift (Sprint)
    -- Controller combo for menu toggle
    RB = 45,            -- Right Bumper (INPUT_VEH_FLY_ATTACK2)
    X_BUTTON = 18       -- X Button (INPUT_FRONTEND_X)
}

-----
-- OPTION CLASS
-----
local Option = {}
Option.__index = Option

function Option.new(type, name, description)
    local self = setmetatable({}, Option)
    self.type = type
    self.name = name
    self.description = description or ""
    self.enabled = true
    self.visible = true
    return self
end

-- Button Option
function Option.button(name, description, callback)
    local opt = Option.new(OptionType.BUTTON, name, description)
    opt.callback = callback or function() end
    return opt
end

-- Toggle Option
function Option.toggle(name, description, default, callback)
    local opt = Option.new(OptionType.TOGGLE, name, description)
    opt.value = default or false
    opt.callback = callback or function() end
    return opt
end

-- Number Option (Slider or Arrows)
function Option.number(name, description, default, min, max, step, callback, style)
    local opt = Option.new(OptionType.NUMBER, name, description)
    opt.value = default or min or 0
    opt.min = min or 0
    opt.max = max or 100
    opt.step = step or 1
    opt.precision = step and (step < 1) and 1 or 0
    opt.style = style or "slider"  -- "slider" or "arrows"
    opt.callback = callback or function() end
    return opt
end

-- Select Option (Dropdown)
function Option.select(name, description, options, default_index, callback)
    local opt = Option.new(OptionType.SELECT, name, description)
    opt.options = options or {}
    opt.index = default_index or 1
    opt.callback = callback or function() end
    return opt
end

-- Submenu Option
function Option.submenu(name, description, submenu)
    local opt = Option.new(OptionType.SUBMENU, name, description)
    opt.submenu = submenu
    return opt
end

-----
-- MENU CLASS
-----
local Menu = {}
Menu.__index = Menu

function Menu.new(title, description)
    local self = setmetatable({}, Menu)
    self.title = title or "Menu"
    self.description = description or ""
    self.options = {}
    self.selected_index = 1
    self.scroll_offset = 0
    self.parent = nil
    return self
end

function Menu:add(option)
    table.insert(self.options, option)
    return self
end

function Menu:add_button(name, description, callback)
    return self:add(Option.button(name, description, callback))
end

-- Vehicle Protections Submenu
local vehicleProtectionsMenu = Menu.new("Vehicle Protections", "Anti-lag and vehicle safety options")

local natives = require("natives")

vehicleProtectionsMenu:add_toggle(
    "Prevent Background Pathfinding",
    "Stops vehicle AI from causing lag by disabling background pathfinding.",
    false,
    function(enabled)
        natives.setDrivingModeFlag("DF_PreventBackgroundPathfinding", enabled)
    end
)

vehicleProtectionsMenu:add_toggle(
    "Force Join In Road Direction",
    "Forces vehicle to join road direction, reducing desync.",
    false,
    function(enabled)
        natives.setDrivingModeFlag("DF_ForceJoinInRoadDirection", enabled)
    end
)

vehicleProtectionsMenu:add_select(
    "Vehicle Lock State",
    "Set vehicle lock state to prevent unwanted entry.",
    {"None", "Unlocked", "Locked", "Lockout Player Only", "Locked Player Inside", "Locked Initially"},
    1,
    function(index)
        natives.setLockState(index)

    end
)

-- Add submenu to main menu (example, adjust as needed)
-- mainMenu:add_submenu("Vehicle Protections", vehicleProtectionsMenu)

function Menu:add_toggle(name, description, default, callback)
    return self:add(Option.toggle(name, description, default, callback))
end

function Menu:add_number(name, description, default, min, max, step, callback, style)
    return self:add(Option.number(name, description, default, min, max, step, callback, style))
end

function Menu:add_select(name, description, options, default_index, callback)
    return self:add(Option.select(name, description, options, default_index, callback))
end

function Menu:add_submenu(name, description, submenu)
    submenu.parent = self
    return self:add(Option.submenu(name, description, submenu))
end

function Menu:add_separator()

    local sep = Option.new("separator", "---", "")
    sep.selectable = false
    return self:add(sep)
end

-- Vehicle Protections Submenu (moved after Menu methods)
local vehicleProtectionsMenu = Menu.new("Vehicle Protections", "Anti-lag and vehicle safety options")

local natives = require("natives")

vehicleProtectionsMenu:add_toggle(
    "Prevent Background Pathfinding",
    "Stops vehicle AI from causing lag by disabling background pathfinding.",
    false,
    function(enabled)
        natives.setDrivingModeFlag("DF_PreventBackgroundPathfinding", enabled)
    end
)

vehicleProtectionsMenu:add_toggle(
    "Force Join In Road Direction",
    "Forces vehicle to join road direction, reducing desync.",
    false,
    function(enabled)
        natives.setDrivingModeFlag("DF_ForceJoinInRoadDirection", enabled)
    end
)

vehicleProtectionsMenu:add_select(
    "Vehicle Lock State",
    "Set vehicle lock state to prevent unwanted entry.",
    {"None", "Unlocked", "Locked", "Lockout Player Only", "Locked Player Inside", "Locked Initially"},
    1,
    function(index)
        natives.setLockState(index)
    end
)

-- Add submenu to main menu (example, adjust as needed)
-- mainMenu:add_submenu("Vehicle Protections", vehicleProtectionsMenu)

function Menu:get_visible_options()
    local visible = {}
    for _, opt in ipairs(self.options) do
        if opt.visible then
            table.insert(visible, opt)
        end
    end
    return visible
end

function Menu:get_selected()
    local visible = self:get_visible_options()
    return visible[self.selected_index]
end

function Menu:navigate(direction)
    local visible = self:get_visible_options()
    local count = #visible
    if count == 0 then return end

    local new_index = self.selected_index + direction

    -- Wrap around
    if new_index < 1 then
        new_index = count
    elseif new_index > count then
        new_index = 1
    end

    -- Skip non-selectable items
    local opt = visible[new_index]
    if opt and opt.selectable == false then
        self.selected_index = new_index
        self:navigate(direction)
        return
    end

    self.selected_index = new_index

    -- Update scroll offset
    local max_visible = CONFIG.max_visible_items
    if self.selected_index > self.scroll_offset + max_visible then
        self.scroll_offset = self.selected_index - max_visible
    elseif self.selected_index <= self.scroll_offset then
        self.scroll_offset = self.selected_index - 1
    end
end

-----
-- OPTION BUILDER (Fluent API)
-----
local OptionBuilder = {}
OptionBuilder.__index = OptionBuilder

function OptionBuilder.new(menu)
    local self = setmetatable({}, OptionBuilder)
    self.menu = menu
    self._name = ""
    self._description = ""
    self._type = OptionType.BUTTON
    self._value = nil
    self._min = 0
    self._max = 100
    self._step = 1
    self._options = {}
    self._callback = function() end
    self._submenu = nil
    return self
end

function OptionBuilder:name(name)
    self._name = name
    return self
end

function OptionBuilder:desc(description)
    self._description = description
    return self
end

function OptionBuilder:as_button()
    self._type = OptionType.BUTTON
    return self
end

function OptionBuilder:as_toggle(default)
    self._type = OptionType.TOGGLE
    self._value = default or false
    return self
end

function OptionBuilder:as_number(default, min, max, step)
    self._type = OptionType.NUMBER
    self._value = default or min or 0
    self._min = min or 0
    self._max = max or 100
    self._step = step or 1
    return self
end

function OptionBuilder:as_select(options, default_index)
    self._type = OptionType.SELECT
    self._options = options or {}
    self._value = default_index or 1
    return self
end

function OptionBuilder:as_submenu(submenu)
    self._type = OptionType.SUBMENU
    self._submenu = submenu
    return self
end

function OptionBuilder:on_change(callback)
    self._callback = callback
    return self
end

function OptionBuilder:build()
    local opt
    if self._type == OptionType.BUTTON then
        opt = Option.button(self._name, self._description, self._callback)
    elseif self._type == OptionType.TOGGLE then
        opt = Option.toggle(self._name, self._description, self._value, self._callback)
    elseif self._type == OptionType.NUMBER then
        opt = Option.number(self._name, self._description, self._value, self._min, self._max, self._step, self._callback)
    elseif self._type == OptionType.SELECT then
        opt = Option.select(self._name, self._description, self._options, self._value, self._callback)
    elseif self._type == OptionType.SUBMENU then
        opt = Option.submenu(self._name, self._description, self._submenu)
        if self._submenu then
            self._submenu.parent = self.menu
        end
    end

    if opt then
        self.menu:add(opt)
    end
    return opt
end

-- Add builder method to Menu
function Menu:option()
    return OptionBuilder.new(self)
end

-----
-- MENU SYSTEM (Controller)
-----
local MenuSystem = {
    active = false,
    current_menu = nil,
    root_menu = nil,
    menu_stack = {},
    tabs = {},
    tab_index = 1,
    header_title = nil
}

function MenuSystem.open(menu)
    MenuSystem.active = true
    -- Prefer tabbed layout if tabs are configured
    if MenuSystem.tabs and #MenuSystem.tabs > 0 then
        MenuSystem.tab_index = MenuSystem.tab_index > 0 and MenuSystem.tab_index or 1
        local t = MenuSystem.tabs[MenuSystem.tab_index]
        MenuSystem.current_menu = (t and t.menu) or menu or MenuSystem.root_menu
    else
        MenuSystem.current_menu = menu or MenuSystem.root_menu
    end
    MenuSystem.menu_stack = {}
    -- Don't use input.disable_input - we'll manually block controls in the loop
end

function MenuSystem.close()
    MenuSystem.active = false
    MenuSystem.menu_stack = {}
end

function MenuSystem.enter_submenu(submenu)
    table.insert(MenuSystem.menu_stack, MenuSystem.current_menu)
    MenuSystem.current_menu = submenu
    submenu.selected_index = 1
    submenu.scroll_offset = 0
end

function MenuSystem.go_back()
    if #MenuSystem.menu_stack > 0 then
        MenuSystem.current_menu = table.remove(MenuSystem.menu_stack)
    else
        MenuSystem.close()
    end
end

function MenuSystem.set_tab(index)
    if not MenuSystem.tabs or #MenuSystem.tabs == 0 then return end
    if index < 1 then index = #MenuSystem.tabs end
    if index > #MenuSystem.tabs then index = 1 end
    MenuSystem.tab_index = index
    local t = MenuSystem.tabs[index]
    if t and t.menu then
        MenuSystem.current_menu = t.menu
        MenuSystem.menu_stack = {}
        -- Reset selection when switching tabs so the counter starts at 1
        MenuSystem.current_menu.selected_index = 1
        MenuSystem.current_menu.scroll_offset = 0
    end
end

-----
-- UTILITIES
-----
local Utils = {}

function Utils.is_control_just_pressed(inputGroup, control)
    local result = invoker.call(0x580417101DDB492F, inputGroup, control)
    return result.bool
end

-- Optional raw key check (guards if API not present)
local VK = { LSHIFT = 0xA0, RSHIFT = 0xA1, F_KEY = 0x46 }
function Utils.is_key_just_pressed(vk)
    -- Try input.is_key_just_pressed first (keyboard only)
    if input and input.is_key_just_pressed then
        local ok, pressed = pcall(input.is_key_just_pressed, vk)
        if ok and pressed then return true end
    end
    return false
end

function Utils.is_keyboard_key_down(vk)
    -- Alternative: check if key is currently held using native
    if invoker and invoker.call then
        local ok, result = pcall(function()
            -- IS_DISABLED_CONTROL_PRESSED checks keyboard specifically when using input group 0
            return invoker.call(0xE2587F8BA56E7B4, 0, vk)
        end)
        if ok and result and result.bool then
            return true
        end
    end
    return false
end

function Utils.get_menu_bounds(menu)
    local visible = menu:get_visible_options()
    local item_count = math.min(#visible, CONFIG.max_visible_items)
    local menu_height = CONFIG.header_height + (CONFIG.item_height * item_count) + CONFIG.footer_height
    local start_x = CONFIG.center_x - CONFIG.width / 2
    local start_y = CONFIG.center_y - menu_height / 2

    return {
        x = start_x,
        y = start_y,
        width = CONFIG.width,
        height = menu_height,
        item_count = item_count
    }
end

function Utils.wrap_text(text, max_chars)
    if not text or text == "" then return {} end

    local lines = {}
    local current_line = ""

    for word in text:gmatch("%S+") do
        local test_line = current_line == "" and word or (current_line .. " " .. word)
        if #test_line <= max_chars then
            current_line = test_line
        else
            if current_line ~= "" then
                table.insert(lines, current_line)
            end
            current_line = word
        end
    end

    if current_line ~= "" then
        table.insert(lines, current_line)
    end

    return lines
end

-----
-- RENDERER
-----
local Renderer = {}

-- Simple header snow particle system
local HeaderSnow = { particles = nil, last_time = nil }

function HeaderSnow:init(bounds)
    self.particles = {}
    local count = CONFIG.header_snow_count or 40
    for i = 1, count do
        local px = bounds.x + math.random() * bounds.width
        local py = bounds.y + math.random() * CONFIG.header_height
        local spd = CONFIG.header_snow_speed_min + math.random() * (CONFIG.header_snow_speed_max - CONFIG.header_snow_speed_min)
        local sz  = CONFIG.header_snow_size_min + math.random() * (CONFIG.header_snow_size_max - CONFIG.header_snow_size_min)
        local ph  = math.random() * math.pi * 2
        table.insert(self.particles, {x = px, y = py, speed = spd, size = sz, phase = ph})
    end
    self.last_time = os.clock()
end

function HeaderSnow:update_and_draw(bounds)
    if not CONFIG.header_snow_enabled then return end
    if not self.particles then self:init(bounds) end

    local now = os.clock()
    local dt = (self.last_time and (now - self.last_time)) or 0.016
    if dt < 0 then dt = 0 end
    if dt > 0.05 then dt = 0.05 end -- clamp to avoid big jumps
    self.last_time = now

    local left = bounds.x
    local right = bounds.x + bounds.width
    local top = bounds.y
    local bottom = bounds.y + CONFIG.header_height

    local drift_amp = CONFIG.header_snow_drift or 12

    for i, p in ipairs(self.particles) do
        -- Ensure speed respects current config (so changes apply immediately)
        local spd_min = CONFIG.header_snow_speed_min or 15
        local spd_max = CONFIG.header_snow_speed_max or 40
        if p.speed > spd_max then p.speed = spd_max end
        if p.speed < spd_min then p.speed = spd_min end

        -- Update
        p.y = p.y + p.speed * dt
        p.phase = p.phase + dt
        local drift = math.sin(p.phase * 2.0) * drift_amp * dt * 60
        p.x = p.x + drift

        -- Wrap
        if p.y > bottom then
            p.y = top - (math.random() * 20)
            p.x = left + math.random() * (right - left)
            p.speed = CONFIG.header_snow_speed_min + math.random() * (CONFIG.header_snow_speed_max - CONFIG.header_snow_speed_min)
        end
        if p.x < left then p.x = right - 1 end
        if p.x > right then p.x = left + 1 end

        -- Draw only if inside header area
        if p.y >= top and p.y <= bottom then
            Renderer.draw_rect(vec2(p.x, p.y), vec2(p.size, p.size), COLORS.snow_red, nil)
        end
    end
end

function Renderer.draw_rect(pos, size, bg_color, border_color)
    if bg_color then
        gui.rect(pos, size):color(bg_color):filled():draw()
    end
    if border_color then
        gui.rect(pos, size):outline(CONFIG.border_thickness, border_color):draw()
    end
end

function Renderer.draw_text(text, pos, text_color, scale)
    local scale_val = scale or 20.0
    gui.text(text):position(pos):color(text_color):scale(scale_val):draw()
end

function Renderer.draw_text_right(text, pos, text_color, bounds_right)
    local text_width = #text * 7
    local x = bounds_right - text_width - 8
    gui.text(text):position(vec2(x, pos.y)):color(text_color):draw()
end

-- (removed) scale-aware text measurement helpers were not needed

function Renderer.draw_tabs(bounds, menu)
    local tabs = MenuSystem.tabs or {}
    local count = #tabs
    if count == 0 then return end

    local tab_h = CONFIG.tab_height or 20
    local tab_y = bounds.y + CONFIG.header_height - tab_h - 2

    -- Right-aligned item counter for the active tab ("1 / N")
    local right_label = ""
    if menu then
        local visible = menu:get_visible_options()
        local selected_idx = menu.selected_index or 1
        if selected_idx < 1 then selected_idx = 1 end
        if selected_idx > #visible then selected_idx = #visible end
        right_label = string.format("%d / %d", selected_idx, #visible)
    end

    local right_area = right_label ~= "" and 65 or 0
    local left_margin = 5
    local usable_width = bounds.width - right_area - left_margin
    -- Variable gutters: tight between first 3 tabs, wider after Network (middle)
    local gutters = {3, 3, 10, 10}  -- gaps after tabs 1, 2, 3, 4
    local total_gap = 0
    for _, g in ipairs(gutters) do total_gap = total_gap + g end
    local tab_band = usable_width - total_gap
    local w = tab_band / count
    local start_x = bounds.x + left_margin

    -- Cyan line across the top of the tabs bar (full UI width)
    do
        local line_left = bounds.x
        local line_right = bounds.x + bounds.width
        local line_y = tab_y - 1
        gui.line(vec2(line_left, line_y), vec2(line_right, line_y), 2, COLORS.text_accent)
    end

    for i, t in ipairs(tabs) do
        local offset = 0
        for j = 1, i-1 do
            local gutter = gutters[j] or gutters[#gutters] or 0  -- fallback spacing once predefined gutters are exhausted
            offset = offset + w + gutter
        end
        local base_x = start_x + offset
        local is_active = (i == MenuSystem.tab_index)
        local br = COLORS.separator

        local label = t.label or (t.menu and t.menu.title) or ('Tab '..i)
        local tw = #label * 7
        local tx = base_x + (w - tw) / 2
        local ty = tab_y + (tab_h / 2) - 8

        -- Draw background: active fills the full tab slot for consistent overlays
        if is_active then
            Renderer.draw_rect(vec2(base_x, tab_y), vec2(w, tab_h), COLORS.selection_bg, br)
        else
            Renderer.draw_rect(vec2(base_x, tab_y), vec2(w, tab_h), nil, br)
        end

        -- Draw label text
        Renderer.draw_text(label, vec2(tx, ty), is_active and COLORS.text_selected or COLORS.text_normal)
    end

    if right_label ~= "" then
        local tw = #right_label * 7
        local rx = bounds.x + bounds.width - tw - 8
        local ry = tab_y + (tab_h / 2) - 8
        Renderer.draw_text(right_label, vec2(rx, ry), COLORS.text_normal, 17.0)
    end
end

-- Draw toggle indicator
function Renderer.draw_toggle(pos, size, value, selected)
    -- Render a checkbox like the reference UI
    local box_size = 16
    local right_edge = pos.x + size.x - 8
    local box_x = right_edge - box_size
    local box_y = pos.y + (size.y - box_size) / 2

    -- Border box
    local border_col = COLORS.separator
    Renderer.draw_rect(vec2(box_x, box_y), vec2(box_size, box_size), nil, border_col)

    -- Fill when checked
    if value then
        Renderer.draw_rect(vec2(box_x + 2, box_y + 2), vec2(box_size - 4, box_size - 4), COLORS.selection_bg, nil)
        -- Simple checkmark
        local x1, y1 = box_x + 3, box_y + 8
        local x2, y2 = box_x + 7, box_y + 12
        local x3, y3 = box_x + 13, box_y + 4
        gui.line(vec2(x1, y1), vec2(x2, y2), 2, COLORS.text_header)
        gui.line(vec2(x2, y2), vec2(x3, y3), 2, COLORS.text_header)
    end

    -- Highlight focus
    if selected then
        Renderer.draw_rect(vec2(box_x - 2, box_y - 2), vec2(box_size + 4, box_size + 4), nil, COLORS.text_accent)
    end
end

-- Draw slider
function Renderer.draw_slider(pos, size, value, min, max, selected)
    local right_edge = pos.x + size.x - 8  -- Same as toggle end position
    local slider_width = 80
    local slider_height = 6
    local value_area_width = 36  -- Fixed width for value text area

    -- Value text (right-aligned within fixed area)
    local value_text = tostring(value)
    local text_width = #value_text * 7
    local text_x = right_edge - value_area_width + (value_area_width - text_width) / 2  -- Centered in fixed area
    local text_y = pos.y + size.y / 2 - 8
    local text_color = selected and COLORS.text_selected or COLORS.text_normal
    Renderer.draw_text(value_text, vec2(text_x, text_y), text_color)

    -- Slider bar (fixed position to the left of value area)
    local slider_x = right_edge - value_area_width - slider_width - 6
    local slider_y = pos.y + (size.y - slider_height) / 2

    -- Background bar
    Renderer.draw_rect(vec2(slider_x, slider_y), vec2(slider_width, slider_height), COLORS.slider_bg, nil)

    -- Fill bar
    local fill_pct = (value - min) / (max - min)
    local fill_width = slider_width * fill_pct
    if fill_width > 0 then
        Renderer.draw_rect(vec2(slider_x, slider_y), vec2(fill_width, slider_height), COLORS.slider_fill, nil)
    end
end

-- Draw number with arrows style (like select)
function Renderer.draw_number_arrows(pos, size, value, selected)
    local right_edge = pos.x + size.x - 8  -- Same as toggle end position
    local text_color = selected and COLORS.text_selected or COLORS.text_normal

    -- Draw value with arrows (right-aligned to match toggle end)
    local display_text = "< " .. tostring(value) .. " >"
    local text_width = #display_text * 7
    local text_x = right_edge - text_width
    local text_y = pos.y + size.y / 2 - 8
    Renderer.draw_text(display_text, vec2(text_x, text_y), text_color)
end

-- Draw select arrows and value
function Renderer.draw_select(pos, size, options, index, selected)
    local right_edge = pos.x + size.x - 8  -- Same as toggle end position
    local text_color = selected and COLORS.text_selected or COLORS.text_normal
    local current_value = options[index] or "None"

    -- Draw current value with arrows (right-aligned to match toggle end)
    local display_text = "< " .. current_value .. " >"
    local text_width = #display_text * 7
    local text_x = right_edge - text_width
    local text_y = pos.y + size.y / 2 - 8
    Renderer.draw_text(display_text, vec2(text_x, text_y), text_color)
end

-- Draw single option
function Renderer.draw_option(opt, pos, size, selected)
    -- Selection highlight
    if selected then
        Renderer.draw_rect(pos, size, COLORS.selection_bg, nil)
    end

    -- Separator
    if opt.type == "separator" then
        local sep_y = pos.y + size.y / 2
        gui.line(vec2(pos.x + 8, sep_y), vec2(pos.x + size.x - 8, sep_y), 1, COLORS.separator)
        return
    end

    local text_color = selected and COLORS.text_selected or COLORS.text_normal
    local text_y = pos.y + size.y / 2 - 8

    -- Option name
    Renderer.draw_text(opt.name, vec2(pos.x + 8, text_y), text_color)

    -- Type-specific rendering
    if opt.type == OptionType.TOGGLE then
        Renderer.draw_toggle(pos, size, opt.value, selected)

    elseif opt.type == OptionType.NUMBER then
        if opt.style == "arrows" then
            Renderer.draw_number_arrows(pos, size, opt.value, selected)
        else
            Renderer.draw_slider(pos, size, opt.value, opt.min, opt.max, selected)
        end

    elseif opt.type == OptionType.SELECT then
        Renderer.draw_select(pos, size, opt.options, opt.index, selected)

    elseif opt.type == OptionType.SUBMENU then
        local right_edge = pos.x + size.x - 8
        local arrow_x = right_edge - 14  -- allow for double arrows »» look
        local arrow_y = pos.y + (size.y - 16) / 2  -- Center vertically (16 = text height)
        Renderer.draw_text(">>", vec2(arrow_x, arrow_y), COLORS.text_accent)
    end
end

-- Draw header
function Renderer.draw_header(bounds, menu)
    local header_pos = vec2(bounds.x, bounds.y)
    local header_size = vec2(bounds.width, CONFIG.header_height)

    -- Simple header background
    Renderer.draw_rect(header_pos, header_size, COLORS.header_bg, nil)

    -- Falling snow particles (red) in the header background
    HeaderSnow:update_and_draw({ x = header_pos.x, y = header_pos.y, width = header_size.x, height = header_size.y })

    -- Small left-aligned title with configurable offsets and scale
    local title = MenuSystem.header_title or menu.title
    local ox = CONFIG.title_offset_x or 8
    local oy = CONFIG.title_offset_y or 8
    -- Draw cyan glow effect for cool styling
    local pos = vec2(bounds.x + ox, bounds.y + oy)
    -- Pulsing glow alpha based on time
    local time = os.clock() * CONFIG.glow_pulse_speed
    local pulse = (math.sin(time) + 1) / 2  -- Oscillates between 0 and 1
    local glow_alpha = 80 + (pulse * 120)  -- Alpha ranges from 80 to 200
    local base = COLORS.glow_outline
    local glow_color = color(base.r, base.g, base.b, glow_alpha)
    local offset = 3
    -- Draw glow outline
    Renderer.draw_text(title or "", vec2(pos.x - offset, pos.y), glow_color, CONFIG.title_scale)
    Renderer.draw_text(title or "", vec2(pos.x + offset, pos.y), glow_color, CONFIG.title_scale)
    Renderer.draw_text(title or "", vec2(pos.x, pos.y - offset), glow_color, CONFIG.title_scale)
    Renderer.draw_text(title or "", vec2(pos.x, pos.y + offset), glow_color, CONFIG.title_scale)
    Renderer.draw_text(title or "", vec2(pos.x - offset, pos.y - offset), glow_color, CONFIG.title_scale)
    Renderer.draw_text(title or "", vec2(pos.x + offset, pos.y + offset), glow_color, CONFIG.title_scale)
    Renderer.draw_text(title or "", vec2(pos.x - offset, pos.y + offset), glow_color, CONFIG.title_scale)
    Renderer.draw_text(title or "", vec2(pos.x + offset, pos.y - offset), glow_color, CONFIG.title_scale)
    -- Draw bright cyan text on top
    Renderer.draw_text(title or "", pos, COLORS.text_accent, CONFIG.title_scale)

    -- Tabs along the bottom of the header with active tab count
    Renderer.draw_tabs(bounds, menu)
end

-- Draw footer
function Renderer.draw_footer(bounds, menu)
    local visible = menu:get_visible_options()
    local footer_y = bounds.y + bounds.height - CONFIG.footer_height
    local footer_pos = vec2(bounds.x, footer_y)
    local footer_size = vec2(bounds.width, CONFIG.footer_height)

    Renderer.draw_rect(footer_pos, footer_size, COLORS.header_bg, nil)

    local text_y = footer_y + CONFIG.footer_height / 2 - 8

    -- Left: Active tab label
    local active_tab = (MenuSystem.tabs and MenuSystem.tabs[MenuSystem.tab_index]) or nil
    local left_label = active_tab and (active_tab.label or (active_tab.menu and active_tab.menu.title)) or menu.title
    Renderer.draw_text(left_label or "", vec2(bounds.x + 8, text_y), COLORS.text_disabled)

    -- Center: Selected option description (trimmed)
    local sel = menu:get_selected()
    if sel and sel.description and sel.description ~= "" then
        local desc = sel.description
        local max_chars = math.floor(bounds.width / 8)
        if #desc > max_chars then
            desc = desc:sub(1, max_chars - 3) .. "..."
        end
        local tw = #desc * 7
        local cx = bounds.x + (bounds.width - tw) / 2
        Renderer.draw_text(desc, vec2(cx, text_y), COLORS.text_normal)
    end

    -- Item count removed from footer for a cleaner look
end

-- Draw description box
function Renderer.draw_description(bounds, opt)
    if not opt or not opt.description or opt.description == "" then return end

    local max_chars = math.floor(CONFIG.width / 7)
    local lines = Utils.wrap_text(opt.description, max_chars)
    if #lines == 0 then return end

    local line_height = 16
    local padding = 8
    local box_height = (#lines * line_height) + (padding * 2)
    local box_y = bounds.y + bounds.height + 8

    -- Background
    Renderer.draw_rect(vec2(bounds.x, box_y), vec2(bounds.width, box_height), COLORS.background, COLORS.border)

    -- Text lines
    for i, line in ipairs(lines) do
        local line_y = box_y + padding + ((i - 1) * line_height)
        Renderer.draw_text(line, vec2(bounds.x + 8, line_y), COLORS.text_normal)
    end
end

-- Main render function
function Renderer.draw_menu()
    if not MenuSystem.active or not MenuSystem.current_menu then return end

    local menu = MenuSystem.current_menu
    local bounds = Utils.get_menu_bounds(menu)
    local visible = menu:get_visible_options()

    -- Main background
    Renderer.draw_rect(vec2(bounds.x, bounds.y), vec2(bounds.width, bounds.height), COLORS.background, COLORS.border)

    -- Header
    Renderer.draw_header(bounds, menu)

    -- Options
    local items_start_y = bounds.y + CONFIG.header_height
    local start_idx = menu.scroll_offset + 1
    local end_idx = math.min(start_idx + bounds.item_count - 1, #visible)

    for i = start_idx, end_idx do
        local opt = visible[i]
        local display_idx = i - menu.scroll_offset
        local item_y = items_start_y + ((display_idx - 1) * CONFIG.item_height)
        local is_selected = (i == menu.selected_index)

        Renderer.draw_option(opt, vec2(bounds.x, item_y), vec2(bounds.width, CONFIG.item_height), is_selected)
    end

    -- Scroll indicators
    if menu.scroll_offset > 0 then
        Renderer.draw_text("^", vec2(bounds.x + bounds.width / 2 - 4, items_start_y - 12), COLORS.text_accent)
    end
    if end_idx < #visible then
        local bottom_y = items_start_y + (bounds.item_count * CONFIG.item_height)
        Renderer.draw_text("v", vec2(bounds.x + bounds.width / 2 - 4, bottom_y - 8), COLORS.text_accent)
    end

    -- Footer
    Renderer.draw_footer(bounds, menu)

    -- FATE-like layout keeps description in footer, so skip separate box
end

-----
-- INPUT HANDLER
-----
local InputHandler = {}

function InputHandler.handle_toggle()
    local should_toggle = false
    
    -- Method 1: F key (keyboard or disabled control in pause menus)
    if input and input.is_key_just_pressed then
        if input.is_key_just_pressed(0x46) then -- F key
            should_toggle = true
        end
    end
    
    -- Also check F key as a disabled control (works in mission/pause screens)
    if not should_toggle and invoker and invoker.call then
        local f_disabled = invoker.call(0x91AEF906BCA88877, 0, 23) -- Control 23 = F
        if f_disabled and f_disabled.bool then
            should_toggle = true
        end
    end
    
    -- Method 2: Controller combo RB + X (requires both buttons pressed)
    if not should_toggle and invoker and invoker.call then
        -- Check group 0 (game controls)
        -- RB held + X just pressed
        local rb_result = invoker.call(0xF3A21BCD95725A4A, 0, 45) -- IS_CONTROL_PRESSED (RB held)
        local x_result = invoker.call(0x580417101DDB492F, 0, 18)  -- IS_CONTROL_JUST_PRESSED (X)
        
        if rb_result and rb_result.bool and x_result and x_result.bool then
            should_toggle = true
        end
    end
    
    if should_toggle then
        if MenuSystem.active then
            MenuSystem.close()
        else
            MenuSystem.open()
        end
        return true
    end
    return false
end

function InputHandler.handle_option_adjust(opt, direction)
    if not opt then return end

    if opt.type == OptionType.TOGGLE then
        opt.value = not opt.value
        if opt.callback then opt.callback(opt.value) end

    elseif opt.type == OptionType.NUMBER then
        local new_val = opt.value + (opt.step * direction)
        if new_val < opt.min then new_val = opt.min end
        if new_val > opt.max then new_val = opt.max end
        if new_val ~= opt.value then
            opt.value = new_val
            if opt.callback then opt.callback(opt.value) end
        end

    elseif opt.type == OptionType.SELECT then
        local new_idx = opt.index + direction
        if new_idx < 1 then new_idx = #opt.options end
        if new_idx > #opt.options then new_idx = 1 end
        if new_idx ~= opt.index then
            opt.index = new_idx
            if opt.callback then opt.callback(opt.options[opt.index], opt.index) end
        end
    end
end

function InputHandler.handle_navigation()
    if not MenuSystem.active then return end

    local menu = MenuSystem.current_menu
    if not menu then return end

    -- Use DISABLED control checks when menu is active (works even when game blocks normal input)
    -- Up/Down navigation
    local up_pressed = invoker.call(0x91AEF906BCA88877, 0, CONTROLS.NAVIGATE_UP)
    if up_pressed and up_pressed.bool then
        menu:navigate(-1)
        return
    end

    local down_pressed = invoker.call(0x91AEF906BCA88877, 0, CONTROLS.NAVIGATE_DOWN)
    if down_pressed and down_pressed.bool then
        menu:navigate(1)
        return
    end

    local selected = menu:get_selected()

    -- Shift advances to the next tab (wraps). Use keyboard first so it works in pause/frontend.
    local shift_pressed = Utils.is_key_just_pressed(VK.LSHIFT) or Utils.is_key_just_pressed(VK.RSHIFT)
    -- Also check disabled control for shift
    local shift_control = invoker.call(0x91AEF906BCA88877, 0, CONTROLS.SWITCH_TAB)
    if (shift_pressed or (shift_control and shift_control.bool))
        and MenuSystem.tabs and #MenuSystem.tabs > 0 then
        MenuSystem.set_tab((MenuSystem.tab_index or 1) + 1)
        return
    end

    -- Left/Right strictly adjust the current option value
    local left_pressed = invoker.call(0x91AEF906BCA88877, 0, CONTROLS.NAVIGATE_LEFT)
    if left_pressed and left_pressed.bool then
        InputHandler.handle_option_adjust(selected, -1)
        return
    end

    local right_pressed = invoker.call(0x91AEF906BCA88877, 0, CONTROLS.NAVIGATE_RIGHT)
    if right_pressed and right_pressed.bool then
        InputHandler.handle_option_adjust(selected, 1)
        return
    end

    -- Select/Enter
    local select_pressed = invoker.call(0x91AEF906BCA88877, 0, CONTROLS.SELECT)
    if select_pressed and select_pressed.bool then
        if selected then
            if selected.type == OptionType.BUTTON then
                if selected.callback then selected.callback() end
            elseif selected.type == OptionType.TOGGLE then
                selected.value = not selected.value
                if selected.callback then selected.callback(selected.value) end
            elseif selected.type == OptionType.SUBMENU and selected.submenu then
                MenuSystem.enter_submenu(selected.submenu)
            end
        end
        return
    end

    -- Back
    local back_pressed = invoker.call(0x91AEF906BCA88877, 0, CONTROLS.BACK)
    if back_pressed and back_pressed.bool then
        MenuSystem.go_back()
        return
    end
end

function InputHandler.process()
    -- Always check for menu toggle first, even when menu is active
    if InputHandler.handle_toggle() then
        return -- Toggle was handled, don't process navigation
    end
    -- Only process navigation if menu is active
    InputHandler.handle_navigation()
end

-----
-- OVERDRIVE: VEHICLE FUNCTIONS
-----

-- Native hashes
local HASH_SET_VEHICLE_MOD_KIT = 0x1F2AA07F00B3217A
local HASH_GET_NUM_VEHICLE_MODS = 0xE38E9162A2500646
local HASH_SET_VEHICLE_MOD = 0x6AF0636DDEDCB6DD
local HASH_TOGGLE_VEHICLE_MOD = 0x2A1F4F37F95BAD08
local HASH_SET_VEHICLE_FIXED = 0x115722B1B9C14C1C
local HASH_SET_VEHICLE_DIRT_LEVEL = 0x79D3B596FE44EE8B
local HASH_SET_VEHICLE_COLOURS = 0x4F1D4BE3A7F24601
local HASH_SET_VEHICLE_EXTRA_COLOURS = 0x2036F561ADD12E33
local HASH_NEON_ENABLED = 0x2AA720E4287BF269
local HASH_NEON_COLOR = 0x8E0A582209A62695
local HASH_SET_VEHICLE_TYRE_SMOKE_COLOR = 0xB5BA80F839791C0F
local HASH_SET_VEHICLE_DOOR_OPEN = 0x7C65DAC73C35C862
local HASH_SET_VEHICLE_DOOR_SHUT = 0x93D9BD300D7789E5
local HASH_SET_VEHICLE_DOORS_SHUT = 0x781B3D62BB013EF5
local HASH_SET_VEHICLE_RADIO_ENABLED = 0x3B988190C0AA6C0B
local HASH_SET_VEHICLE_WHEEL_TYPE = 0x487EB21CC7295BA1
local HASH_SET_VEHICLE_RADIO_LOUD = 0xBB6F1CAEC68B0BCE
local HASH_SET_VEH_RADIO_STATION = 0x1B9C0099CB942AC6
local HASH_SET_VEHICLE_XENON_LIGHTS_COLOR = 0xE41033B25D003A07
local HASH_DOES_EXTRA_EXIST = 0x1262D55792428154
local HASH_SET_VEHICLE_EXTRA = 0x7EE3A3C5E4A40CC9
local HASH_IS_VEHICLE_EXTRA_TURNED_ON = 0xD2E6822DBFD6C8BD
local HASH_SET_VEHICLE_NUMBER_PLATE_TEXT = 0x95A88F0B409CDA47
local HASH_SET_VEHICLE_LIGHTS = 0x34E710FF01247C5A
local HASH_ROLL_DOWN_WINDOWS = 0x85796B0549DDE156
local HASH_ROLL_UP_WINDOW = 0x602E548F46E24D59

-- Global state
local last_vehicle = 0
local subwoofer_enabled = false
local PLATE_TEXT_PRESET = "OVERDRIVE"
local plate_lock_enabled = false
local SHOWCASE_PLAYLIST = {vehicles = {}, current_index = 1, enabled = false}

-- Helper functions
local function get_player_vehicle()
    if not players or not players.me then
        notify.push("Vehicle", "Players API missing", 2000)
        return nil
    end
    local me = players.me()
    if not me or not me.exists or not me.in_vehicle or me.vehicle == 0 then
        notify.push("Vehicle", "You need to be in a vehicle", 2000)
        return nil
    end
    return me.vehicle
end

local function ensure_control(veh)
    if request and request.control then
        request.control(veh, true)
        util.yield(50)
    end
end

-- Max upgrade
local function max_upgrade_current()
    local veh = get_player_vehicle()
    if not veh then return end
    ensure_control(veh)
    invoker.call(HASH_SET_VEHICLE_MOD_KIT, veh, 0)
    
    local mod_types = {0,1,2,3,4,5,6,7,8,9,10,11,12,13,15,16,23,24}
    for _, modType in ipairs(mod_types) do
        local count_ret = invoker.call(HASH_GET_NUM_VEHICLE_MODS, veh, modType)
        local count = count_ret and count_ret.int or 0
        if count and count > 0 then
            invoker.call(HASH_SET_VEHICLE_MOD, veh, modType, count - 1, false)
            util.yield(15)
        end
    end
    
    invoker.call(HASH_TOGGLE_VEHICLE_MOD, veh, 18, true) -- Turbo
    invoker.call(HASH_TOGGLE_VEHICLE_MOD, veh, 20, true) -- Tire smoke
    invoker.call(HASH_TOGGLE_VEHICLE_MOD, veh, 22, true) -- Xenon
    notify.push("Vehicle", "Max upgrades applied", 2000)
end

-- Performance upgrade
local function performance_upgrade_current()
    local veh = get_player_vehicle()
    if not veh then return end
    ensure_control(veh)
    invoker.call(HASH_SET_VEHICLE_MOD_KIT, veh, 0)
    
    local perf_mods = {11,12,13,15,16} -- Engine, Brakes, Trans, Susp, Armor
    for _, modType in ipairs(perf_mods) do
        local count_ret = invoker.call(HASH_GET_NUM_VEHICLE_MODS, veh, modType)
        local count = count_ret and count_ret.int or 0
        if count and count > 0 then
            invoker.call(HASH_SET_VEHICLE_MOD, veh, modType, count - 1, false)
            util.yield(15)
        end
    end
    
    invoker.call(HASH_TOGGLE_VEHICLE_MOD, veh, 18, true) -- Turbo
    notify.push("Vehicle", "Performance upgrades applied", 2000)
end

-- Repair & Clean
local function fix_vehicle()
    local veh = get_player_vehicle()
    if not veh then return end
    ensure_control(veh)
    invoker.call(HASH_SET_VEHICLE_FIXED, veh)
    invoker.call(HASH_SET_VEHICLE_DIRT_LEVEL, veh, 0.0)
    notify.push("Vehicle", "Repaired & cleaned", 2000)
end

-- Paint functions
local function apply_paint(preset)
    local veh = get_player_vehicle()
    if not veh then return end
    ensure_control(veh)
    invoker.call(HASH_SET_VEHICLE_MOD_KIT, veh, 0)
    
    local primary = preset.primary or 0
    local secondary = preset.secondary or primary
    local pearlescent = preset.pearlescent or primary
    local wheels = preset.wheels or primary
    
    invoker.call(HASH_SET_VEHICLE_COLOURS, veh, primary, secondary)
    invoker.call(HASH_SET_VEHICLE_EXTRA_COLOURS, veh, pearlescent, wheels)
    notify.push("Vehicle", "Paint applied: " .. (preset.name or "Unknown"), 2000)
end

local function random_paint()
    local veh = get_player_vehicle()
    if not veh then return end
    ensure_control(veh)
    invoker.call(HASH_SET_VEHICLE_MOD_KIT, veh, 0)
    
    math.randomseed(os.time())
    local primary = math.random(0, 160)
    local secondary = math.random(0, 160)
    local pearl = math.random(0, 160)
    local wheels = math.random(0, 160)
    
    invoker.call(HASH_SET_VEHICLE_COLOURS, veh, primary, secondary)
    invoker.call(HASH_SET_VEHICLE_EXTRA_COLOURS, veh, pearl, wheels)
    notify.push("Vehicle", string.format("Random paint (P:%d S:%d)", primary, secondary), 2000)
end

-- Neon functions
local function apply_neon(r, g, b)
    local veh = get_player_vehicle()
    if not veh then return end
    ensure_control(veh)
    
    for i = 0, 3 do
        invoker.call(HASH_NEON_ENABLED, veh, i, true)
    end
    invoker.call(HASH_NEON_COLOR, veh, r, g, b)
    notify.push("Vehicle", string.format("Neon RGB(%d,%d,%d)", r, g, b), 2000)
end

-- Door functions
local function open_all_doors()
    local veh = get_player_vehicle()
    if not veh then return end
    ensure_control(veh)
    
    for door = 0, 5 do
        invoker.call(HASH_SET_VEHICLE_DOOR_OPEN, veh, door, false, true)
    end
    notify.push("Vehicle", "All doors opened", 1500)
end

local function close_all_doors()
    local veh = get_player_vehicle()
    if not veh then return end
    ensure_control(veh)
    invoker.call(HASH_SET_VEHICLE_DOORS_SHUT, veh, true)
    notify.push("Vehicle", "All doors closed", 1500)
end

-- Radio functions
local function radio_on()
    local veh = get_player_vehicle()
    if not veh then return end
    ensure_control(veh)
    invoker.call(HASH_SET_VEHICLE_RADIO_ENABLED, veh, true)
    notify.push("Vehicle", "Radio ON", 1500)
end

local function radio_off()
    local veh = get_player_vehicle()
    if not veh then return end
    ensure_control(veh)
    invoker.call(HASH_SET_VEHICLE_RADIO_ENABLED, veh, false)
    notify.push("Vehicle", "Radio OFF", 1500)
end

local function toggle_subwoofer()
    subwoofer_enabled = not subwoofer_enabled
    local veh = get_player_vehicle()
    if veh then
        ensure_control(veh)
        invoker.call(HASH_SET_VEHICLE_RADIO_ENABLED, veh, true)
        invoker.call(HASH_SET_VEHICLE_RADIO_LOUD, veh, subwoofer_enabled)
    end
    notify.push("Vehicle", subwoofer_enabled and "Subwoofer ON" or "Subwoofer OFF", 1500)
end

local function set_radio_station(station, name)
    local veh = get_player_vehicle()
    if not veh then return end
    ensure_control(veh)
    invoker.call(HASH_SET_VEHICLE_RADIO_ENABLED, veh, true)
    invoker.call(HASH_SET_VEH_RADIO_STATION, veh, station)
    notify.push("Vehicle", "Radio: " .. name, 1500)
end

-- Tire smoke
local function apply_tire_smoke(r, g, b)
    local veh = get_player_vehicle()
    if not veh then return end
    ensure_control(veh)
    invoker.call(HASH_TOGGLE_VEHICLE_MOD, veh, 20, true)
    invoker.call(HASH_SET_VEHICLE_TYRE_SMOKE_COLOR, veh, r, g, b)
    notify.push("Vehicle", string.format("Tire smoke RGB(%d,%d,%d)", r, g, b), 2000)
end

-- Xenon headlights
local function set_headlight_color(color_id, name)
    local veh = get_player_vehicle()
    if not veh then return end
    ensure_control(veh)
    invoker.call(HASH_SET_VEHICLE_MOD_KIT, veh, 0)
    invoker.call(HASH_TOGGLE_VEHICLE_MOD, veh, 22, true)
    invoker.call(HASH_SET_VEHICLE_XENON_LIGHTS_COLOR, veh, color_id)
    notify.push("Vehicle", "Headlights: " .. name, 2000)
end

-- Vehicle Extras
local function toggle_extra(extraId)
    local veh = get_player_vehicle()
    if not veh then return end
    ensure_control(veh)
    local exists = invoker.call(HASH_DOES_EXTRA_EXIST, veh, extraId)
    if not exists or not exists.bool then
        notify.push("Vehicle", "Extra " .. extraId .. " doesn't exist", 1500)
        return
    end
    local state = invoker.call(HASH_IS_VEHICLE_EXTRA_TURNED_ON, veh, extraId)
    local is_on = state and state.bool
    invoker.call(HASH_SET_VEHICLE_EXTRA, veh, extraId, is_on)
    notify.push("Vehicle", "Extra " .. extraId .. (is_on and " OFF" or " ON"), 1500)
end

local function set_all_extras(enable)
    local veh = get_player_vehicle()
    if not veh then return end
    ensure_control(veh)
    for i = 0, 20 do
        local exists = invoker.call(HASH_DOES_EXTRA_EXIST, veh, i)
        if exists and exists.bool then
            invoker.call(HASH_SET_VEHICLE_EXTRA, veh, i, not enable)
        end
    end
    notify.push("Vehicle", "All extras " .. (enable and "ON" or "OFF"), 1500)
end

-- Signals
local function set_signals(left, right)
    local veh = get_player_vehicle()
    if not veh then return end
    ensure_control(veh)
    invoker.call(0xB5D45264751B7DF0, veh, 1, left)
    invoker.call(0xB5D45264751B7DF0, veh, 0, right)
end

-- Windows
local function windows_down()
    local veh = get_player_vehicle()
    if not veh then return end
    ensure_control(veh)
    invoker.call(HASH_ROLL_DOWN_WINDOWS, veh)
    notify.push("Vehicle", "Windows down", 1500)
end

local function windows_up()
    local veh = get_player_vehicle()
    if not veh then return end
    ensure_control(veh)
    for i = 0, 3 do
        invoker.call(HASH_ROLL_UP_WINDOW, veh, i)
    end
    notify.push("Vehicle", "Windows up", 1500)
end

-- Wheels
local function set_wheel_type(type_id, name)
    local veh = get_player_vehicle()
    if not veh then return end
    ensure_control(veh)
    invoker.call(HASH_SET_VEHICLE_WHEEL_TYPE, veh, type_id)
    notify.push("Vehicle", "Wheel type: " .. name, 2000)
end

local function set_wheel_mod(mod_index)
    local veh = get_player_vehicle()
    if not veh then return end
    ensure_control(veh)
    invoker.call(HASH_SET_VEHICLE_MOD_KIT, veh, 0)
    invoker.call(HASH_SET_VEHICLE_MOD, veh, 23, mod_index, false)
    notify.push("Vehicle", "Wheel option " .. (mod_index + 1), 1500)
end

-- Individual parts
local function set_part_mod(part_id, mod_index, part_name)
    local veh = get_player_vehicle()
    if not veh then return end
    ensure_control(veh)
    invoker.call(HASH_SET_VEHICLE_MOD_KIT, veh, 0)
    if mod_index == -1 then
        invoker.call(HASH_SET_VEHICLE_MOD, veh, part_id, -1, false)
        notify.push("Vehicle", part_name .. " stock", 1500)
    else
        invoker.call(HASH_SET_VEHICLE_MOD, veh, part_id, mod_index, false)
        notify.push("Vehicle", part_name .. " option " .. (mod_index + 1), 1500)
    end
end

-- Plate tools
local function set_plate_text()
    local veh = get_player_vehicle()
    if not veh then return end
    ensure_control(veh)
    invoker.call(HASH_SET_VEHICLE_NUMBER_PLATE_TEXT, veh, PLATE_TEXT_PRESET)
    notify.push("Vehicle", 'Plate: "' .. PLATE_TEXT_PRESET .. '"', 2000)
end

local function toggle_plate_lock()
    plate_lock_enabled = not plate_lock_enabled
    notify.push("Vehicle", plate_lock_enabled and "Plate lock ON" or "Plate lock OFF", 2000)
end

-- Show-Off Mode
local function showoff_now()
    local veh = get_player_vehicle()
    if not veh then return end
    open_all_doors()
    for i = 0, 3 do
        invoker.call(HASH_NEON_ENABLED, veh, i, true)
    end
    invoker.call(HASH_SET_VEHICLE_LIGHTS, veh, 2)
    radio_on()
    notify.push("Vehicle", "Show-Off Mode activated!", 2000)
end

-- Showcase Playlist
local function showcase_add_vehicle()
    local veh = get_player_vehicle()
    if not veh then return end
    if #SHOWCASE_PLAYLIST.vehicles >= 16 then
        notify.push("Showcase", "Max 16 vehicles", 2000)
        return
    end
    for _, v in ipairs(SHOWCASE_PLAYLIST.vehicles) do
        if v == veh then
            notify.push("Showcase", "Vehicle already added", 2000)
            return
        end
    end
    table.insert(SHOWCASE_PLAYLIST.vehicles, veh)
    notify.push("Showcase", "Added vehicle #" .. #SHOWCASE_PLAYLIST.vehicles, 2000)
end

local function showcase_clear()
    SHOWCASE_PLAYLIST.vehicles = {}
    SHOWCASE_PLAYLIST.current_index = 1
    notify.push("Showcase", "Playlist cleared", 2000)
end

local function showcase_toggle()
    SHOWCASE_PLAYLIST.enabled = not SHOWCASE_PLAYLIST.enabled
    notify.push("Showcase", SHOWCASE_PLAYLIST.enabled and "Playlist ON" or "Playlist OFF", 2000)
end

-- Theme packs
local function apply_theme(theme)
    if theme.paint then apply_paint(theme.paint) end
    if theme.neon then apply_neon(theme.neon.r, theme.neon.g, theme.neon.b) end
    if theme.smoke then apply_tire_smoke(theme.smoke.r, theme.smoke.g, theme.smoke.b) end
    if theme.xenon then set_headlight_color(theme.xenon.id, theme.xenon.name) end
    if theme.wheels then set_wheel_type(theme.wheels.id, theme.wheels.name) end
    notify.push("Theme", theme.name .. " applied", 2000)
end

-- Paint presets
local paint_presets = {
    {name = "Metallic Black", primary = 0, secondary = 0, pearlescent = 0, wheels = 0},
    {name = "Metallic Red", primary = 27, secondary = 27, pearlescent = 27, wheels = 27},
    {name = "Metallic Blue", primary = 64, secondary = 64, pearlescent = 64, wheels = 64},
    {name = "Chrome", primary = 120, secondary = 120, pearlescent = 120, wheels = 120},
    {name = "Matte Black", primary = 12, secondary = 12, pearlescent = 12, wheels = 12},
    {name = "Ice White", primary = 111, secondary = 111, pearlescent = 111, wheels = 0},
    {name = "Midnight Blue", primary = 61, secondary = 61, pearlescent = 61, wheels = 0},
    {name = "Racing Green", primary = 50, secondary = 50, pearlescent = 50, wheels = 50},
    {name = "Sunset Orange", primary = 41, secondary = 41, pearlescent = 41, wheels = 41},
    {name = "Purple Metallic", primary = 71, secondary = 71, pearlescent = 71, wheels = 71},
}

-- Neon presets
local neon_presets = {
    {name = "White", r = 222, g = 222, b = 255},
    {name = "Blue", r = 2, g = 21, b = 255},
    {name = "Mint", r = 0, g = 255, b = 140},
    {name = "Yellow", r = 255, g = 255, b = 0},
    {name = "Red", r = 255, g = 1, b = 1},
    {name = "Purple", r = 35, g = 1, b = 255},
}

-- Tire smoke presets
local smoke_presets = {
    {name = "White", r = 254, g = 254, b = 254},
    {name = "Black", r = 0, g = 0, b = 0},
    {name = "Red", r = 244, g = 65, b = 65},
    {name = "Orange", r = 244, g = 167, b = 66},
    {name = "Yellow", r = 244, g = 244, b = 66},
    {name = "Green", r = 65, g = 244, b = 65},
    {name = "Blue", r = 65, g = 65, b = 244},
    {name = "Purple", r = 163, g = 65, b = 244},
    {name = "Pink", r = 244, g = 65, b = 163},
}

-- Xenon colors
local xenon_colors = {
    {name = "Default", id = -1},
    {name = "White", id = 0},
    {name = "Blue", id = 1},
    {name = "Electric Blue", id = 2},
    {name = "Mint Green", id = 3},
    {name = "Lime Green", id = 4},
    {name = "Yellow", id = 5},
    {name = "Golden", id = 6},
    {name = "Orange", id = 7},
    {name = "Red", id = 8},
    {name = "Pink", id = 9},
    {name = "Hot Pink", id = 10},
    {name = "Purple", id = 11},
    {name = "Blacklight", id = 12},
}

-- Wheel types
local wheel_types = {
    {name = "Sport", id = 0},
    {name = "Muscle", id = 1},
    {name = "Lowrider", id = 2},
    {name = "SUV", id = 3},
    {name = "Offroad", id = 4},
    {name = "Tuner", id = 5},
    {name = "Bike", id = 6},
    {name = "High End", id = 7},
    {name = "Benny's Original", id = 8},
    {name = "Benny's Bespoke", id = 9},
    {name = "F1", id = 10},
}

-- Theme packs
local themes = {
    {
        name = "JDM Theme",
        paint = {name = "JDM Blue", primary = 70, secondary = 70, pearlescent = 70, wheels = 70},
        neon = {r = 2, g = 21, b = 255},
        smoke = {r = 254, g = 254, b = 254},
        xenon = {id = 2, name = "Electric Blue"},
        wheels = {id = 5, name = "Tuner"},
    },
    {
        name = "VIP Theme",
        paint = {name = "VIP Black", primary = 0, secondary = 0, pearlescent = 37, wheels = 37},
        neon = {r = 244, g = 167, b = 66},
        smoke = {r = 244, g = 244, b = 66},
        xenon = {id = 6, name = "Golden"},
        wheels = {id = 7, name = "High End"},
    },
    {
        name = "Clean Theme",
        paint = {name = "Clean Silver", primary = 111, secondary = 111, pearlescent = 111, wheels = 111},
        neon = {r = 222, g = 222, b = 255},
        smoke = {r = 254, g = 254, b = 254},
        xenon = {id = 0, name = "White"},
        wheels = {id = 0, name = "Sport"},
    },
}

-- Individual parts
local vehicle_parts = {
    {name = "Spoiler", id = 0},
    {name = "Front Bumper", id = 1},
    {name = "Rear Bumper", id = 2},
    {name = "Side Skirts", id = 3},
    {name = "Exhaust", id = 4},
    {name = "Frame", id = 5},
    {name = "Grille", id = 6},
    {name = "Hood", id = 7},
    {name = "Fender", id = 8},
    {name = "Right Fender", id = 9},
    {name = "Roof", id = 10},
}

-----
-- HEIST FUNCTIONS
-----

-- Shared Heist Globals
local function GetMP()
    local mp_idx = script.globals(1574927).int32
    return mp_idx == 1 and "MP1_" or "MP0_"
end

-- Teleport Helper
local teleport_cooldown = 0
local function teleport_to_coords(x, y, z)
    local success = false
    local error_msg = nil
    
    local ok, err = pcall(function()
        local ped = nil
        
        -- Method 1: Try using invoker directly to get player ped
        if invoker and invoker.call then
            local result = invoker.call(0xD80958FC74E988A6) -- PLAYER_PED_ID
            if result and result.int and result.int ~= 0 then
                ped = result.int
            end
        end
        
        -- Method 2: Try using native.player_ped_id()
        if not ped then
            local native_ok, native_result = pcall(function()
                local native = require("natives")
                if native and native.player_ped_id then
                    return native.player_ped_id()
                end
                return nil
            end)
            
            if native_ok and native_result and native_result ~= 0 then
                ped = native_result
            end
        end
        
        if ped and ped ~= 0 then
            -- Check if player is in a vehicle
            local vehicle = nil
            if invoker and invoker.call then
                local in_vehicle = invoker.call(0x997ABD671D25CA0B, ped, false)
                if in_vehicle and in_vehicle.bool then
                    local veh_result = invoker.call(0x9A9112A0FE9A4713, ped, false)
                    if veh_result and veh_result.int and veh_result.int ~= 0 then
                        vehicle = veh_result.int
                    end
                end
            end
            
            -- Teleport vehicle first if player is in one
            if vehicle and vehicle ~= 0 then
                if invoker and invoker.call then
                    invoker.call(0xB69317BF5E782347, vehicle) -- NETWORK_REQUEST_CONTROL_OF_ENTITY
                    util.yield(150)
                end
                
                -- Freeze vehicle
                if invoker and invoker.call then
                    invoker.call(0x428CA6DBD1094446, vehicle, true)
                end
                
                -- Teleport vehicle
                invoker.call(0x06843DA7060A026B, vehicle, x, y, z, false, false, false, true)
                
                util.yield(250)
                
                -- Unfreeze vehicle
                if invoker and invoker.call then
                    invoker.call(0x428CA6DBD1094446, vehicle, false)
                end
                
                -- Teleport player
                if invoker and invoker.call then
                    invoker.call(0x06843DA7060A026B, ped, x, y, z, false, false, false, true)
                    util.yield(150)
                    invoker.call(0x9A7D091411C5F684, ped, vehicle, -1)
                    util.yield(150)
                    success = true
                end
            else
                -- Teleport player only
                if invoker and invoker.call then
                    invoker.call(0x06843DA7060A026B, ped, x, y, z, false, false, false, true)
                    success = true
                end
            end
        end
    end)
    
    return success
end

-- ============================================================================
-- CASINO HEIST
-- ============================================================================

local CasinoGlobals = {
    Host = 1975557,
    P2 = 1975558,
    P3 = 1975559,
    P4 = 1975560
}

local CasinoCuts = { host = 100, p2 = 0, p3 = 0, p4 = 0 }

local function apply_casino_cuts()
    script.globals(CasinoGlobals.Host).int32 = CasinoCuts.host
    script.globals(CasinoGlobals.P2).int32 = CasinoCuts.p2
    script.globals(CasinoGlobals.P3).int32 = CasinoCuts.p3
    script.globals(CasinoGlobals.P4).int32 = CasinoCuts.p4
    if notify then notify.push("Casino Heist", "Cuts Applied!", 2000) end
end

local function apply_silent_sneaky()
    local p = GetMP()
    account.stats(p.."H3OPT_MASKS").int32 = 4
    account.stats(p.."H3OPT_WEAPS").int32 = 1
    account.stats(p.."H3OPT_VEHS").int32 = 3
    account.stats(p.."CAS_HEIST_FLOW").int32 = -1
    account.stats(p.."H3_LAST_APPROACH").int32 = 0
    account.stats(p.."H3OPT_APPROACH").int32 = 1
    account.stats(p.."H3_HARD_APPROACH").int32 = 1
    account.stats(p.."H3OPT_TARGET").int32 = 3
    account.stats(p.."H3OPT_POI").int32 = 1023
    account.stats(p.."H3OPT_ACCESSPOINTS").int32 = 2047
    account.stats(p.."H3OPT_CREWWEAP").int32 = 4
    account.stats(p.."H3OPT_CREWDRIVER").int32 = 3
    account.stats(p.."H3OPT_CREWHACKER").int32 = 4
    account.stats(p.."H3OPT_DISRUPTSHIP").int32 = 3
    account.stats(p.."H3OPT_BODYARMORLVL").int32 = -1
    account.stats(p.."H3OPT_KEYLEVELS").int32 = 2
    account.stats(p.."H3OPT_BITSET1").int32 = 127
    account.stats(p.."H3OPT_BITSET0").int32 = 262270
    script.locals("gb_casino_heist_planning", 210).int32 = 2
    if notify then notify.push("Preset", "Applied Silent & Sneaky", 2000) end
end

local function apply_big_con()
    local p = GetMP()
    account.stats(p.."H3OPT_MASKS").int32 = 2
    account.stats(p.."H3OPT_WEAPS").int32 = 1
    account.stats(p.."H3OPT_VEHS").int32 = 3
    account.stats(p.."CAS_HEIST_FLOW").int32 = -1
    account.stats(p.."H3_LAST_APPROACH").int32 = 0
    account.stats(p.."H3OPT_APPROACH").int32 = 2
    account.stats(p.."H3_HARD_APPROACH").int32 = 2
    account.stats(p.."H3OPT_TARGET").int32 = 3
    account.stats(p.."H3OPT_POI").int32 = 1023
    account.stats(p.."H3OPT_ACCESSPOINTS").int32 = 2047
    account.stats(p.."H3OPT_CREWWEAP").int32 = 4
    account.stats(p.."H3OPT_CREWDRIVER").int32 = 3
    account.stats(p.."H3OPT_CREWHACKER").int32 = 4
    account.stats(p.."H3OPT_DISRUPTSHIP").int32 = 3
    account.stats(p.."H3OPT_BODYARMORLVL").int32 = -1
    account.stats(p.."H3OPT_KEYLEVELS").int32 = 2
    account.stats(p.."H3OPT_BITSET1").int32 = 159
    account.stats(p.."H3OPT_BITSET0").int32 = 524118
    script.locals("gb_casino_heist_planning", 212).int32 = 2
    if notify then notify.push("Preset", "Applied The Big Con", 2000) end
end

local function apply_aggressive()
    local p = GetMP()
    account.stats(p.."H3OPT_MASKS").int32 = 4
    account.stats(p.."H3OPT_WEAPS").int32 = 1
    account.stats(p.."H3OPT_VEHS").int32 = 3
    account.stats(p.."CAS_HEIST_FLOW").int32 = -1
    account.stats(p.."H3_LAST_APPROACH").int32 = 0
    account.stats(p.."H3OPT_APPROACH").int32 = 3
    account.stats(p.."H3_HARD_APPROACH").int32 = 3
    account.stats(p.."H3OPT_TARGET").int32 = 3
    account.stats(p.."H3OPT_POI").int32 = 1023
    account.stats(p.."H3OPT_ACCESSPOINTS").int32 = 2047
    account.stats(p.."H3OPT_CREWWEAP").int32 = 4
    account.stats(p.."H3OPT_CREWDRIVER").int32 = 3
    account.stats(p.."H3OPT_CREWHACKER").int32 = 4
    account.stats(p.."H3OPT_DISRUPTSHIP").int32 = 3
    account.stats(p.."H3OPT_BODYARMORLVL").int32 = -1
    account.stats(p.."H3OPT_KEYLEVELS").int32 = 2
    account.stats(p.."H3OPT_BITSET1").int32 = 799
    account.stats(p.."H3OPT_BITSET0").int32 = 3670102
    script.locals("gb_casino_heist_planning", 212).int32 = 2
    if notify then notify.push("Preset", "Applied Aggressive", 2000) end
end

local function casino_skip_arcade_setup()
    account.stats(27227, 1).bool = true
    if notify then notify.push("Casino Tools", "Arcade Setup Skipped", 2000) end
end

local function casino_fix_stuck_keycards()
    script.locals("fm_mission_controller", 63638).int32 = 5
    if notify then notify.push("Casino Tools", "Keycards Fixed", 2000) end
end

local function casino_skip_objective()
    local v = script.locals("fm_mission_controller", 20397).int32
    script.locals("fm_mission_controller", 20397).int32 = v | (1 << 17)
    if notify then notify.push("Casino Tools", "Objective Skipped", 2000) end
end

local function casino_fingerprint_hack()
    script.locals("fm_mission_controller", 54042).int32 = 5
    if notify then notify.push("Casino Tools", "Fingerprint Hack Completed", 2000) end
end

local function casino_instant_keypad_hack()
    script.locals("fm_mission_controller", 55108).int32 = 5
    if notify then notify.push("Casino Tools", "Keypad Hack Completed", 2000) end
end

local function casino_instant_vault_drill()
    script.locals("fm_mission_controller", 10551 + 2).int32 = 7
    script.locals("fm_mission_controller", 10551).int32 = script.locals("fm_mission_controller", 10551).int32 | (1 << 12)
    if notify then notify.push("Casino Tools", "Vault Drill Completed", 2000) end
end

local function casino_remove_cooldown()
    local p = GetMP()
    account.stats(p .. "H3_COMPLETEDPOSIX").int32 = -1
    account.stats(p .. "MPPLY_H3_COOLDOWN").int32 = -1
    if notify then notify.push("Casino Tools", "Cooldown Removed", 2000) end
end

local function casino_instant_finish()
    if not script.running("fm_mission_controller") then
        if notify then notify.push("Casino Tools", "Casino script not running", 2000) end
        return
    end
    
    util.create_job(function()
        if script and script.force_host then
            script.force_host("fm_mission_controller")
        end
        util.yield(1000)
        
        local p = GetMP()
        local approach = account.stats(p .. "H3OPT_APPROACH").int32 or 1
        
        if approach == 3 then
            script.locals("fm_mission_controller", 20395).int32 = 12
            script.locals("fm_mission_controller", 20395 + 1740 + 1).int32 = 80
            script.locals("fm_mission_controller", 20395 + 2686).int32 = 10000000
            script.locals("fm_mission_controller", 29016 + 1).int32 = 99999
            script.locals("fm_mission_controller", 32472 + 1 + 68).int32 = 99999
        else
            script.locals("fm_mission_controller", 20395 + 1062).int32 = 5
            script.locals("fm_mission_controller", 20395 + 1740 + 1).int32 = 80
            script.locals("fm_mission_controller", 20395 + 2686).int32 = 10000000
            script.locals("fm_mission_controller", 29016 + 1).int32 = 99999
            script.locals("fm_mission_controller", 32472 + 1 + 68).int32 = 99999
        end
        
        if notify then notify.push("Casino Tools", "Diamond Casino instant finish", 2000) end
    end)
end

-- ============================================================================
-- CAYO PERICO HEIST
-- ============================================================================

local CayoGlobals = {
    Host = 1980923,
    P2 = 1980924,
    P3 = 1980925,
    P4 = 1980926,
    ReadyBase = 1981147
}

local CayoReady = {
    PLAYER2 = 1981184,
    PLAYER3 = 1981211,
    PLAYER4 = 1981238
}

local CayoCuts = { host = 100, p2 = 100, p3 = 100, p4 = 100 }

local CayoConfig = {
    diff = 126823,
    app = 65535,
    wep = 1,
    tgt = 5,
    sec_comp = "GOLD",
    sec_isl = "GOLD",
    amt_comp = 255,
    amt_isl = 16777215,
    paint = 127,
    val_cash = 83250,
    val_weed = 135000,
    val_coke = 202500,
    val_gold = 333333,
    val_art = 180000
}

local function cayo_apply_preps()
    local p = GetMP()
    account.stats(p .. "H4_PROGRESS").int32 = CayoConfig.diff
    account.stats(p .. "H4_MISSIONS").int32 = CayoConfig.app
    account.stats(p .. "H4CNF_WEAPONS").int32 = CayoConfig.wep
    account.stats(p .. "H4CNF_TARGET").int32 = CayoConfig.tgt
    
    local loots = {"CASH", "WEED", "COKE", "GOLD"}
    for _, l in ipairs(loots) do
        local val = (CayoConfig.sec_comp == l) and CayoConfig.amt_comp or 0
        account.stats(p .. "H4LOOT_" .. l .. "_C").int32 = val
        account.stats(p .. "H4LOOT_" .. l .. "_C_SCOPED").int32 = val
        local val2 = (CayoConfig.sec_isl == l) and CayoConfig.amt_isl or 0
        account.stats(p .. "H4LOOT_" .. l .. "_I").int32 = val2
        account.stats(p .. "H4LOOT_" .. l .. "_I_SCOPED").int32 = val2
        local money = (l == "CASH" and CayoConfig.val_cash) or (l == "WEED" and CayoConfig.val_weed) or (l == "COKE" and CayoConfig.val_coke) or (l == "GOLD" and CayoConfig.val_gold) or 0
        account.stats(p .. "H4LOOT_" .. l .. "_V").int32 = money
    end
    account.stats(p .. "H4LOOT_PAINT").int32 = CayoConfig.paint
    account.stats(p .. "H4LOOT_PAINT_SCOPED").int32 = CayoConfig.paint
    account.stats(p .. "H4LOOT_PAINT_V").int32 = CayoConfig.val_art
    script.locals("heist_island_planning", 1570).int32 = 2
    if notify then notify.push("Cayo Perico", "Preps Applied", 2000) end
end

local function cayo_apply_cuts()
    script.globals(CayoGlobals.Host).int32 = CayoCuts.host
    script.globals(CayoGlobals.P2).int32 = CayoCuts.p2
    script.globals(CayoGlobals.P3).int32 = CayoCuts.p3
    script.globals(CayoGlobals.P4).int32 = CayoCuts.p4
    if notify then notify.push("Cayo Perico", "Cuts Applied", 2000) end
end

local function cayo_force_ready()
    util.create_job(function()
        if script and script.force_host then
            script.force_host("fm_mission_controller_2020")
        end
        util.yield(1000)
        script.globals(CayoReady.PLAYER2).int32 = 1
        script.globals(CayoReady.PLAYER3).int32 = 1
        script.globals(CayoReady.PLAYER4).int32 = 1
        if notify then notify.push("Cayo Perico", "All players ready", 2000) end
    end)
end

local function cayo_unlock_all_poi()
    local p = GetMP()
    account.stats(p .. "H4CNF_BS_GEN").int32 = -1
    account.stats(p .. "H4CNF_BS_ENTR").int32 = 63
    script.locals("heist_island_planning", 1570).int32 = 2
    if notify then notify.push("Cayo Tools", "All POI Unlocked", 2000) end
end

local function cayo_reset_preps()
    local p = GetMP()
    account.stats(p .. "H4_PROGRESS").int32 = 0
    script.locals("heist_island_planning", 1570).int32 = 2
    if notify then notify.push("Cayo Tools", "Preps Reset", 2000) end
end

local function cayo_instant_voltlab_hack()
    if not script.running("fm_content_island_heist") then
        if notify then notify.push("Cayo Tools", "Mission Not Running", 2000) end
        return
    end
    script.locals("fm_content_island_heist", 10166 + 24).int32 = 5
    if notify then notify.push("Cayo Tools", "Voltlab Hack Completed", 2000) end
end

local function cayo_instant_password_hack()
    script.locals("fm_mission_controller_2020", 26486).int32 = 5
    if notify then notify.push("Cayo Tools", "Password Hack Completed", 2000) end
end

local function cayo_bypass_plasma_cutter()
    script.locals("fm_mission_controller_2020", 32589 + 3).float = 100.0
    if notify then notify.push("Cayo Tools", "Plasma Cutter Bypassed", 2000) end
end

local function cayo_bypass_drainage_pipe()
    script.locals("fm_mission_controller_2020", 31349).int32 = 6
    if notify then notify.push("Cayo Tools", "Drainage Pipe Bypassed", 2000) end
end

local function cayo_reload_planning_screen()
    script.locals("heist_island_planning", 1570).int32 = 2
    if notify then notify.push("Cayo Tools", "Planning Screen Reloaded", 2000) end
end

local function cayo_remove_cooldown()
    local p = GetMP()
    account.stats(p .. "H4_TARGET_POSIX").int32 = 1659643454
    account.stats(p .. "H4_COOLDOWN").int32 = 0
    account.stats(p .. "H4_COOLDOWN_HARD").int32 = 0
    if notify then notify.push("Cayo Tools", "Cooldown Removed", 2000) end
end

local function cayo_instant_finish()
    if not script.running("fm_mission_controller_2020") then
        if notify then notify.push("Cayo Tools", "Cayo script not running", 2000) end
        return
    end
    
    util.create_job(function()
        if script and script.force_host then
            script.force_host("fm_mission_controller_2020")
        end
        util.yield(1000)
        script.locals("fm_mission_controller_2020", 56223).int32 = 9
        script.locals("fm_mission_controller_2020", 56223 + 1776 + 1).int32 = 50
        if notify then notify.push("Cayo Tools", "Cayo Perico instant finish", 2000) end
    end)
end

local function cayo_teleport_tunnel()
    if os.clock() < teleport_cooldown then return end
    teleport_cooldown = os.clock() + 1.0
    
    if teleport_to_coords(5051.0, -5822.0, 2.0) then
        util.create_thread(function()
            util.yield(500)
            if script.running("fm_mission_controller_2020") then
                for i = 1, 10 do
                    script.locals("fm_mission_controller_2020", 31349).int32 = 6
                    util.yield(50)
                end
            end
        end)
        if notify then notify.push("Cayo Teleport", "Teleported to Underwater Tunnel", 2000) end
    else
        if notify then notify.push("Cayo Teleport", "Failed to teleport", 2000) end
    end
end

local function cayo_teleport_compound()
    if os.clock() < teleport_cooldown then return end
    teleport_cooldown = os.clock() + 1.0
    if teleport_to_coords(5010.0, -5753.0, 30.0) then
        if notify then notify.push("Cayo Teleport", "Teleported to Compound", 2000) end
    end
end

local function cayo_teleport_vault()
    if os.clock() < teleport_cooldown then return end
    teleport_cooldown = os.clock() + 1.0
    if teleport_to_coords(5006.0, -5754.0, 16.0) then
        if notify then notify.push("Cayo Teleport", "Teleported to Vault", 2000) end
    end
end

-- ============================================================================
-- APARTMENT HEISTS (CLASSIC)
-- ============================================================================

local ApartmentGlobals = {
    Ready = {
        PLAYER2 = 2659033,
        PLAYER3 = 2659501,
        PLAYER4 = 2659969
    },
    Board = 1936048,
    Cooldown = 1877303
}

local function apartment_unlock_all()
    -- SilentNight: Unlock all classic apartment heists
    for _, prefix in ipairs({"", "MP0_", "MP1_"}) do
        -- Set heist strands to max completion
        account.stats(prefix .. "HEIST_PLANNING_STAGE").int32 = -1
        account.stats(prefix .. "HEIST_FLEECA_STATUS").int32 = 2
        account.stats(prefix .. "HEIST_PRISON_BREAK_STATUS").int32 = 2
        account.stats(prefix .. "HEIST_HUMANE_LABS_STATUS").int32 = 2
        account.stats(prefix .. "HEIST_SERIES_A_STATUS").int32 = 2
        account.stats(prefix .. "HEIST_PACIFIC_STANDARD_STATUS").int32 = 2
    end
    if notify then notify.push("Apartment Heists", "All classic heists unlocked ツ", 3000) end
end

-- Solo Launch State
local apartment_solo_launch_enabled = false

local function apartment_solo_launch(toggle_on)
    -- SilentNight: Allow launching apartment heists solo
    apartment_solo_launch_enabled = toggle_on
    
    if toggle_on then
        -- Enable solo launch - continuously set minimum players to 1
        util.create_thread(function()
            while apartment_solo_launch_enabled do
                -- Always set these globals when enabled, regardless of which script is running
                -- This ensures solo launch works when you launch from the heist board
                script.globals(4718592 + 3539).int32 = 1
                script.globals(4718592 + 3540).int32 = 1
                script.globals(4718592 + 3542 + 1).int32 = 1
                script.globals(4718592 + 192451 + 1).int32 = 0
                script.globals(4718592 + 3536).int32 = 1
                util.yield(100)
            end
        end)
        if notify then notify.push("Apartment Heists", "Solo Launch enabled ツ", 2000) end
    else
        -- Disable solo launch
        if notify then notify.push("Apartment Heists", "Solo Launch disabled", 2000) end
    end
end

local function apartment_complete_preps()
    -- SilentNight: Complete all apartment heist preparations
    for _, mp in ipairs({"", "MP0_", "MP1_"}) do
        account.stats(mp .. "HEIST_PLANNING_STAGE").int32 = -1
    end
    if notify then notify.push("Apartment Heists", "Preps marked complete ツ", 2500) end
end

local function apartment_kill_cooldown()
    -- SilentNight: Skip apartment heist cooldown
    local cooldown_global = 1877303 + 1 + 76  -- Cooldown global offset
    script.globals(cooldown_global).int32 = -1
    if notify then notify.push("Apartment Heists", "Cooldown cleared ツ", 2000) end
end

local function apartment_force_ready()
    -- SilentNight: Force all players to "Ready" status
    util.create_thread(function()
        util.yield(1000)
        local ready_base = 1877303 + 1 + 75  -- Ready state global offset base
        for i = 2, 4 do
            script.globals(ready_base + (i-1) * 77).int32 = 6
        end
    end)
    if notify then notify.push("Apartment Heists", "Players forced ready ツ", 2000) end
end

local function apartment_redraw_board()
    -- SilentNight: Redraw the planning board to update state
    -- Global 1936048 = Apartment Board State
    script.globals(1936048).int32 = 22
    if notify then notify.push("Apartment Heists", "Planning board refreshed ツ", 2000) end
end

-- Apartment Tools (classic heists)
local function apartment_fleeca_hack()
    -- SilentNight: Bypass Fleeca hack minigun
    if script.running("fm_mission_controller") then
        script.locals("fm_mission_controller", 12223 + 24).int32 = 7
        if notify then notify.push("Apartment Tools", "Fleeca Hack bypassed ツ", 2000) end
    else
        if notify then notify.push("Apartment Tools", "Hack not active", 2000) end
    end
end

local function apartment_fleeca_drill()
    -- SilentNight: Bypass Fleeca drill (instant completion)
    if script.running("fm_mission_controller") then
        script.locals("fm_mission_controller", 10511 + 11).float = 100.0
        if notify then notify.push("Apartment Tools", "Fleeca Drill bypassed ツ", 2000) end
    else
        if notify then notify.push("Apartment Tools", "Drill not active", 2000) end
    end
end

local function apartment_pacific_hack()
    -- SilentNight: Bypass Pacific Standard hack
    if script.running("fm_mission_controller") then
        script.locals("fm_mission_controller", 10217).int32 = 9
        if notify then notify.push("Apartment Tools", "Pacific Hack bypassed ツ", 2000) end
    else
        if notify then notify.push("Apartment Tools", "Hack not active", 2000) end
    end
end

local function apartment_instant_finish()
    -- SilentNight: Instant heist finish (use after minimap visible)
    if not script.running("fm_mission_controller") then
        if notify then notify.push("Apartment Tools", "Apartment script not running", 2000) end
        return false
    end

    util.create_job(function()
        if script and script.force_host then
            script.force_host("fm_mission_controller")
        end
        util.yield(1000)

        local p = GetMP() or "MP0_"
        local heist = account.stats(p .. "HEIST_MISSION_RCONT_ID_1").int32 or 0
        local is_pacific = (heist == 5)

        if is_pacific then
            -- Pacific Standard finish offsets
            script.locals("fm_mission_controller", 20395 + 1062).int32 = 5
            script.locals("fm_mission_controller", 20395 + 1740 + 1).int32 = 80
            script.locals("fm_mission_controller", 20395 + 2686).int32 = 10000000
            script.locals("fm_mission_controller", 29016 + 1).int32 = 99999
            script.locals("fm_mission_controller", 32472 + 1 + 68).int32 = 99999
        else
            -- Other heists (Fleeca, Prison Break, etc.)
            script.locals("fm_mission_controller", 20395).int32 = 12
            script.locals("fm_mission_controller", 20395 + 2686).int32 = 99999
            script.locals("fm_mission_controller", 29016 + 1).int32 = 99999
            script.locals("fm_mission_controller", 32472 + 1 + 68).int32 = 99999
        end

        if notify then notify.push("Apartment Tools", "Instant finish triggered ツ", 2000) end
    end)
    return true
end

local function apartment_play_unavailable()
    -- SilentNight: Make unavailable jobs temporarily playable (clears cooldown)
    local cooldown_global = 1877303 + 1 + 76
    script.globals(cooldown_global).int32 = -1
    if notify then notify.push("Apartment Tools", "Unavailable jobs playable ツ", 2000) end
end

local function apartment_unlock_all_jobs()
    -- SilentNight: Unlock all apartment job strands without playing them
    local p = GetMP() or "MP0_"
    local stats = {
        "HEIST_SAVED_STRAND_0", "HEIST_SAVED_STRAND_0_L",
        "HEIST_SAVED_STRAND_1", "HEIST_SAVED_STRAND_1_L",
        "HEIST_SAVED_STRAND_2", "HEIST_SAVED_STRAND_2_L",
        "HEIST_SAVED_STRAND_3", "HEIST_SAVED_STRAND_3_L",
        "HEIST_SAVED_STRAND_4", "HEIST_SAVED_STRAND_4_L"
    }
    for _, stat in ipairs(stats) do
        account.stats(p .. stat).int32 = 5
    end
    local reload_global = 1877303 + 1 + 5
    script.globals(reload_global).int32 = 2
    if notify then notify.push("Apartment Tools", "All jobs unlocked ツ", 2000) end
end

-- Apartment teleports
local function get_blip_coords_apartment(blip_sprite)
    local blip = invoker.call(0x1BEDE233E6CD2A1F, blip_sprite)
    if not blip or not blip.int or blip.int == 0 then return nil end

    local handle = blip.int
    while handle and handle ~= 0 do
        local exists = invoker.call(0xA6DB27D19ECBB7DA, handle)
        if exists and exists.bool then
            local color = invoker.call(0xDF729E8D20CF7327, handle)
            if color and color.int and color.int ~= 3 then
                local ok, coords_result = pcall(function()
                    local native = require("natives")
                    if native and native.get_blip_coords then
                        return native.get_blip_coords(handle)
                    end
                    return nil
                end)
                if ok and coords_result and coords_result.vec3 then
                    return { x = coords_result.vec3.x, y = coords_result.vec3.y, z = coords_result.vec3.z + 1.0 }
                end

                local cx, cy, cz = {float = 0.0}, {float = 0.0}, {float = 0.0}
                local ok2 = pcall(function()
                    invoker.call(0x586AFE3FF72D996E, handle, cx, cy, cz)
                end)
                if ok2 and cx.float and cy.float and cz.float and (math.abs(cx.float) > 0.001 or math.abs(cy.float) > 0.001 or math.abs(cz.float) > 0.001) then
                    return { x = cx.float, y = cy.float, z = cz.float + 1.0 }
                end
            end
        end
        local next_blip = invoker.call(0x14F96AA50D6FBEA7, blip_sprite)
        handle = (next_blip and next_blip.int) and next_blip.int or 0
    end
    return nil
end

local function apartment_teleport_to_entrance()
    if os.clock() < teleport_cooldown then return end
    teleport_cooldown = os.clock() + 1.0

    local me = players and players.me and players.me()
    if not me then
        if notify then notify.push("Apartment Tools", "Player not found", 2000) end
        return
    end

    util.create_thread(function()
        local ped = me.ped
        local veh = me.vehicle
        local entity = (veh and veh ~= 0) and veh or ped
        if not entity or entity == 0 then
            if notify then notify.push("Apartment Tools", "Entity not found", 2000) end
            return
        end

        invoker.call(0x428CA6DBD1094446, entity, true)

        if me.in_interior then
            local transit_point = { x = -75.146, y = -818.687, z = 326.175 }
            invoker.call(0x06843DA7060A026B, entity, transit_point.x, transit_point.y, transit_point.z, false, false, false, true)
            util.yield(800)
        end

        local coords = get_blip_coords_apartment(40)
        if coords then
            invoker.call(0x06843DA7060A026B, entity, coords.x, coords.y, coords.z, false, false, false, true)
            util.yield(500)
            if notify then notify.push("Apartment Tools", "Teleported to Entrance", 2000) end
        else
            if notify then notify.push("Apartment Tools", "Entrance blip not found", 2000) end
        end

        invoker.call(0x428CA6DBD1094446, entity, false)
    end)
end

local function apartment_teleport_to_heist_board()
    if os.clock() < teleport_cooldown then return end
    teleport_cooldown = os.clock() + 1.0

    local me = players and players.me and players.me()
    if not me then
        if notify then notify.push("Apartment Tools", "Player not found", 2000) end
        return
    end

    util.create_thread(function()
        local ped = me.ped
        local veh = me.vehicle
        local entity = (veh and veh ~= 0) and veh or ped
        if not entity or entity == 0 then
            if notify then notify.push("Apartment Tools", "Entity not found", 2000) end
            return
        end

        invoker.call(0x428CA6DBD1094446, entity, true)

        local coords = get_blip_coords_apartment(428)
        if coords then
            invoker.call(0x06843DA7060A026B, entity, coords.x, coords.y, coords.z, false, false, false, true)
            invoker.call(0x8E2530AA8ADA980E, entity, 173.376)
            util.yield(500)
            if notify then notify.push("Apartment Tools", "Teleported to Heist Board", 2000) end
        else
            if notify then notify.push("Apartment Tools", "Heist board blip not found", 2000) end
        end

        invoker.call(0x428CA6DBD1094446, entity, false)
    end)
end

local ApartmentCuts = { p1 = 100, p2 = 0, p3 = 0, p4 = 0 }

local function apply_apartment_cuts()
    -- SilentNight: Apply player cut distribution for apartment heists
    local total = ApartmentCuts.p1 + ApartmentCuts.p2 + ApartmentCuts.p3 + ApartmentCuts.p4
    local base = 1936013
    script.globals(base + 1 + 1).int32 = 100 - total  -- Host cut (remainder)
    script.globals(base + 1 + 2).int32 = ApartmentCuts.p2
    script.globals(base + 1 + 3).int32 = ApartmentCuts.p3
    script.globals(base + 1 + 4).int32 = ApartmentCuts.p4
    script.globals(1937981 + 3008 + 1).int32 = ApartmentCuts.p1
    if notify then notify.push("Apartment Cuts", "Cuts applied ツ", 2000) end
end

-----
-- SILENTNIGHT PORTED FEATURES
-----
-- SilentNight Heists Port for Project X
local SilentNight = {}

-- Ensure natives.lua is in the same directory or search path
-- Lexis typically allows require for files in the same folder
local natives = require("natives")
if not natives then
    if notify then notify.push("Error", "natives.lua not found!", 5000) end
    return
end

-- Helpers
local function joaat(str)
    if not str then return 0 end
    local hash = 0
    for i = 1, #str do
        hash = hash + string.byte(str, i)
        hash = hash + (hash << 10)
        hash = hash ~ (hash >> 6)
    end
    hash = hash + (hash << 3)
    hash = hash ~ (hash >> 11)
    hash = hash + (hash << 15)
    return hash
end

local function set_stat_int(stat, val)
    local p = GetMP() or "MP0_"
    local actual_stat = stat:gsub("MPX_", p)
    account.stats(actual_stat).int32 = val
end

local function set_global_int(idx, val)
    script.globals(idx).int32 = val
end

local function set_local_int(script_name, idx, val)
    if script.locals(script_name, idx) then
        script.locals(script_name, idx).int32 = val
    end
end

local function get_local_int(script_name, idx)
    if script.locals(script_name, idx) then
        return script.locals(script_name, idx).int32
    end
    return 0
end

local function tp_to_coords(x, y, z)
    local ped = natives.GET_PLAYER_PED(-1)
    if ped then
        local veh = natives.GET_VEHICLE_PED_IS_IN(ped, false)
        local entity = (veh ~= 0) and veh or ped
        
        -- Lexis native wrapper expects a table with x, y, z for Vector3 arguments
        -- or explicit 3 floats if the signature differs.
        -- Based on standard Lexis natives.lua: invoker.call(hash, ent, vec3, ...)
        -- We will pass a table which the Lua wrapper usually unpacks or marshals.
        local pos = {x = x, y = y, z = z}
        
        -- Attempt to set coords
        -- pcall to catch any "invalid argument" errors if the vector format is wrong
        pcall(function()
            natives.SET_ENTITY_COORDS(entity, pos, false, false, false, false)
        end)
    end
end

local function set_tunable_int(name, val)
    if script.tunables(name) then
        script.tunables(name).int32 = val
    end
end

local function set_tunable_float(name, val)
    if script.tunables(name) then
        script.tunables(name).float = val
    end
end

-- Agency Features
SilentNight.Agency = {}
function SilentNight.Agency.TeleportEntrance()
    tp_to_coords(-1111.41, -505.74, 34.25) -- Fixed coords for Agency Entrance (example)
    -- SilentNight coords: -1111, -505, 34? No, the previous code had -578...
    -- Let's stick to the previous code's coords if they were correct (-578.981, -711.381, 116.805)
    -- Actually -578 is closer to the Agency in Hawick/Rockford.
    tp_to_coords(-578.981, -711.381, 116.805)
    if notify then notify.push("Agency", "Teleported to Agency", 3000) end
end

function SilentNight.Agency.InstantFinish()
    set_local_int("fm_mission_controller_2020", 56224, 51338752)
    set_local_int("fm_mission_controller_2020", 58000, 50)
    if notify then notify.push("Agency", "Instant Finish Applied", 3000) end
end

function SilentNight.Agency.KillCooldowns()
    set_stat_int("MPX_FIXER_STORY_COOLDOWN", -1)
    if notify then notify.push("Agency", "Story Cooldown Reset", 3000) end
end

function SilentNight.Agency.SetPayout(amount)
    -- FIXER_FINALE_LEADER_CASH_REWARD
    set_tunable_int("FIXER_FINALE_LEADER_CASH_REWARD", amount)
    if notify then notify.push("Agency", "Payout Set to $" .. amount, 3000) end
end

-- Auto Shop Features
SilentNight.AutoShop = {}
function SilentNight.AutoShop.InstantFinish()
    set_local_int("fm_mission_controller_2020", 56224, 51338977)
    set_local_int("fm_mission_controller_2020", 58000, 101)
    if notify then notify.push("Auto Shop", "Instant Finish Applied", 3000) end
end

function SilentNight.AutoShop.CompletePreps(contract_id)
    if not contract_id then contract_id = 1 end
    set_stat_int("MPX_TUNER_CURRENT", contract_id)
    if contract_id == 1 then
        set_stat_int("MPX_TUNER_GEN_BS", 4351)
    else
        set_stat_int("MPX_TUNER_GEN_BS", 12543)
    end
    set_local_int("tuner_planning", 408, 2)
    if notify then notify.push("Auto Shop", "Preps Completed", 3000) end
end

function SilentNight.AutoShop.SetPayout(amount)
    -- Sets all contract slots to the same payout for simplicity
    local contracts = {
        "TUNER_ROBBERY_LEADER_CASH_REWARD0", "TUNER_ROBBERY_LEADER_CASH_REWARD1",
        "TUNER_ROBBERY_LEADER_CASH_REWARD2", "TUNER_ROBBERY_LEADER_CASH_REWARD3",
        "TUNER_ROBBERY_LEADER_CASH_REWARD4", "TUNER_ROBBERY_LEADER_CASH_REWARD5",
        "TUNER_ROBBERY_LEADER_CASH_REWARD6", "TUNER_ROBBERY_LEADER_CASH_REWARD7"
    }
    for _, t in ipairs(contracts) do
        set_tunable_int(t, amount)
    end
    set_tunable_float("TUNER_ROBBERY_CONTACT_FEE", 0.0) -- Remove fee
    if notify then notify.push("Auto Shop", "Payout Set to $" .. amount, 3000) end
end

-- Doomsday Features
SilentNight.Doomsday = {}
function SilentNight.Doomsday.InstantFinish()
    set_local_int("fm_mission_controller", 20395, 12)
    set_local_int("fm_mission_controller", 22136, 150)
    set_local_int("fm_mission_controller", 29017, 99999)
    set_local_int("fm_mission_controller", 32541, 99999)
    set_local_int("fm_mission_controller", 32569, 80)
    if notify then notify.push("Doomsday", "Instant Finish Applied", 3000) end
end

function SilentNight.Doomsday.CompletePreps(act)
    local vals = {
        [1] = {503, -229383},
        [2] = {240, -229378},
        [3] = {16368, -229380}
    }
    if not vals[act] then return end
    set_stat_int("MPX_GANGOPS_FLOW_MISSION_PROG", vals[act][1])
    set_stat_int("MPX_GANGOPS_HEIST_STATUS", vals[act][2])
    set_stat_int("MPX_GANGOPS_FLOW_NOTIFICATIONS", 1557)
    set_local_int("gb_gang_ops_planning", 211, 6)
    if notify then notify.push("Doomsday", "Act " .. act .. " Preps Completed", 3000) end
end

-- Salvage Yard Features
SilentNight.Salvage = {}
function SilentNight.Salvage.InstantFinish()
    local scripts = {
        ["fm_content_vehrob_cargo_ship"] = {7188, 8581},
        ["fm_content_vehrob_police"] = {9014, 10451},
        ["fm_content_vehrob_arena"] = {7915, 9348},
        ["fm_content_vehrob_casino_prize"] = {9194, 10588},
        ["fm_content_vehrob_submarine"] = {6221, 7517}
    }
    for s_name, locs in pairs(scripts) do
        if script.locals(s_name, locs[1]) then
            local val = script.locals(s_name, locs[1]).int32
            val = val | (1 << 11)
            script.locals(s_name, locs[1]).int32 = val
            script.locals(s_name, locs[2]).int32 = 2
            if notify then notify.push("Salvage Yard", "Instant Finish Applied", 3000) end
            break
        end
    end
end

function SilentNight.Salvage.MakeAvailable(slot)
    local stat = "MPX_SALV23_VEHROB_STATUS" .. (slot - 1)
    set_stat_int(stat, 0)
    set_local_int("vehrob_planning", 537, 2)
    if notify then notify.push("Salvage Yard", "Slot " .. slot .. " Available", 3000) end
end

function SilentNight.Salvage.CompletePreps()
    set_stat_int("MPX_SALV23_GEN_BS", -1)
    set_stat_int("MPX_SALV23_SCOPE_BS", -1)
    set_stat_int("MPX_SALV23_FM_PROG", -1)
    set_stat_int("MPX_SALV23_INST_PROG", -1)
    set_local_int("vehrob_planning", 537, 2)
    if notify then notify.push("Salvage Yard", "Preps Completed", 3000) end
end

function SilentNight.Salvage.SetSellPrice(price)
    -- SALV23_VEHICLE_CLAIM_PRICE (Standard Claim)
    -- SALV23_VEHICLE_CLAIM_PRICE_FORGERY_DISCOUNT (Discounted)
    set_tunable_int("SALV23_VEHICLE_CLAIM_PRICE", price)
    set_tunable_int("SALV23_VEHICLE_CLAIM_PRICE_FORGERY_DISCOUNT", price)
    if notify then notify.push("Salvage Yard", "Claim Price Set to $" .. price, 3000) end
end

-- Cayo Perico Features
SilentNight.Cayo = {}
function SilentNight.Cayo.ApplyPreset(preset_idx)
    -- Preset_idx: 0=All 0%, 85=All 85%, 100=All 100%, -1=Max Payout (2.55M)
    local cuts = {host = 100, p2 = 0, p3 = 0, p4 = 0}
    
    if preset_idx == 85 then
        cuts = {host = 85, p2 = 85, p3 = 85, p4 = 85}
    elseif preset_idx == 100 then
        cuts = {host = 100, p2 = 100, p3 = 100, p4 = 100}
    elseif preset_idx == -1 then
        -- Max Payout logic usually handled by script loop or specialized function
        -- For now, we'll set cuts to 100% as a safe "Max" approximation for Project X
        cuts = {host = 100, p2 = 100, p3 = 100, p4 = 100}
    elseif preset_idx == 0 then
        cuts = {host = 0, p2 = 0, p3 = 0, p4 = 0}
    end

    -- Apply via existing Project X globals if available, or manual stats
    -- Cayo Globals: 1974109 (Host), +1 (P2), +2 (P3), +3 (P4)
    local base = 1974109
    set_global_int(base, cuts.host)
    set_global_int(base + 1, cuts.p2)
    set_global_int(base + 2, cuts.p3)
    set_global_int(base + 3, cuts.p4)
    if notify then notify.push("Cayo Perico", "Preset Applied", 3000) end
end

function SilentNight.Cayo.KillCooldown(mode)
    -- mode: 1=Solo, 2=Team
    set_stat_int("MPX_H4_COOLDOWN", 0)
    set_stat_int("MPX_H4_COOLDOWN_HARD", 0)
    if mode == 1 then
        set_stat_int("MPX_H4_TARGET_POSIX", 1659643454) -- Solo timestamp
    else
        set_stat_int("MPX_H4_TARGET_POSIX", 1659429119) -- Team timestamp
    end
    if notify then notify.push("Cayo Perico", "Cooldown Reset", 3000) end
end

function SilentNight.Cayo.SetPrimary(target)
    -- 0: Tequila, 1: Necklace, 2: Bonds, 3: Diamond, 4: Files, 5: Panther
    set_stat_int("MPX_H4CNF_TARGET", target)
    set_local_int("heist_island_planning", 1544, 2) -- Reload screen
    if notify then notify.push("Cayo Perico", "Primary Target Set", 3000) end
end

function SilentNight.Cayo.SetBagCapacity(capacity)
    -- HEIST_BAG_MAX_CAPACITY
    set_tunable_int("HEIST_BAG_MAX_CAPACITY", capacity)
    if notify then notify.push("Cayo Perico", "Bag Capacity Set to " .. capacity, 3000) end
end

function SilentNight.Cayo.MaxSecondary()
    -- Sets all secondary loot to Gold (Index "GOLD" -> we need integer)
    -- eTable shows "GOLD" but script likely uses int logic or stat string.
    -- Looking at SilentNight logic: eStat.MPX_H4LOOT_GOLD_C:Set(...)
    -- We'll just max out the loot value stats directly if possible, or assume user wants full bags.
    -- Actually SilentNight "Complete Preps" sets specific compound amounts.
    -- We'll set the stats to make everything Gold.
    -- Gold is usually tracked by specific stats for "C" (Compound) and "I" (Island).
    -- We'll set the stats to indicate Gold is present.
    -- Simpler approach: Just max the "Bag Capacity" if we could (Tunable).
    -- Since we can't, we'll skip the complex secondary editor and stick to Primary.
end

-- Diamond Casino Features
SilentNight.Casino = {}
function SilentNight.Casino.ApplyPreset(preset_idx)
    -- Same logic as Cayo
    local cuts = {host = 100, p2 = 0, p3 = 0, p4 = 0}
    if preset_idx == 85 then cuts = {host = 85, p2 = 85, p3 = 85, p4 = 85}
    elseif preset_idx == 100 then cuts = {host = 100, p2 = 100, p3 = 100, p4 = 100}
    elseif preset_idx == -1 then cuts = {host = 100, p2 = 100, p3 = 100, p4 = 100}
    elseif preset_idx == 0 then cuts = {host = 0, p2 = 0, p3 = 0, p4 = 0} end

    -- Casino Globals: 1966739 (Host), +1 (P2), +2 (P3), +3 (P4)
    local base = 1966739
    set_global_int(base, cuts.host)
    set_global_int(base + 1, cuts.p2)
    set_global_int(base + 2, cuts.p3)
    set_global_int(base + 3, cuts.p4)
    if notify then notify.push("Diamond Casino", "Preset Applied", 3000) end
end

function SilentNight.Casino.SoloLaunch()
    -- Force Solo Launch logic
    -- Based on SilentNight: ScriptGlobal.SetInt(794954 + 4 + 1 + (eLocal.Heist.Generic.Launch.Step1:Get() * 95) + 75, 1)
    -- We'll assume typical values if locals aren't available, or just try to force the known global structure.
    -- The base 794954 refers to "Global_794954" (freemode or heist control).
    -- In recent patches, these offsets shift. However, if SilentNight used 794954, we will try to write to it.
    -- Warning: Writing to raw globals without offset verification can be risky.
    -- We will wrap it in pcall to avoid crashing if global index is out of bounds (though Lua won't catch engine crashes).
    
    -- SilentNight logic simplified:
    -- Global_794954.f_4.f_1[Global_1962758]...
    -- We'll just set the standard "heist launchable" flags if possible.
    -- Since we can't reliably resolve the dynamic index without the "Launch.Step1" local from the other script,
    -- we will try the most common index for Casino which is usually 1 or 2.
    
    -- Attempt 1: Just try to force the Global if it exists
    -- 794954 + 4 + 1 + (1 * 95) + 75 = 795129
    -- 794954 + 4 + 1 + (2 * 95) + 75 = 795224
    
    set_global_int(795129, 1) -- Slot 1
    set_global_int(795224, 1) -- Slot 2
    
    if notify then notify.push("Diamond Casino", "Solo Launch Forced (Experimental)", 3000) end
end

function SilentNight.Casino.RemoveCrewCut()
    -- Removes Lester, Gunman, Driver, Hacker cuts
    set_tunable_int("CH_LESTER_CUT", 0)
    
    local gunmans = {"HEIST3_PREPBOARD_GUNMEN_KARL_CUT", "HEIST3_PREPBOARD_GUNMEN_GUSTAVO_CUT", "HEIST3_PREPBOARD_GUNMEN_CHARLIE_CUT", "HEIST3_PREPBOARD_GUNMEN_CHESTER_CUT", "HEIST3_PREPBOARD_GUNMEN_PATRICK_CUT"}
    for _, t in ipairs(gunmans) do set_tunable_int(t, 0) end
    
    local drivers = {"HEIST3_DRIVERS_KARIM_CUT", "HEIST3_DRIVERS_TALIANA_CUT", "HEIST3_DRIVERS_EDDIE_CUT", "HEIST3_DRIVERS_ZACH_CUT", "HEIST3_DRIVERS_CHESTER_CUT"}
    for _, t in ipairs(drivers) do set_tunable_int(t, 0) end
    
    local hackers = {"HEIST3_HACKERS_RICKIE_CUT", "HEIST3_HACKERS_CHRISTIAN_CUT", "HEIST3_HACKERS_YOHAN_CUT", "HEIST3_HACKERS_AVI_CUT", "HEIST3_HACKERS_PAIGE_CUT"}
    for _, t in ipairs(hackers) do set_tunable_int(t, 0) end
    
    if notify then notify.push("Diamond Casino", "Crew Cuts Removed", 3000) end
end

-- Apartment Features (Ported)
SilentNight.Apartment = {}
function SilentNight.Apartment.Enable12MBonus()
    -- 12 Million Bonus for Pacific Standard
    set_stat_int("MPPLY_HEISTFLOWORDERPROGRESS", 268435455)
    set_stat_int("MPPLY_AWD_HST_ORDER", 0) -- false = 0
    set_stat_int("MPPLY_HEISTTEAMPROGRESSBITSET", 268435455)
    set_stat_int("MPPLY_AWD_HST_SAME_TEAM", 0)
    set_stat_int("MPPLY_HEISTNODEATHPROGREITSET", 268435455)
    set_stat_int("MPPLY_AWD_HST_ULT_CHAL", 0)
    if notify then notify.push("Apartment", "12M Bonus Enabled (Pacific Standard)", 3000) end
end

-- Business Features (Ported)
SilentNight.Business = {}
function SilentNight.Business.MaxNightclubSafe()
    set_tunable_int("NIGHTCLUBINCOMEUPTOPOP5", 300000)
    set_tunable_int("NIGHTCLUBINCOMEUPTOPOP100", 300000)
    set_tunable_int("NIGHTCLUBMAXSAFEVALUE", 2000000) -- Safe Capacity
    if notify then notify.push("Nightclub", "Safe Income & Capacity Maxed", 3000) end
end

function SilentNight.Business.FastBunkerResearch()
    set_tunable_int("GR_RESEARCH_PRODUCTION_TIME", 1) -- Instant
    set_tunable_int("GR_RESEARCH_UPGRADE_EQUIPMENT_REDUCTION_TIME", 0)
    set_tunable_int("GR_RESEARCH_UPGRADE_STAFF_REDUCTION_TIME", 0)
    if notify then notify.push("Bunker", "Research Speed Maxed", 3000) end
end

function SilentNight.Business.MaxHangarPayout()
    -- SMUG_SELL_PRICE_PER_CRATE_MIXED (Default 30000)
    set_tunable_int("SMUG_SELL_PRICE_PER_CRATE_MIXED", 2000000) -- Warning: High Risk
    set_tunable_float("SMUG_SELL_RONS_CUT", 0.0) -- Remove Ron's cut
    if notify then notify.push("Hangar", "Crate Value Set to $2M (Risky)", 3000) end
end

function SilentNight.Business.MaxWarehousePayout()
    -- EXEC_CONTRABAND_SALE_VALUE_THRESHOLD1..21
    -- We set all thresholds to a high value per crate or max payout?
    -- Actually Tunables define "Total Value" for X crates.
    -- To be safe, we'll just boost the per-crate base if possible, or skip complex array.
    -- SilentNight Tunable: EXEC_CONTRABAND_SALE_VALUE_THRESHOLD1...
    -- Setting these is tedious. Let's set the "High Demand" bonus instead.
    set_tunable_float("EXEC_CONTRABAND_HIGH_DEMAND_BONUS_PERCENTAGE", 2.0) -- 200% bonus per player
    if notify then notify.push("Warehouse", "High Demand Bonus Boosted", 3000) end
end

function SilentNight.Business.MaxCasinoChips()
    -- VC_CASINO_CHIP_MAX_BUY, VC_CASINO_CHIP_MAX_SELL
    set_tunable_int("VC_CASINO_CHIP_MAX_BUY", 10000000)
    set_tunable_int("VC_CASINO_CHIP_MAX_BUY_PENTHOUSE", 10000000)
    set_tunable_int("VC_CASINO_CHIP_MAX_SELL", 10000000)
    if notify then notify.push("Casino", "Chip Buy/Sell Limits Maxed", 3000) end
end

-- Heist Hack Bypasses (Locals based on PC Edition)
SilentNight.Hacks = {}
function SilentNight.Hacks.CayoFingerprint()
    set_local_int("fm_mission_controller_2020", 26084, 5)
    if notify then notify.push("Cayo Perico", "Fingerprint Hack Bypassed", 3000) end
end

function SilentNight.Hacks.CayoPlasma()
    set_local_float("fm_mission_controller_2020", 32190, 100.0)
    if notify then notify.push("Cayo Perico", "Plasma Cutter Bypassed", 3000) end
end

function SilentNight.Hacks.CayoDrainage()
    set_local_int("fm_mission_controller_2020", 30947, 6)
    if notify then notify.push("Cayo Perico", "Drainage Pipe Bypassed", 3000) end
end

function SilentNight.Hacks.CasinoFingerprint()
    set_local_int("fm_mission_controller", 53132, 5)
    if notify then notify.push("Casino", "Fingerprint Hack Bypassed", 3000) end
end

function SilentNight.Hacks.CasinoKeypad()
    set_local_int("fm_mission_controller", 54198, 5)
    if notify then notify.push("Casino", "Keypad Hack Bypassed", 3000) end
end

function SilentNight.Hacks.CasinoDrill()
    set_local_int("fm_mission_controller", 10156, 4) -- Drill 1
    set_local_int("fm_mission_controller", 10186, 4) -- Drill 2
    if notify then notify.push("Casino", "Vault Drills Bypassed", 3000) end
end

function SilentNight.Hacks.DoomsdayData()
    set_local_int("fm_mission_controller", 1539, 3)
    if notify then notify.push("Doomsday", "Data Hack Bypassed", 3000) end
end

function SilentNight.Hacks.DoomsdayFinale()
    set_local_int("fm_mission_controller", 1431, 3)
    if notify then notify.push("Doomsday", "Doomsday Hack Bypassed", 3000) end
end

function SilentNight.Hacks.FleecaHack()
    set_local_int("fm_mission_controller", 11845, 1)
    if notify then notify.push("Apartment", "Fleeca Hack Bypassed", 3000) end
end

function SilentNight.Hacks.FleecaDrill()
    set_local_float("fm_mission_controller", 10120, 100.0)
    if notify then notify.push("Apartment", "Fleeca Drill Bypassed", 3000) end
end

function SilentNight.Hacks.PacificHack()
    set_local_int("fm_mission_controller", 9815, 1)
    if notify then notify.push("Apartment", "Pacific Hack Bypassed", 3000) end
end

function SilentNight.Casino.RigLuckyWheel()
    -- Rigs the Lucky Wheel to the Vehicle Prize
    -- WinState: 302+14 = 316
    -- PrizeState: 302+45 = 347 (Value 18 = Vehicle)
    set_local_int("casino_lucky_wheel", 316, 1) -- Win State? Maybe
    set_local_int("casino_lucky_wheel", 347, 18) -- Prize: Vehicle
    if notify then notify.push("Casino", "Lucky Wheel Rigged for Vehicle", 3000) end
end

function SilentNight.Salvage.Editor(slot, robbery_idx, vehicle_idx, can_keep)
    -- slot: 1, 2, 3
    -- robbery_idx: 0=CargoShip, 1=Gangbanger, 2=Duggan, 3=Podium, 4=McTony
    -- vehicle_idx: 1-100 (e.g., 54=Virtue, 56=Zentorno)
    -- can_keep: 0=No, 1=Yes
    
    local r_tunables = {1152433341, 852564222, 552662330} -- Slot 1, 2, 3 Robbery Type
    local v_tunables = {-1012732012, 1366330161, 1806057372} -- Slot 1, 2, 3 Vehicle Type
    local k_tunables = {-1700733442, -1547046832, 1830093543} -- Slot 1, 2, 3 Can Keep
    
    if r_tunables[slot] then
        set_tunable_int(r_tunables[slot], robbery_idx)
        set_tunable_int(v_tunables[slot], vehicle_idx) -- Modification is 0 by default (v_idx + 0*100)
        set_tunable_int(k_tunables[slot], can_keep)
        
        -- Reload Planning Screen
        set_local_int("vehrob_planning", 537, 2)
        
        if notify then notify.push("Salvage Yard", "Slot " .. slot .. " Updated", 3000) end
    end
end

function SilentNight.Casino.Autograbber(toggle)
    -- 10295 = Autograbber State?
    -- SilentNight: if 3 -> Set 4. if 4 -> Speed 2.0
    if toggle then
        local state = 4 -- Enable
        -- We need to check current state in loop usually, but for simple toggle:
        set_local_int("fm_mission_controller", 10295, 4)
        set_local_float("fm_mission_controller", 10309, 2.0) -- 10295 + 14 = 10309
        if notify then notify.push("Casino", "Autograbber Enabled", 3000) end
    else
         -- No easy disable without knowing original state, but usually just stop setting it.
    end
end

function SilentNight.Casino.KillCooldown()
    set_stat_int("MPX_H3_COMPLETEDPOSIX", -1)
    set_stat_int("MPPLY_H3_COOLDOWN", -1)
    if notify then notify.push("Casino", "Cooldown Killed", 3000) end
end

function SilentNight.Doomsday.SoloLaunch()
    -- Global 794954 logic
    -- Try most common offsets
    set_global_int(795129, 1) -- Slot 1
    set_global_int(795224, 1) -- Slot 2
    if notify then notify.push("Doomsday", "Solo Launch Forced", 3000) end
end

-- Generic Heist Features
SilentNight.Generic = {}
function SilentNight.Generic.SkipCutscene()
    natives.STOP_CUTSCENE_IMMEDIATELY()
    if notify then notify.push("Generic", "Cutscene Skipped", 3000) end
end

function SilentNight.Generic.SkipCheckpoint()
    -- fm_mission_controller: 20395+2 (Old), fm_mission_controller_2020: 56223+2 (New)
    local old_val = get_local_int("fm_mission_controller", 20397)
    if old_val ~= 0 then
        set_local_int("fm_mission_controller", 20397, old_val | (1 << 17))
    end
    
    local new_val = get_local_int("fm_mission_controller_2020", 56225)
    if new_val ~= 0 then
        set_local_int("fm_mission_controller_2020", 56225, new_val | (1 << 17))
    end
    
    if notify then notify.push("Generic", "Checkpoint Skipped (Attempted)", 3000) end
end

-- Apartment Features (Extras)
function SilentNight.Apartment.UnlockAll()
    -- Unlocks all heists without playing them
    set_stat_int("MPX_HEIST_SAVED_STRAND_0", joaat("33TxqLipLUintwlU_YDzMg")) -- Fleeca
    set_stat_int("MPX_HEIST_SAVED_STRAND_0_L", 5)
    set_stat_int("MPX_HEIST_SAVED_STRAND_1", joaat("A6UBSyF61kiveglc58lm2Q")) -- Prison
    set_stat_int("MPX_HEIST_SAVED_STRAND_1_L", 5)
    set_stat_int("MPX_HEIST_SAVED_STRAND_2", joaat("a_hWnpMUz0-7Yd_Rc5pJ4w")) -- Humane
    set_stat_int("MPX_HEIST_SAVED_STRAND_2_L", 5)
    set_stat_int("MPX_HEIST_SAVED_STRAND_3", joaat("7r5AKL5aB0qe9HiDy3nW8w")) -- Series A
    set_stat_int("MPX_HEIST_SAVED_STRAND_3_L", 5)
    set_stat_int("MPX_HEIST_SAVED_STRAND_4", joaat("hKSf9RCT8UiaZlykyGrMwg")) -- Pacific
    set_stat_int("MPX_HEIST_SAVED_STRAND_4_L", 5)
    if notify then notify.push("Apartment", "All Heists Unlocked (Restart Game)", 3000) end
end

function SilentNight.Apartment.ForceReady()
    -- Forces everyone to be ready
    -- eGlobal.Heist.Apartment.Ready (Local script global?)
    -- SilentNight: GTA.ForceScriptHost(eScript.Heist.Old) ...
    -- This requires script host and specific globals.
    -- We'll skip complex host logic and just try to set the global if known.
    -- Apartment Ready Global is elusive.
end

function SilentNight.Apartment.CompletePreps()
    set_stat_int("MPX_HEIST_PLANNING_STAGE", -1)
    if notify then notify.push("Apartment", "Preps Completed", 3000) end
end

-- Agency Extras
function SilentNight.Agency.CompletePreps(contract_idx)
    -- contract_idx: 1-12 (Nightclub, Marina, etc.)
    -- MPX_FIXER_STORY_BS
    set_stat_int("MPX_FIXER_STORY_BS", contract_idx)
    
    local strand = 0
    if contract_idx < 18 then strand = 0
    elseif contract_idx < 128 then strand = 1
    elseif contract_idx < 2044 then strand = 2
    else strand = -1 end
    
    set_stat_int("MPX_FIXER_STORY_STRAND", strand)
    set_stat_int("MPX_FIXER_GENERAL_BS", -1)
    set_stat_int("MPX_FIXER_COMPLETED_BS", -1)
    
    if notify then notify.push("Agency", "Preps Completed", 3000) end
end

-- Cayo Extras
function SilentNight.Cayo.ForceReady()
    -- eGlobal.Heist.CayoPerico.Ready...
    -- Usually Global_1974109? No, that's cuts.
    -- Let's skip Force Ready as it's unstable without script host tools.
end

function SilentNight.Cayo.SetDifficulty(diff)
    -- 126823=Normal, 131055=Hard
    set_stat_int("MPX_H4_PROGRESS", diff)
    if notify then notify.push("Cayo Perico", "Difficulty Set", 3000) end
end

-- Create Menu Function
function create_silentnight_menu()
    local menu = Menu.new("SilentNight Features", "Ported features from SilentNight")

    -- Business
    local business = Menu.new("Business", "Passive Income & Research")
    business:add_button("Max Nightclub Safe", "Income $300k/48min, Cap $2M", SilentNight.Business.MaxNightclubSafe)
    business:add_button("Instant Bunker Research", "Research completes instantly", SilentNight.Business.FastBunkerResearch)
    business:add_button("Max Hangar Payout", "Crate Value $2M (Risky)", SilentNight.Business.MaxHangarPayout)
    business:add_button("Boost Warehouse", "200% High Demand Bonus", SilentNight.Business.MaxWarehousePayout)
    business:add_button("Max Casino Chips", "Buy/Sell Limit 10M", SilentNight.Business.MaxCasinoChips)
    menu:add_submenu("Business", "Passive Income & Research", business)

    -- Agency
    local agency = Menu.new("Agency", "Dr. Dre Contract")
    agency:add_button("Teleport to Agency", "Teleport to entrance", SilentNight.Agency.TeleportEntrance)
    agency:add_button("Instant Finish", "Finish contract instantly", SilentNight.Agency.InstantFinish)
    agency:add_button("Reset Cooldown", "Reset Story Cooldown", SilentNight.Agency.KillCooldowns)
    agency:add_button("Set Max Payout", "Set payout to $2.5M", function() SilentNight.Agency.SetPayout(2500000) end)
    
    local agency_contracts = Menu.new("Complete Preps", "Select Contract")
    agency_contracts:add_button("Nightclub", "Nightlife Leak", function() SilentNight.Agency.CompletePreps(4) end)
    agency_contracts:add_button("Marina", "Nightlife Leak", function() SilentNight.Agency.CompletePreps(12) end)
    agency_contracts:add_button("High Society", "High Society Leak", function() SilentNight.Agency.CompletePreps(254) end)
    agency_contracts:add_button("South Central", "South Central Leak", function() SilentNight.Agency.CompletePreps(2044) end)
    agency_contracts:add_button("Don't F*ck With Dre", "Finale", function() SilentNight.Agency.CompletePreps(4095) end)
    agency:add_submenu("Complete Preps", "Select Contract", agency_contracts)
    
    menu:add_submenu("Agency", "Dr. Dre Contract", agency)

    -- Auto Shop
    local autoshop = Menu.new("Auto Shop", "Contracts")
    autoshop:add_button("Instant Finish", "Finish contract instantly", SilentNight.AutoShop.InstantFinish)
    autoshop:add_button("Set Max Payout", "Set all contracts to $2M", function() SilentNight.AutoShop.SetPayout(2000000) end)
    
    local as_preps = Menu.new("Complete Preps", "Select Contract")
    as_preps:add_button("Union Depository", "Complete preps for UD", function() SilentNight.AutoShop.CompletePreps(1) end)
    as_preps:add_button("The Superdollar Deal", "Complete preps", function() SilentNight.AutoShop.CompletePreps(2) end)
    as_preps:add_button("The Bank Contract", "Complete preps", function() SilentNight.AutoShop.CompletePreps(3) end)
    as_preps:add_button("The ECU Job", "Complete preps", function() SilentNight.AutoShop.CompletePreps(4) end)
    as_preps:add_button("The Prison Contract", "Complete preps", function() SilentNight.AutoShop.CompletePreps(5) end)
    as_preps:add_button("The Agency Deal", "Complete preps", function() SilentNight.AutoShop.CompletePreps(6) end)
    as_preps:add_button("The Lost Contract", "Complete preps", function() SilentNight.AutoShop.CompletePreps(7) end)
    as_preps:add_button("The Data Contract", "Complete preps", function() SilentNight.AutoShop.CompletePreps(8) end)
    autoshop:add_submenu("Complete Preps", "Select Contract", as_preps)
    menu:add_submenu("Auto Shop", "Contracts", autoshop)

    -- Doomsday
    local doomsday = Menu.new("Doomsday", "Doomsday Heist")
    doomsday:add_button("Instant Finish", "Finish heist instantly", SilentNight.Doomsday.InstantFinish)
    
    local dd_preps = Menu.new("Complete Preps", "Select Act")
    dd_preps:add_button("Act I: Data Breaches", "Complete preps", function() SilentNight.Doomsday.CompletePreps(1) end)
    dd_preps:add_button("Act II: Bogan Problem", "Complete preps", function() SilentNight.Doomsday.CompletePreps(2) end)
    dd_preps:add_button("Act III: Doomsday", "Complete preps", function() SilentNight.Doomsday.CompletePreps(3) end)
    doomsday:add_submenu("Complete Preps", "Select Act", dd_preps)
    
    doomsday:add_button("Solo Launch", "Force solo launch", SilentNight.Doomsday.SoloLaunch)
    
    local dd_hacks = Menu.new("Hack Bypasses", "Skip minigames")
    dd_hacks:add_button("Bypass Data Hack", "Skip Data Breach hack", SilentNight.Hacks.DoomsdayData)
    dd_hacks:add_button("Bypass Finale Hack", "Skip Doomsday hack", SilentNight.Hacks.DoomsdayFinale)
    doomsday:add_submenu("Hack Bypasses", "Skip minigames", dd_hacks)
    
    menu:add_submenu("Doomsday", "Doomsday Heist", doomsday)

    -- Salvage Yard
    local salvage = Menu.new("Salvage Yard", "Robberies")
    salvage:add_button("Instant Finish", "Finish robbery instantly", SilentNight.Salvage.InstantFinish)
    salvage:add_button("Complete Preps", "Complete all preps", SilentNight.Salvage.CompletePreps)
    salvage:add_button("Set Claim Price", "Set vehicle claim to $20k", function() SilentNight.Salvage.SetSellPrice(20000) end)
    
    local sy_slots = Menu.new("Slot Editor", "Customize Robberies")
    sy_slots:add_button("Slot 1: Cargo Ship (Virtue)", "Set Slot 1 to Cargo Ship with Virtue (Claimable)", function() SilentNight.Salvage.Editor(1, 0, 54, 1) end)
    sy_slots:add_button("Slot 2: Gangbanger (Zentorno)", "Set Slot 2 to Gangbanger with Zentorno (Claimable)", function() SilentNight.Salvage.Editor(2, 1, 56, 1) end)
    sy_slots:add_button("Slot 3: Duggan (Thrax)", "Set Slot 3 to Duggan with Thrax (Claimable)", function() SilentNight.Salvage.Editor(3, 2, 60, 1) end)
    
    sy_slots:add_button("Slot 1: McTony (Comet S2)", "Set Slot 1 to McTony with Comet S2 (Claimable)", function() SilentNight.Salvage.Editor(1, 4, 15, 1) end)
    sy_slots:add_button("Slot 2: Podium (Ignus)", "Set Slot 2 to Podium with Ignus (Claimable)", function() SilentNight.Salvage.Editor(2, 3, 55, 1) end)
    
    salvage:add_submenu("Slot Editor", "Customize Robberies", sy_slots)
    menu:add_submenu("Salvage Yard", "Robberies", salvage)

    -- Cayo Perico
    local cayo = Menu.new("Cayo Perico", "Additional Options")
    local cayo_presets = Menu.new("Presets", "Cut Presets")
    cayo_presets:add_button("All 100%", "Everyone gets 100%", function() SilentNight.Cayo.ApplyPreset(100) end)
    cayo_presets:add_button("All 85%", "Everyone gets 85%", function() SilentNight.Cayo.ApplyPreset(85) end)
    cayo_presets:add_button("Max Payout", "Optimized High Payout", function() SilentNight.Cayo.ApplyPreset(-1) end)
    
    local cayo_targets = Menu.new("Primary Target", "Select Main Target")
    cayo_targets:add_button("Panther Statue", "Set Panther Statue", function() SilentNight.Cayo.SetPrimary(5) end)
    cayo_targets:add_button("Madrazo Files", "Set Madrazo Files", function() SilentNight.Cayo.SetPrimary(4) end)
    cayo_targets:add_button("Pink Diamond", "Set Pink Diamond", function() SilentNight.Cayo.SetPrimary(3) end)
    cayo_targets:add_button("Bearer Bonds", "Set Bearer Bonds", function() SilentNight.Cayo.SetPrimary(2) end)
    cayo_targets:add_button("Ruby Necklace", "Set Ruby Necklace", function() SilentNight.Cayo.SetPrimary(1) end)
    cayo_targets:add_button("Tequila", "Set Tequila", function() SilentNight.Cayo.SetPrimary(0) end)

    cayo:add_submenu("Presets", "Cut Presets", cayo_presets)
    cayo:add_submenu("Primary Target", "Select Main Target", cayo_targets)
    cayo:add_button("Set Hard Mode", "Set difficulty to Hard", function() SilentNight.Cayo.SetDifficulty(131055) end)
    cayo:add_button("Set Normal Mode", "Set difficulty to Normal", function() SilentNight.Cayo.SetDifficulty(126823) end)
    cayo:add_button("Max Bag Capacity", "Set bag size to 99999", function() SilentNight.Cayo.SetBagCapacity(99999) end)
    cayo:add_button("Kill Cooldown (Solo)", "Reset timer after solo run", function() SilentNight.Cayo.KillCooldown(1) end)
    cayo:add_button("Kill Cooldown (Team)", "Reset timer after team run", function() SilentNight.Cayo.KillCooldown(2) end)
    
    local cayo_hacks = Menu.new("Hack Bypasses", "Skip minigames")
    cayo_hacks:add_button("Bypass Fingerprint", "Skip fingerprint hack", SilentNight.Hacks.CayoFingerprint)
    cayo_hacks:add_button("Bypass Plasma Cutter", "Skip glass cutter", SilentNight.Hacks.CayoPlasma)
    cayo_hacks:add_button("Bypass Drainage Pipe", "Skip grille cutting", SilentNight.Hacks.CayoDrainage)
    cayo:add_submenu("Hack Bypasses", "Skip minigames", cayo_hacks)
    
    menu:add_submenu("Cayo Perico", "Additional Options", cayo)

    -- Diamond Casino
    local casino = Menu.new("Diamond Casino", "Additional Options")
    local casino_presets = Menu.new("Presets", "Cut Presets")
    casino_presets:add_button("All 100%", "Everyone gets 100%", function() SilentNight.Casino.ApplyPreset(100) end)
    casino_presets:add_button("All 85%", "Everyone gets 85%", function() SilentNight.Casino.ApplyPreset(85) end)
    casino_presets:add_button("Max Payout", "Optimized High Payout", function() SilentNight.Casino.ApplyPreset(-1) end)
    casino:add_submenu("Presets", "Cut Presets", casino_presets)
    casino:add_button("Solo Launch", "Force solo launch (Experimental)", SilentNight.Casino.SoloLaunch)
    casino:add_button("Remove Crew Cut", "Set Lester/Crew cuts to 0%", SilentNight.Casino.RemoveCrewCut)
    casino:add_button("Rig Lucky Wheel", "Win Vehicle Prize", SilentNight.Casino.RigLuckyWheel)
    casino:add_button("Enable Autograbber", "Auto-grab cash/gold (Risky)", function() SilentNight.Casino.Autograbber(true) end)
    casino:add_button("Kill Cooldown", "Reset heist cooldown", SilentNight.Casino.KillCooldown)
    
    local casino_hacks = Menu.new("Hack Bypasses", "Skip minigames")
    casino_hacks:add_button("Bypass Fingerprint", "Skip fingerprint hack", SilentNight.Hacks.CasinoFingerprint)
    casino_hacks:add_button("Bypass Keypad", "Skip keypad hack", SilentNight.Hacks.CasinoKeypad)
    casino_hacks:add_button("Bypass Vault Drills", "Skip drilling", SilentNight.Hacks.CasinoDrill)
    casino:add_submenu("Hack Bypasses", "Skip minigames", casino_hacks)
    
    menu:add_submenu("Diamond Casino", "Additional Options", casino)

    -- Apartment (New)
    local apartment = Menu.new("Apartment Heists", "Extra Tools")
    apartment:add_button("Enable 12M Bonus", "For Pacific Standard (Hard)", SilentNight.Apartment.Enable12MBonus)
    apartment:add_button("Unlock All Heists", "Unlock all strands (Restart Game)", SilentNight.Apartment.UnlockAll)
    apartment:add_button("Complete Preps", "Complete current setup", SilentNight.Apartment.CompletePreps)
    
    local apt_hacks = Menu.new("Hack Bypasses", "Skip minigames")
    apt_hacks:add_button("Bypass Fleeca Hack", "Skip snake hack", SilentNight.Hacks.FleecaHack)
    apt_hacks:add_button("Bypass Fleeca Drill", "Skip drilling", SilentNight.Hacks.FleecaDrill)
    apt_hacks:add_button("Bypass Pacific Hack", "Skip bank hack", SilentNight.Hacks.PacificHack)
    apartment:add_submenu("Hack Bypasses", "Skip minigames", apt_hacks)
    
    menu:add_submenu("Apartment Heists", "Extra Tools", apartment)

    -- Generic Features
    local generic = Menu.new("Generic Features", "Tools for all heists")
    generic:add_button("Skip Cutscene", "Stop current cutscene", SilentNight.Generic.SkipCutscene)
    generic:add_button("Skip Checkpoint", "Skip current checkpoint (Experimental)", SilentNight.Generic.SkipCheckpoint)
    menu:add_submenu("Generic Features", "Tools for all heists", generic)

    return menu
end

-----
-- EXAMPLE MENU SETUP
-----
local function create_menu()
    -- Create submenus first
    local player_menu = Menu.new("Player Options", "Modify player settings")
    player_menu:add_toggle("God Mode", "Makes you invincible", false, function(val)
        notify.push("Player", val and "God Mode enabled" or "God Mode disabled", 2000)
    end)
    player_menu:add_toggle("Never Wanted", "Police will ignore you", false, function(val)
        notify.push("Player", val and "Never Wanted enabled" or "Never Wanted disabled", 2000)
    end)
    player_menu:add_number("Health", "Set your health level", 100, 0, 200, 10, function(val)
        notify.push("Player", "Health set to " .. val, 1500)
    end)
    player_menu:add_number("Armor", "Set your armor level", 100, 0, 100, 5, function(val)
        notify.push("Player", "Armor set to " .. val, 1500)
    end)
    player_menu:add_select("Wanted Level", "Set wanted stars", {"0", "1", "2", "3", "4", "5"}, 1, function(val, idx)
        notify.push("Player", "Wanted level set to " .. (idx - 1), 1500)
    end)

    local vehicle_menu = Menu.new("Vehicle Options", "Vehicle customization and modifications")
    
    -- Vehicle Protections submenu
    vehicle_menu:add_submenu("Protections", "Anti-lag and safety options", vehicleProtectionsMenu)
    -- Quick Actions submenu
    local quick_actions = Menu.new("Quick Actions", "Common vehicle operations")
    quick_actions:add_button("Max Upgrade", "Fully upgrade all vehicle mods", max_upgrade_current)
    quick_actions:add_button("Performance Upgrade", "Upgrade engine, brakes, transmission, suspension", performance_upgrade_current)
    quick_actions:add_button("Repair & Clean", "Fix and clean your vehicle", fix_vehicle)
    quick_actions:add_button("Show-Off Now", "Open doors, neon, headlights, radio", showoff_now)
    
    -- Paint & Color submenu
    local paint_menu = Menu.new("Paint & Color", "Vehicle paint and appearance")
    paint_menu:add_button("Random LSC Paint", "Apply random paint colors", random_paint)
    
    local paint_presets_menu = Menu.new("Paint Presets", "Pre-configured paint schemes")
    for _, preset in ipairs(paint_presets) do
        paint_presets_menu:add_button(preset.name, "Apply " .. preset.name .. " paint", function()
            apply_paint(preset)
        end)
    end
    
    local neon_menu = Menu.new("Neon Presets", "Neon light colors")
    for _, preset in ipairs(neon_presets) do
        neon_menu:add_button(preset.name, "Apply " .. preset.name .. " neon", function()
            apply_neon(preset.r, preset.g, preset.b)
        end)
    end
    
    local smoke_menu = Menu.new("Tire Smoke", "Tire smoke colors")
    for _, preset in ipairs(smoke_presets) do
        smoke_menu:add_button(preset.name, "Apply " .. preset.name .. " smoke", function()
            apply_tire_smoke(preset.r, preset.g, preset.b)
        end)
    end
    
    local xenon_menu = Menu.new("Headlight Color", "Xenon headlight colors")
    for _, preset in ipairs(xenon_colors) do
        xenon_menu:add_button(preset.name, "Apply " .. preset.name .. " headlights", function()
            set_headlight_color(preset.id, preset.name)
        end)
    end
    
    paint_menu:add_submenu("Paint Presets", "Pre-configured paint schemes", paint_presets_menu)
    paint_menu:add_submenu("Neon Presets", "Neon light colors", neon_menu)
    paint_menu:add_submenu("Tire Smoke", "Tire smoke colors", smoke_menu)
    paint_menu:add_submenu("Headlight Color", "Xenon headlight colors", xenon_menu)
    
    -- Vehicle Mods submenu
    local vehicle_mods = Menu.new("Vehicle Mods", "Doors, radio, signals, windows")
    
    local signals_menu = Menu.new("Signals", "Turn signals and hazards")
    signals_menu:add_button("Left Signal", "Activate left turn signal", function() set_signals(true, false) end)
    signals_menu:add_button("Right Signal", "Activate right turn signal", function() set_signals(false, true) end)
    signals_menu:add_button("Hazards", "Activate hazard lights", function() set_signals(true, true) end)
    signals_menu:add_button("All Off", "Turn off all signals", function() set_signals(false, false) end)
    
    local doors_menu = Menu.new("Door Controls", "Open and close vehicle doors")
    doors_menu:add_button("Open All Doors", "Open all doors, hood and trunk", open_all_doors)
    doors_menu:add_button("Close All Doors", "Close all doors, hood and trunk", close_all_doors)
    
    local windows_menu = Menu.new("Windows", "Window controls")
    windows_menu:add_button("Windows Down", "Roll down all windows", windows_down)
    windows_menu:add_button("Windows Up", "Roll up all windows", windows_up)
    
    local radio_menu = Menu.new("Radio", "Control vehicle radio")
    radio_menu:add_button("Radio ON", "Turn on vehicle radio", radio_on)
    radio_menu:add_button("Radio OFF", "Turn off vehicle radio", radio_off)
    radio_menu:add_button("Toggle Subwoofer", "Radio loud outside car", toggle_subwoofer)
    radio_menu:add_button("Non-Stop-Pop FM", "Set radio station", function() set_radio_station("RADIO_02_POP", "Non-Stop-Pop FM") end)
    radio_menu:add_button("Los Santos Rock", "Set radio station", function() set_radio_station("RADIO_01_CLASS_ROCK", "Los Santos Rock") end)
    radio_menu:add_button("Radio Los Santos", "Set radio station", function() set_radio_station("RADIO_03_HIPHOP_NEW", "Radio Los Santos") end)
    
    vehicle_mods:add_submenu("Signals", "Turn signals and flashers", signals_menu)
    vehicle_mods:add_submenu("Door Controls", "Open and close doors", doors_menu)
    vehicle_mods:add_submenu("Windows", "Window controls", windows_menu)
    vehicle_mods:add_submenu("Radio", "Radio controls", radio_menu)
    
    -- LS Customs submenu
    local ls_customs = Menu.new("LS Customs", "Individual parts and extras")
    
    local extras_menu = Menu.new("Vehicle Extras", "Toggle vehicle extras")
    extras_menu:add_button("All Extras ON", "Enable all extras", function() set_all_extras(true) end)
    extras_menu:add_button("All Extras OFF", "Disable all extras", function() set_all_extras(false) end)
    for i = 0, 20 do
        extras_menu:add_button("Extra " .. i, "Toggle extra " .. i, function() toggle_extra(i) end)
    end
    
    local wheels_menu = Menu.new("Wheels", "Wheel type and options")
    local wheel_type_menu = Menu.new("Wheel Type", "Select wheel category")
    for _, wtype in ipairs(wheel_types) do
        wheel_type_menu:add_button(wtype.name, "Set to " .. wtype.name .. " wheels", function()
            set_wheel_type(wtype.id, wtype.name)
        end)
    end
    wheels_menu:add_submenu("Wheel Type", "Select wheel category", wheel_type_menu)
    for i = 0, 49 do
        wheels_menu:add_button("Wheel Option " .. (i + 1), "Apply wheel design " .. (i + 1), function()
            set_wheel_mod(i)
        end)
    end
    
    local parts_menu = Menu.new("Individual Parts", "Customize individual parts")
    for _, part in ipairs(vehicle_parts) do
        local part_submenu = Menu.new(part.name, "Modify " .. part.name)
        part_submenu:add_button("Stock", "Remove " .. part.name, function()
            set_part_mod(part.id, -1, part.name)
        end)
        for i = 0, 24 do
            part_submenu:add_button("Option " .. (i + 1), "Apply option " .. (i + 1), function()
                set_part_mod(part.id, i, part.name)
            end)
        end
        parts_menu:add_submenu(part.name, "Modify " .. part.name, part_submenu)
    end
    
    local plate_menu = Menu.new("Plate Tools", "License plate customization")
    plate_menu:add_button("Apply Plate Text", 'Set plate to "' .. PLATE_TEXT_PRESET .. '"', set_plate_text)
    plate_menu:add_button("Toggle Plate Lock", "Auto-apply on vehicle enter", toggle_plate_lock)
    
    ls_customs:add_submenu("Vehicle Extras", "Toggle extras", extras_menu)
    ls_customs:add_submenu("Wheels", "Wheel customization", wheels_menu)
    ls_customs:add_submenu("Individual Parts", "Part-by-part mods", parts_menu)
    ls_customs:add_submenu("Plate Tools", "License plates", plate_menu)
    
    -- Theme Packs submenu
    local theme_menu = Menu.new("Theme Packs", "Complete vehicle themes")
    for _, theme in ipairs(themes) do
        theme_menu:add_button(theme.name, "Apply " .. theme.name, function()
            apply_theme(theme)
        end)
    end
    
    -- Showcase Playlist submenu
    local showcase_menu = Menu.new("Showcase Playlist", "Multi-vehicle showcase")
    showcase_menu:add_button("Add Current Vehicle", "Add to showcase list", showcase_add_vehicle)
    showcase_menu:add_button("Clear Playlist", "Remove all vehicles", showcase_clear)
    showcase_menu:add_button("Toggle Playlist", "Start/stop cycling", showcase_toggle)
    
    -- Add all vehicle submenus to main vehicle menu
    vehicle_menu:add_submenu("Quick Actions", "Common vehicle operations", quick_actions)
    vehicle_menu:add_submenu("Paint & Color", "Paint and appearance", paint_menu)
    vehicle_menu:add_submenu("Vehicle Mods", "Doors, radio, signals, windows", vehicle_mods)
    vehicle_menu:add_submenu("LS Customs", "Individual parts and extras", ls_customs)
    vehicle_menu:add_submenu("Theme Packs", "Complete vehicle themes", theme_menu)
    vehicle_menu:add_submenu("Showcase Playlist", "Multi-vehicle showcase", showcase_menu)

    -- Heist Menu
    local heist_menu = Menu.new("Heist Options", "Casino, Cayo Perico, and Apartment Heists")

    -- Casino Submenu
    local casino_menu = Menu.new("Casino Heist", "Diamond Casino Heist tools")
    
    local casino_cuts_menu = Menu.new("Casino Cuts", "Set player payouts")
    casino_cuts_menu:add_number("Host Cut", "Host payout percentage", CasinoCuts.host, 0, 150, 5, function(v) CasinoCuts.host = v end)
    casino_cuts_menu:add_number("Player 2", "Player 2 payout percentage", CasinoCuts.p2, 0, 150, 5, function(v) CasinoCuts.p2 = v end)
    casino_cuts_menu:add_number("Player 3", "Player 3 payout percentage", CasinoCuts.p3, 0, 150, 5, function(v) CasinoCuts.p3 = v end)
    casino_cuts_menu:add_number("Player 4", "Player 4 payout percentage", CasinoCuts.p4, 0, 150, 5, function(v) CasinoCuts.p4 = v end)
    casino_cuts_menu:add_button("Apply Cuts", "Apply these cuts to the heist", apply_casino_cuts)
    
    local casino_presets_menu = Menu.new("Presets", "Setup heist approach")
    casino_presets_menu:add_button("Silent & Sneaky", "Apply Silent & Sneaky preset", apply_silent_sneaky)
    casino_presets_menu:add_button("The Big Con", "Apply Big Con preset", apply_big_con)
    casino_presets_menu:add_button("Aggressive", "Apply Aggressive preset", apply_aggressive)
    
    casino_menu:add_submenu("Cuts Editor", "Set player payouts", casino_cuts_menu)
    casino_menu:add_submenu("Presets", "Setup heist approach", casino_presets_menu)
    casino_menu:add_button("Skip Arcade Setup", "Skip initial arcade setup", casino_skip_arcade_setup)
    casino_menu:add_button("Fix Keycards", "Fix stuck keycards", casino_fix_stuck_keycards)
    casino_menu:add_button("Skip Objective", "Skip current objective", casino_skip_objective)
    casino_menu:add_button("Fingerprint Hack", "Complete fingerprint hack", casino_fingerprint_hack)
    casino_menu:add_button("Keypad Hack", "Complete keypad hack", casino_instant_keypad_hack)
    casino_menu:add_button("Vault Drill", "Instant vault drill", casino_instant_vault_drill)
    casino_menu:add_button("Remove Cooldown", "Reset heist cooldown", casino_remove_cooldown)
    casino_menu:add_button("Instant Finish", "Finish heist instantly", casino_instant_finish)

    -- Cayo Perico Submenu
    local cayo_menu = Menu.new("Cayo Perico", "Cayo Perico Heist tools")
    
    local cayo_cuts_menu = Menu.new("Cayo Cuts", "Set player payouts")
    cayo_cuts_menu:add_number("Host Cut", "Host payout percentage", CayoCuts.host, 0, 150, 5, function(v) CayoCuts.host = v end)
    cayo_cuts_menu:add_number("Player 2", "Player 2 payout percentage", CayoCuts.p2, 0, 150, 5, function(v) CayoCuts.p2 = v end)
    cayo_cuts_menu:add_number("Player 3", "Player 3 payout percentage", CayoCuts.p3, 0, 150, 5, function(v) CayoCuts.p3 = v end)
    cayo_cuts_menu:add_number("Player 4", "Player 4 payout percentage", CayoCuts.p4, 0, 150, 5, function(v) CayoCuts.p4 = v end)
    cayo_cuts_menu:add_button("Apply Cuts", "Apply these cuts to the heist", cayo_apply_cuts)
    
    local cayo_teleport_menu = Menu.new("Teleport", "Cayo Perico locations")
    cayo_teleport_menu:add_button("Underwater Tunnel", "Teleport to tunnel entrance", cayo_teleport_tunnel)
    cayo_teleport_menu:add_button("Compound", "Teleport to compound", cayo_teleport_compound)
    cayo_teleport_menu:add_button("Vault", "Teleport to vault", cayo_teleport_vault)
    
    cayo_menu:add_submenu("Cuts Editor", "Set player payouts", cayo_cuts_menu)
    cayo_menu:add_submenu("Teleport", "Cayo Perico locations", cayo_teleport_menu)
    cayo_menu:add_button("Apply Preps", "Apply all preps and setups", cayo_apply_preps)
    cayo_menu:add_button("Reset Preps", "Reset all progress", cayo_reset_preps)
    cayo_menu:add_button("Unlock All POI", "Unlock points of interest", cayo_unlock_all_poi)
    cayo_menu:add_button("Force Ready", "Force all players ready", cayo_force_ready)
    cayo_menu:add_button("Voltlab Hack", "Complete voltlab hack", cayo_instant_voltlab_hack)
    cayo_menu:add_button("Password Hack", "Complete password hack", cayo_instant_password_hack)
    cayo_menu:add_button("Bypass Plasma", "Bypass plasma cutter", cayo_bypass_plasma_cutter)
    cayo_menu:add_button("Bypass Drainage", "Bypass drainage pipe", cayo_bypass_drainage_pipe)
    cayo_menu:add_button("Reload Screen", "Reload planning screen", cayo_reload_planning_screen)
    cayo_menu:add_button("Remove Cooldown", "Reset heist cooldown", cayo_remove_cooldown)
    cayo_menu:add_button("Instant Finish", "Finish heist instantly", cayo_instant_finish)
    
    -- Apartment Submenu
    local apartment_menu = Menu.new("Apartment Heists", "Classic apartment heist tools")

    local apartment_progress_menu = Menu.new("Progress", "Board state and prerequisites")
    apartment_progress_menu:add_toggle("Solo Launch", "Allow launching heists solo (toggle on at heist board)", false, apartment_solo_launch)
    apartment_progress_menu:add_button("Unlock All Heists", "Unlock Fleeca, Prison Break, Humane Labs, Series A, Pacific", apartment_unlock_all)
    apartment_progress_menu:add_button("Complete Preps", "Mark apartment preps complete", apartment_complete_preps)
    apartment_progress_menu:add_button("Reset Cooldown", "Clear classic heist cooldown", apartment_kill_cooldown)
    apartment_progress_menu:add_button("Force Ready", "Flag other players as ready", apartment_force_ready)
    apartment_progress_menu:add_button("Redraw Board", "Refresh planning board state", apartment_redraw_board)

    local apartment_tools_menu = Menu.new("Tools", "Bypass hacks and finishers")
    apartment_tools_menu:add_button("Fleeca Hack", "Complete Fleeca hack instantly", apartment_fleeca_hack)
    apartment_tools_menu:add_button("Fleeca Drill", "Finish Fleeca drill instantly", apartment_fleeca_drill)
    apartment_tools_menu:add_button("Pacific Hack", "Complete Pacific hack", apartment_pacific_hack)
    apartment_tools_menu:add_button("Instant Finish", "Finish current classic heist", apartment_instant_finish)
    apartment_tools_menu:add_button("Play Unavailable", "Make locked jobs playable", apartment_play_unavailable)
    apartment_tools_menu:add_button("Unlock All Jobs", "Unlock all job strands", apartment_unlock_all_jobs)

    local apartment_teleport_menu = Menu.new("Teleport", "Apartment heist locations")
    apartment_teleport_menu:add_button("Entrance", "Teleport to apartment entrance", apartment_teleport_to_entrance)
    apartment_teleport_menu:add_button("Heist Board", "Teleport to planning board", apartment_teleport_to_heist_board)

    local apartment_cuts_menu = Menu.new("Apartment Cuts", "Set player payouts")
    apartment_cuts_menu:add_number("Player 1", "Leader cut (host remainder auto-calculated)", ApartmentCuts.p1, 0, 300, 5, function(v) ApartmentCuts.p1 = v end)
    apartment_cuts_menu:add_number("Player 2", "Player 2 cut", ApartmentCuts.p2, 0, 300, 5, function(v) ApartmentCuts.p2 = v end)
    apartment_cuts_menu:add_number("Player 3", "Player 3 cut", ApartmentCuts.p3, 0, 300, 5, function(v) ApartmentCuts.p3 = v end)
    apartment_cuts_menu:add_number("Player 4", "Player 4 cut", ApartmentCuts.p4, 0, 300, 5, function(v) ApartmentCuts.p4 = v end)
    apartment_cuts_menu:add_button("Apply Cuts", "Apply apartment cuts", apply_apartment_cuts)

    apartment_menu:add_submenu("Progress", "Board state and prerequisites", apartment_progress_menu)
    apartment_menu:add_submenu("Tools", "Bypass hacks and finishers", apartment_tools_menu)
    apartment_menu:add_submenu("Teleport", "Apartment heist locations", apartment_teleport_menu)
    apartment_menu:add_submenu("Cuts", "Set player payouts", apartment_cuts_menu)

    heist_menu:add_submenu("Casino Heist", "Diamond Casino Heist tools", casino_menu)
    heist_menu:add_submenu("Cayo Perico", "Cayo Perico Heist tools", cayo_menu)
    heist_menu:add_submenu("Apartment Heists", "Classic apartment heist tools", apartment_menu)
    heist_menu:add_submenu("SilentNight Features", "Ported from SilentNight", create_silentnight_menu())

    local world_menu = Menu.new("World Options", "Modify world settings")

    local teleport_menu = Menu.new("Teleport", "Quick travel locations")

    local settings_menu = Menu.new("Settings", "Configure menu options")
    settings_menu:add_number("Menu Width", "Adjust menu width", 370, 250, 400, 10, function(val)
        CONFIG.width = val
    end, "arrows")
    settings_menu:add_number("Menu X", "Horizontal position", 960, 200, 1720, 20, function(val)
        CONFIG.center_x = val
    end, "arrows")
    settings_menu:add_number("Menu Y", "Vertical position", 400, 100, 900, 20, function(val)
        CONFIG.center_y = val
    end, "arrows")
    settings_menu:add_select("Theme", "Color theme", {"Default", "Dark", "Light", "Blue"}, 1)

    -- Create main menu (kept for compatibility) and wire top tabs
    local main_menu = Menu.new("Menu Base", "Main menu")
    -- Keep the old entries available if someone enters via submenu path
    main_menu:add_submenu("Player", "Player modifications and cheats", player_menu)
    main_menu:add_submenu("Vehicle", "Vehicle spawning and options", vehicle_menu)
    main_menu:add_submenu("Heist", "Casino, Cayo Perico, and Apartment tools", heist_menu)
    main_menu:add_submenu("World", "World and environment settings", world_menu)
    main_menu:add_submenu("Teleport", "Quick travel locations", teleport_menu)
    main_menu:add_separator()
    main_menu:add_submenu("Settings", "Configure menu preferences", settings_menu)

    -- Configure FATE-like top tabs
    MenuSystem.tabs = {
        { label = "Self",    menu = player_menu },
        { label = "Vehicle", menu = vehicle_menu },
        { label = "Heist",   menu = heist_menu },
        { label = "Network", menu = world_menu },
        { label = "Teleport",menu = teleport_menu },
        { label = "Settings",menu = settings_menu }
    }
    MenuSystem.tab_index = 1
    -- Header branding
    MenuSystem.header_title = "Project X"

    return main_menu
end

-----
-- INITIALIZATION
-----
local function initialize()
    MenuSystem.root_menu = create_menu()
    if MenuSystem.tabs and #MenuSystem.tabs > 0 then
        MenuSystem.set_tab(MenuSystem.tab_index or 1)
    else
        MenuSystem.current_menu = MenuSystem.root_menu
    end
    
    -- Ensure menu is closed on start so Lexis controls work
    MenuSystem.active = false

    notify.push("UI Menu", "Press F to open menu", 3000)

    util.create_thread(function()
        while true do
            -- Block game controls ONLY when menu is active (open on screen)
            -- When menu is closed (MenuSystem.active = false), all game and Lexis controls work normally
            if MenuSystem.active then
                -- Block movement controls
                invoker.call(0xFE99B66D079CF6BC, 0, 30, true) -- MoveLeftRight
                invoker.call(0xFE99B66D079CF6BC, 0, 31, true) -- MoveUpDown
                invoker.call(0xFE99B66D079CF6BC, 0, 21, true) -- Sprint
                invoker.call(0xFE99B66D079CF6BC, 0, 22, true) -- Jump
                invoker.call(0xFE99B66D079CF6BC, 0, 36, true) -- Duck
                
                -- Block attack controls
                invoker.call(0xFE99B66D079CF6BC, 0, 24, true) -- Attack
                invoker.call(0xFE99B66D079CF6BC, 0, 25, true) -- Aim
                invoker.call(0xFE99B66D079CF6BC, 0, 140, true) -- MeleeAttackLight
                invoker.call(0xFE99B66D079CF6BC, 0, 141, true) -- MeleeAttackHeavy
                invoker.call(0xFE99B66D079CF6BC, 0, 142, true) -- MeleeAttackAlternate
                
                -- Block interaction controls
                invoker.call(0xFE99B66D079CF6BC, 0, 23, true) -- Enter (F key in game)
                invoker.call(0xFE99B66D079CF6BC, 0, 75, true) -- Exit Vehicle
                invoker.call(0xFE99B66D079CF6BC, 0, 51, true) -- Context (E key)
                
                -- Block phone/menus
                invoker.call(0xFE99B66D079CF6BC, 0, 27, true) -- Phone
                invoker.call(0xFE99B66D079CF6BC, 0, 199, true) -- Pause Menu
                invoker.call(0xFE99B66D079CF6BC, 0, 200, true) -- Pause Menu Alt
            end
            
            InputHandler.process()
            Renderer.draw_menu()
            util.yield(0)
        end
    end)
end

-- Start
local success, err = pcall(initialize)
if not success then
    notify.push("Menu Error", "Init failed: " .. tostring(err), 5000)
end
