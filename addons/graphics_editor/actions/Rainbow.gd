extends GEAction
class_name GERainbow


func do_action(canvas, data: Array):
	.do_action(canvas, data)
	
	var pixels = GEUtils.get_pixels_in_line(data[0], data[1])
	for pixel in pixels:
		if pixel in action_data.undo.cells:
			var color = GEUtils.random_color()
			canvas.set_pixel_v(pixel, color)
			
			var idx = action_data.do.cells.find(pixel)
			action_data.do.cells.remove(idx)
			action_data.do.colors.remove(idx)
			
			action_data.do.cells.append(pixel)
			action_data.do.colors.append(color)
			continue
		
		action_data.undo.colors.append(canvas.get_pixel_v(pixel))
		action_data.undo.cells.append(pixel)
		
		var color = GEUtils.random_color()
		canvas.set_pixel_v(pixel, color)
	
		action_data.do.cells.append(pixel)
		action_data.do.colors.append(color)


func commit_action(canvas):
	var cells = action_data.do.cells
	var colors = action_data.do.colors
	return []


func undo_action(canvas):
	var cells = action_data.undo.cells
	var colors = action_data.undo.colors
	for idx in range(cells.size()):
		canvas.set_pixel_v(cells[idx], colors[idx])



