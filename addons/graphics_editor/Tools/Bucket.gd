tool
extends "../Tool.gd"

func on_left_mouse_click():
	canvas.util.flood_fill(cell_mouse_position, cell_color, selected_color)
	
func on_right_mouse_click():
	canvas.util.flood_fill(cell_mouse_position, cell_color, Color(0, 0, 0, 0))
