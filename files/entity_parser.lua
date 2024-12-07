--- @class quick_drop_spells
--- @field spells {[number]:entity_id}

--- @class quick_drop_wand
--- @field slot number
--- @field icon_height number
--- @field cards quick_drop_spells

--- @class quick_drop_entity_parser
--- @field wands quick_drop_wand[]
--- @field inventory_cards quick_drop_spells
local ep = {
	wands = {},
	inventory_cards = {}, ---@diagnostic disable-line: missing-fields
}

--- Returns items inventory slot
--- @private
--- @param item entity_id
--- @return number inventory_slot
function ep:get_inventory_slot(item)
	local item_component = EntityGetFirstComponentIncludingDisabled(item, "ItemComponent")
	if not item_component then return 99 end
	local slot = ComponentGetValue2(item_component, "inventory_slot")
	return slot
end

--- Returns player quick_inventory entity_id
--- @private
--- @return entity_id? quick_inventory_id
function ep:get_quick_inventory()
	local player = EntityGetWithTag("player_unit")[1]
	if not player then return end
	local children = EntityGetAllChildren(player) or {}
	for i = 1, #children do
		local child = children[i]
		if EntityGetName(child) == "inventory_quick" then return child end
	end
end

--- Returns player full_inventory entity_id
--- @private
--- @return entity_id? full_inventory_id
function ep:get_full_inventory()
	local player = EntityGetWithTag("player_unit")[1]
	if not player then return end
	local children = EntityGetAllChildren(player) or {}
	for i = 1, #children do
		local child = children[i]
		if EntityGetName(child) == "inventory_full" then return child end
	end
end

--- Parse spell entity
--- @private
--- @param spell entity_id
--- @return number? slot_number
function ep:parse_spell(spell)
	local item_component = EntityGetFirstComponentIncludingDisabled(spell, "ItemComponent")
	if not item_component then return end
	if ComponentGetValue2(item_component, "permanently_attached") then return end -- we don't need always cast
	local slot = ComponentGetValue2(item_component, "inventory_slot")
	return slot
end

--- Returns wand sprite size
--- @private
--- @param gui gui
--- @param wand entity_id
--- @return number height
function ep:get_wand_sprite_size(gui, wand)
	local ability_component = EntityGetFirstComponentIncludingDisabled(wand, "AbilityComponent")
	if not ability_component then return 0 end
	local sprite_file = ComponentGetValue2(ability_component, "sprite_file")
	local _, height = GuiGetImageDimensions(gui, sprite_file, 2)
	return height
end

--- Parses child entity cards
--- @private
--- @param entity_id entity_id
--- @return quick_drop_spells cards
function ep:parse_child_cards(entity_id)
	local children = EntityGetAllChildren(entity_id, "card_action") or {}
	local cards = {}
	for i = 1, #children do
		local action = children[i]
		local slot = self:parse_spell(action)
		if slot then cards[slot] = action end
	end
	return cards
end

--- Parse wand and it's spells
--- @private
--- @param gui gui
--- @param wand entity_id
function ep:parse_wand(gui, wand)
	local wand_slot = self:get_inventory_slot(wand)
	self.wands[wand_slot] = {
		slot = wand_slot,
		icon_height = self:get_wand_sprite_size(gui, wand),
		cards = {
			spells = self:parse_child_cards(wand),
		},
	}
end

--- Parse inventory
--- @param gui gui
function ep:parse(gui)
	local quick_inventory = self:get_quick_inventory()
	if not quick_inventory then return end
	local full_inventory = self:get_full_inventory()
	if not full_inventory then return end

	local wands = EntityGetAllChildren(quick_inventory, "wand") or {}
	self.wands = {}
	for i = 1, #wands do
		self:parse_wand(gui, wands[i])
	end

	self.inventory_cards = self:parse_child_cards(full_inventory)
end

return ep
