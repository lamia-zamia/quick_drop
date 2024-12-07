--- @class quickdrop_mouse_to_entity
--- @field private parser quick_drop_entity_parser
--- @field private key_holding boolean
local mte = {
	dim = {},
	parser = dofile_once("mods/quick_drop/files/entity_parser.lua"),
	key_holding = false,
	player_x = 0,
	player_y = 0,
}

local modules = {
	"mods/quick_drop/files/gui_helper.lua",
}
for i = 1, #modules do
	local module = dofile_once(modules[i])
	if not module then error("whoops") end
	for k, v in pairs(module) do
		mte[k] = v
	end
end

--- Drops item
--- @private
--- @param entity_id entity_id
function mte:drop_item(entity_id)
	EntitySetTransform(entity_id, self.player_x, self.player_y - 3, 0, 1, 1)
	EntityRemoveFromParent(entity_id)
	EntitySetComponentsWithTagEnabled(entity_id, "enabled_in_inventory", false)
	EntitySetComponentsWithTagEnabled(entity_id, "enabled_in_world", true)
	EntitySetComponentsWithTagEnabled(entity_id, "item_unidentified", false)
	if self.play_sound then GamePlaySound("data/audio/Desktop/ui.bank", "ui/item_remove", self.player_x, self.player_y) end
end

--- Draws hoverboxes over spells
--- @param x number
--- @param y number
--- @param cards quick_drop_spells
function mte:draw_spells_hoverboxes(x, y, cards)
	for index, spell_id in pairs(cards.spells) do
		if self:draw_hoverbox(x + self.inventory_box_size * index, y) then
			if self.key_holding then self:drop_item(spell_id) end
		end
	end
end

--- Draws hoverbox for wands
--- @private
function mte:draw_wands_hoverboxes()
	local x, y = 26, 49
	for _, wand in pairs(self.parser.wands) do
		y = y + 8 + wand.icon_height + 9
		self:draw_spells_hoverboxes(x, y, wand.cards)
		y = y + 30
	end
end

function mte:draw_inventory_hoverboxes()
	local x, y = 191, 21
	for index, spell_id in pairs(self.parser.inventory_cards) do
		if self:draw_hoverbox(x + self.inventory_box_size * index, y) then
			if self.key_holding then self:drop_item(spell_id) end
		end
	end
end

--- Checks if a player is in tinkering zone
--- @private
--- @param tinkering_zone entity_id
--- @return boolean
function mte:is_in_tinkering_zone(tinkering_zone)
	local hitbox = EntityGetFirstComponent(tinkering_zone, "HitboxComponent")
	if not hitbox then return false end
	local x, y = EntityGetTransform(tinkering_zone)
	local offset = 2 -- why, nolla

	local mx = x + ComponentGetValue2(hitbox, "aabb_min_x") - offset
	local bx = x + ComponentGetValue2(hitbox, "aabb_max_x") + offset
	local my = y + ComponentGetValue2(hitbox, "aabb_min_y") - offset
	local by = y + ComponentGetValue2(hitbox, "aabb_max_y") + offset
	if self.player_x > mx and self.player_x < bx and self.player_y > my and self.player_y < by then return true end

	return false
end

--- Checks if you can tinker
--- @private
--- @param player_id entity_id
--- @return boolean
function mte:can_tinker(player_id)
	local twwe = GameGetGameEffect(player_id, "EDIT_WANDS_EVERYWHERE")
	local no_tinker = GameGetGameEffect(player_id, "NO_WAND_EDITING")
	if no_tinker > 0 and twwe < 1 then return false end
	if twwe > 0 then return true end

	local tinkering_areas = EntityGetInRadiusWithTag(self.player_x, self.player_y, 500, "workshop") or {}
	for i = 1, #tinkering_areas do
		if self:is_in_tinkering_zone(tinkering_areas[i]) then return true end
	end
	return false
end

--- Main loop
function mte:loop()
	self:start_frame()
	if not GameIsInventoryOpen() then return end
	local player = EntityGetWithTag("player_unit")[1]
	if not player then return end
	self.player_x, self.player_y = EntityGetTransform(player)
	if not self:can_tinker(player) then return end
	self.parser:parse(self.gui)
	self.key_holding = self.get_input(self.hotkey)
	self:draw_wands_hoverboxes()
	self:draw_inventory_hoverboxes()
end

--- Gets settings
function mte:get_settings()
	self:update_dims()
	self.hotkey = tonumber(ModSettingGet("quick_drop.hotkey")) or 0
	local type = ModSettingGet("quick_drop.hotkey_type")
	local is_mouse = type == "mouse"
	self.get_input = is_mouse and InputIsMouseButtonDown or InputIsKeyDown
	self.play_sound = ModSettingGet("quick_drop.sound")
end

--- Init script
function mte:init()
	self:get_settings()
end

return mte
