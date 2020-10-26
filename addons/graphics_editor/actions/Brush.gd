extends GEAction
class_name GEBrush


func do_action(canvas: GECanvas, data: Array):
	if not "cells" in action_data.do:
		action_data.do["cells"] = []
		action_data.do["colors"] = []
	
	if not "cells" in action_data.undo:
		action_data.undo["cells"] = []
		action_data.undo["colors"] = []
	
	if "layer" in action_data.do:
		action_data.do["layer"] = canvas.active_layer
		action_data.undo["layer"] = canvas.active_layer
	
	for pixel in GEUtils.get_pixels_in_line(data[0], data[1]):
		for off in BrushPrefabs.list[data[3]]:
			var p = pixel + off
			
			if p in action_data.undo.cells or canvas.get_pixel_v(p) == null:
				continue
			
			action_data.undo.colors.append(canvas.get_pixel_v(p))
			action_data.undo.cells.append(p)
			
			canvas.set_pixel_v(p, data[2])
		
			action_data.do.cells.append(p)
			action_data.do.colors.append(data[2])


func commit_action(canvas):
	var cells = action_data.do.cells
	var colors = action_data.do.colors


func undo_action(canvas):
	var cells = action_data.undo.cells
	var colors = action_data.undo.colors
	for idx in range(cells.size()):
		canvas.set_pixel_v(cells[idx], colors[idx])



