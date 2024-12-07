--- @class quickdrop_mouse_to_entity
--- @field dim {vx:number, vy: number, x:number, y:number}
--- @field gui gui
--- @field gui_id number
local mte = {
	gui = GuiCreate(),
	gui_id = 100000,
	inventory_box_size = 20,
}

--- Draws a hoverbox over coordinates and returns true if hovered
--- @private
--- @param x number
--- @param y number
--- @return boolean hovered
function mte:draw_hoverbox(x, y)
	local size = 18 --self.inventory_box_size
	-- GuiImageNinePiece(self.gui, self.gui_id, x, y, size, size, 1) -- visible 9piece for debugging
	GuiImageNinePiece(self.gui, self.gui_id, x, y, size, size, 1, "data/debug/empty.png", "data/debug/empty.png")
	local _, _, hovered = GuiGetPreviousWidgetInfo(self.gui)
	return hovered
end

--- Updates dimensions
--- @private
function mte:update_dims()
	local gui_temp = GuiCreate()
	self.dim.vx, self.dim.vy = GuiGetScreenDimensions(gui_temp)
	GuiStartFrame(gui_temp)
	self.dim.x, self.dim.y = GuiGetScreenDimensions(gui_temp)
	local box_width, box_height = GuiGetImageDimensions(gui_temp, "data/ui_gfx/inventory/full_inventory_box.png")
	self.inventory_box_size = box_width
	GuiDestroy(gui_temp)
end

--- Starts frame
--- @private
function mte:start_frame()
	GuiStartFrame(self.gui)
	self.gui_id = 100000
end

return mte
