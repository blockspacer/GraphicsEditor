extends GEAction
class_name GELine


var mouse_start_pos = null

func do_action(canvas, data: Array):
	.do_action(canvas, data)
	
	if mouse_start_pos == null:
		mouse_start_pos = data[0]
	
	action_data.preview.cells.clear()
	action_data.preview.colors.clear()
	canvas.clear_preview_layer()
	
	var pixels = GEUtils.get_pixels_in_line(data[0], mouse_start_pos)
	for pixel in pixels:
		canvas.set_preview_pixel_v(pixel, data[2])
		action_data.preview.cells.append(pixel)
		action_data.preview.colors.append(data[2])


func commit_action(canvas):
	canvas.clear_preview_layer()
	var cells = action_data.preview.cells
	var colors = action_data.preview.colors
	for idx in range(cells.size()):
		action_data.undo.cells.append(cells[idx])
		action_data.undo.colors.append(canvas.get_pixel_v(cells[idx]))
		
		canvas.set_pixel_v(cells[idx], colors[idx])
	
		action_data.do.cells.append(cells[idx])
		action_data.do.colors.append(colors[idx])
	mouse_start_pos = null
	return []


func undo_action(canvas):
	var cells = action_data.undo.cells
	var colors = action_data.undo.colors
	for idx in range(cells.size()):
		canvas.set_pixel_v(cells[idx], colors[idx])



