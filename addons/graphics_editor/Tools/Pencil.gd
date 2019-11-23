tool
extends "../Tool.gd"

func on_left_mouse_click():
	canvas.util.set_pixels_from_line(last_cell_mouse_position, cell_mouse_position, selected_color)
	
func on_right_mouse_click():
	canvas.util.set_pixels_from_line(last_cell_mouse_position, cell_mouse_position, Color(0, 0, 0, 0))
