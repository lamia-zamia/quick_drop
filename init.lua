local mte = dofile_once("mods/quick_drop/files/mouse_to_entity.lua") --- @type quickdrop_mouse_to_entity

--- Main loop
function OnWorldPostUpdate()
	mte:loop()
end

--- On player spawn (duh)
function OnPlayerSpawned()
	mte:init()
end

--- Updates settings when paused
function OnPausedChanged()
	mte:get_settings()
end
