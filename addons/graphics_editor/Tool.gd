#Main file for the graphic editor tools!
tool
extends Node

export var keep_running = false
export var tool_name = ""

#Common variables
onready var canvas = get_node("../../../Editor/PaintCanvasContainer/ViewportContainer/Viewport/PaintCanvas")
var util = preload("res://addons/graphics_editor/Util.gd")
var cell_mouse_position = Vector2()
var last_cell_mouse_position = Vector2()
var selected_color = Color()
var cell_color = Color()

#Dummy functions
func on_left_mouse_click():
	pass

func on_right_mouse_click():
	pass
