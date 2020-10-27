extends GEAction
class_name GEBucket



func do_action(canvas, data: Array):
	.do_action(canvas, data)
	
	if canvas.get_pixel_v(data[0]) == data[2]:
		return
	var pixels = canvas.select_same_color(data[0].x, data[0].y)
	
	for pixel in pixels:
		if pixel in action_data.undo.cells:
			continue
		
		action_data.undo.colors.append(canvas.get_pixel_v(pixel))
		action_data.undo.cells.append(pixel)
		
		canvas.set_pixel_v(pixel, data[2])
	
		action_data.do.cells.append(pixel)
		action_data.do.colors.append(data[2])


func commit_action(canvas):
	var cells = action_data.preview.cells
	var colors = action_data.preview.colors
	return []


func undo_action(canvas):
	var cells = action_data.undo.cells
	var colors = action_data.undo.colors
	for idx in range(cells.size()):
		canvas.set_pixel_v(cells[idx], colors[idx])



