tool
extends Node

onready var paint_canvas = get_parent()
onready var util = preload("res://addons/graphics_editor/Util.gd")

func _ready():
	pass

func set_pixels_from_line(vec2_1, vec2_2, color):
	var points = get_points_from_line(vec2_1, vec2_2)
	for i in points:
		paint_canvas.set_pixel(i, color)
	
func get_points_from_line(vec2_1, vec2_2):
	var points = PoolVector2Array()
	
	var dx = abs(vec2_2.x - vec2_1.x)
	var dy = abs(vec2_2.y - vec2_1.y)
	
	var x = vec2_1.x
	var y = vec2_1.y
	
	var sx = 0
	if vec2_1.x > vec2_2.x:
		sx = -1
	else:
		sx = 1

	var sy = 0
	if vec2_1.y > vec2_2.y:
		sy = -1
	else:
		sy = 1
		
	if dx > dy:
		var err = dx / 2
		while(true):
			if x == vec2_2.x:
				break
			points.push_back(Vector2(x, y))
			
			err -= dy
			if err < 0:
				y += sy
				err += dx
			x += sx
	else:
		var err = dy / 2
		while (true):
			if y == vec2_2.y:
				break
			points.push_back(Vector2(x, y))
			
			err -= dx
			if err < 0:
				x += sx
				err += dy
			y += sy
	points.push_back(Vector2(x, y))
	return points

#Flood fill algrorithm copied and modified from Pixeloroma!
#https://github.com/OverloadedOrama/Pixelorama/blob/master/Scripts/Canvas.gd
func flood_fill(pos, target_color, replacement_color):
	if target_color == replacement_color:
		return
	elif paint_canvas.get_pixel(pos) != target_color:
		return
	elif !paint_canvas.pixel_in_canvas_region(pos):
		return
	var q = [pos]
	for n in q:
		var west = n
		var east = n
		while paint_canvas.get_pixel(west) == target_color:
			west += Vector2.LEFT
		while paint_canvas.get_pixel(east) == target_color:
			east += Vector2.RIGHT
		for px in range(west.x + 1, east.x):
			var p = Vector2(px, n.y)
			paint_canvas.set_pixel(p, replacement_color)
			var north = p + Vector2.UP
			var south = p + Vector2.DOWN
			if paint_canvas.get_pixel(north) == target_color:
				q.append(north)
			if paint_canvas.get_pixel(south) == target_color:
				q.append(south)