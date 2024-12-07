---@diagnostic disable: missing-global-doc
dofile_once("data/scripts/lib/mod_settings.lua")

local mod_id = "quick_drop"
local prfx = mod_id .. "."

--- gather keycodes from game file
local function gather_key_codes()
	local keyboard = {}
	local mouse = {}
	keyboard["0"] = GameTextGetTranslatedOrNot("$menuoptions_configurecontrols_action_unbound")
	mouse["0"] = GameTextGetTranslatedOrNot("$menuoptions_configurecontrols_action_unbound")
	local keycodes_all = ModTextFileGetContent("data/scripts/debug/keycodes.lua")
	for line in keycodes_all:gmatch("Key_.-\n") do
		local _, key, code = line:match("(Key_)(.+) = (%d+)")
		keyboard[code] = key:upper()
	end
	for line in keycodes_all:gmatch("Mouse_.-\n") do
		local key, code = line:match("(Mouse_.+) = (%d+)")
		mouse[code] = key:upper()
	end
	return keyboard, mouse
end
local keycodes_kb, keycodes_mouse = gather_key_codes()

local function pending_input(is_mouse)
	if is_mouse then
		for code, _ in pairs(keycodes_mouse) do
			if InputIsMouseButtonJustDown(code) then return code end
		end
	else
		for code, _ in pairs(keycodes_kb) do
			if InputIsKeyJustDown(code) then return code end
		end
	end
end

local function ui_get_input(_, gui, _, im_id, setting)
	local setting_id = prfx .. setting.id
	local type = ModSettingGetNextValue("quick_drop.hotkey_type")
	local is_mouse = type == "mouse"
	local hotkey = is_mouse and keycodes_mouse or keycodes_kb
	local current = tostring(ModSettingGetNextValue(setting_id)) or "0"
	local current_key = string.format("[%s]", hotkey[current] or hotkey["0"])

	if setting.is_waiting_for_input then
		current_key = string.format("[%s]", GameTextGetTranslatedOrNot("$menuoptions_configurecontrols_pressakey"))
		local new_key = pending_input(is_mouse)
		if new_key then
			ModSettingSetNextValue(setting_id, new_key, false)
			setting.is_waiting_for_input = false
		end
	end

	GuiLayoutBeginHorizontal(gui, 0, 0, true, 0, 0)
	GuiText(gui, mod_setting_group_x_offset, 0, setting.ui_name)

	GuiText(gui, 8, 0, "")
	local _, _, _, x, y = GuiGetPreviousWidgetInfo(gui)
	local w, h = GuiGetTextDimensions(gui, current_key)
	GuiOptionsAddForNextWidget(gui, GUI_OPTION.ForceFocusable)
	GuiImageNinePiece(gui, im_id, x, y, w, h, 0)
	local _, _, hovered = GuiGetPreviousWidgetInfo(gui)
	if hovered then
		GuiTooltip(gui, setting.ui_description, GameTextGetTranslatedOrNot("$menuoptions_reset_keyboard"))
		GuiColorSetForNextWidget(gui, 1, 1, 0.7, 1)
		if InputIsMouseButtonJustDown(1) then setting.is_waiting_for_input = true end
		if InputIsMouseButtonJustDown(2) then
			GamePlaySound("ui", "ui/button_click", 0, 0)
			ModSettingSetNextValue(setting_id, setting.value_default, false)
			setting.is_waiting_for_input = false
		end
	end
	GuiText(gui, 0, 0, current_key)

	GuiLayoutEnd(gui)
end

local function build_settings()
	local settings = {
		{
			id = "hotkey_type",
			ui_name = "Hotkey type",
			ui_description = "Mouse or Keyboard",
			value_default = "mouse",
			values = { { "mouse", "Mouse" }, { "keyboard", "Keyboard" } },
			scope = MOD_SETTING_SCOPE_RUNTIME,
			change_fn = function()
				ModSettingSetNextValue("quick_drop.hotkey", "0", false)
			end,
		},
		{
			id = "hotkey",
			ui_name = "Hotkey",
			ui_description = "Hotkey to drop spell",
			value_default = "2",
			ui_fn = ui_get_input,
			is_waiting_for_input = false,
			scope = MOD_SETTING_SCOPE_RUNTIME,
		},
		{
			id = "sound",
			ui_name = "Play sound on drop",
			ui_description = "Play drop sound on quick drop",
			value_default = true,
			scope = MOD_SETTING_SCOPE_RUNTIME,
		},
	}
	return settings
end
mod_settings = build_settings()

-- This function is called to ensure the correct setting values are visible to the game. your mod's settings don't work if you don't have a function like this defined in settings.lua.
function ModSettingsUpdate(init_scope)
	mod_settings = build_settings()
	mod_settings_update(mod_id, mod_settings, init_scope)
end

-- This function should return the number of visible setting UI elements.
-- Your mod's settings wont be visible in the mod settings menu if this function isn't defined correctly.
-- If your mod changes the displayed settings dynamically, you might need to implement custom logic for this function.
function ModSettingsGuiCount()
	return mod_settings_gui_count(mod_id, mod_settings)
end

-- This function is called to display the settings UI for this mod. your mod's settings wont be visible in the mod settings menu if this function isn't defined correctly.
function ModSettingsGui(gui, in_main_menu)
	mod_settings_gui(mod_id, mod_settings, gui, in_main_menu)
end
