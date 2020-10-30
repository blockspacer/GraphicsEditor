extends GEAction
class_name GEPencil


func do_action(canvas, data: Array):
	.do_action(canvas, data)
	
	var pixels = GEUtils.get_pixels_in_line(data[0], data[1])
	for pixel in pixels:
		if pixel in action_data.undo.cells or canvas.get_pixel_v(pixel) == null:
			continue
		
		action_data.undo.colors.append(canvas.get_pixel_v(pixel))
		action_data.undo.cells.append(pixel)
		
		canvas.set_pixel_v(pixel, data[2])
	
		action_data.do.cells.append(pixel)
		action_data.do.colors.append(data[2])


func commit_action(canvas):
	var cells = action_data.do.cells
	var colors = action_data.do.colors
	return []


func undo_action(canvas):
	var cells = action_data.undo.cells
	var colors = action_data.undo.colors
	for idx in range(cells.size()):
		canvas.set_pixel_v(cells[idx], colors[idx])



