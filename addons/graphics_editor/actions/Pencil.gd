extends "res://addons/graphics_editor/actions/Action.gd"



func do_action(data: Array):
	action_data["do"] = {
		"cell_position": data[0],
		"last_cell_position": data[1],
		"color": data[2],
	}
	
	action_data["undo"] = {
		"cell_position": data[0],
		"last_cell_position": data[1],
		"color": get("painter").get_pixel_cell_color_v(action_data.do.cell_position),
	}
	
	get("painter").set_pixels_from_line(action_data.do.cell_position, action_data.do.last_cell_position, action_data.do.color)


func undo_action(data: Array):
	get("painter").set_pixels_from_line(action_data.undo.cell_position, action_data.undo.last_cell_position, action_data.undo.color)



