tool
extends "../Tool.gd"

func on_left_mouse_click():
	if cell_mouse_position != last_cell_mouse_position:
		var points = canvas.util.get_points_from_line(last_cell_mouse_position, cell_mouse_position)
		for i in points:
			canvas.set_pixel(i, util.random_color_alt())
	
func on_right_mouse_click():
	canvas.util.set_pixels_from_line(last_cell_mouse_position, cell_mouse_position, Color(0, 0, 0, 0))
