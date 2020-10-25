tool
extends Control

export var color = Color()

func _ready():
	pass

func _draw():
	var size = get_parent().get_node("Grids").rect_size
	var pos = get_parent().get_node("Grids").rect_position
	draw_outline_box(pos, size, color, 1)

func draw_outline_box(pos, size, color, width):
		#Top line
		pos -= Vector2(0, 0)
		size += Vector2(0, 0)
		draw_line(pos, pos + Vector2(size.x, 0), color, width)
		#Left line
		draw_line(pos, pos + Vector2(0, size.y), color, width)
		#Bottom line
		draw_line(pos + Vector2(0, size.y), pos + Vector2(size.x, size.y), color, width)
		#Right line
		draw_line(pos + Vector2(size.x, 0), pos + Vector2(size.x, size.y), color, width)

func _process(delta):
	update()
