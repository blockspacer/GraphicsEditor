extends GEAction
class_name GEPencil


func do_action(canvas, data: Array):
	if not "cells" in action_data.do:
		action_data.do["cells"] = []
		action_data.do["colors"] = []
	
	if not "cells" in action_data.undo:
		action_data.undo["cells"] = []
		action_data.undo["colors"] = []
	
	var pixels = GEUtils.get_pixels_in_line(data[0], data[1])
	
	for pixel in pixels:
		canvas.set_pixel_v(pixel, data[2])
		action_data.do.cells.append(pixel)
		action_data.undo.cells.append(pixel)
	
		action_data.do.colors.append(data[2])
		action_data.undo.colors.append(Color.transparent)


func commit_action(canvas):
	var cells = action_data.do.cells
	var colors = action_data.do.colors


func undo_action(canvas):
	var cells = action_data.undo.cells
	var colors = action_data.undo.colors
	for idx in range(cells.size()):
		canvas.set_pixel_v(cells[idx], colors[idx])



