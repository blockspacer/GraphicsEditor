extends GEAction
class_name GEBrighten


const brighten_color = 0.1


func do_action(canvas, data: Array):
	.do_action(canvas, data)
	
	var pixels = GEUtils.get_pixels_in_line(data[0], data[1])
	for pixel in pixels:
		if pixel in action_data.undo.cells:
			var brightened_color = canvas.get_pixel_v(pixel).lightened(0.1)
			canvas.set_pixel_v(pixel, brightened_color)
		
			action_data.do.cells.append(pixel)
			action_data.do.colors.append(brightened_color)
			continue
		
		action_data.undo.colors.append(canvas.get_pixel_v(pixel))
		action_data.undo.cells.append(pixel)
		var brightened_color = canvas.get_pixel_v(pixel).lightened(0.1)
		canvas.set_pixel_v(pixel, brightened_color)
	
		action_data.do.cells.append(pixel)
		action_data.do.colors.append(brightened_color)


func commit_action(canvas):
	var cells = action_data.do.cells
	var colors = action_data.do.colors
	return []


func undo_action(canvas):
	var cells = action_data.undo.cells
	var colors = action_data.undo.colors
	for idx in range(cells.size()):
		canvas.set_pixel_v(cells[idx], colors[idx])



