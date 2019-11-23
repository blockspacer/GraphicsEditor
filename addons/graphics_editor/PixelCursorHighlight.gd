tool
extends Control

var cell_mouse_position = Vector2()
var grid_size = 0

func _process(delta):
	var canvas_mouse_position = get_parent().get_local_mouse_position()
	grid_size = get_parent().grid_size
	cell_mouse_position = Vector2(floor(canvas_mouse_position.x / grid_size), floor(canvas_mouse_position.y / grid_size))
	update()

func _draw():
	draw_rect(Rect2(Vector2((cell_mouse_position.x * grid_size), (cell_mouse_position.y * grid_size)), Vector2(grid_size, grid_size)), Color(0.8, 0.8, 0.8, 0.8), true)
