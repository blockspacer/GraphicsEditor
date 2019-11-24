tool
extends Control

#TODO: Make the settings auto generate!

onready var editor = get_parent()
onready var canvas_outline = get_parent().get_node("PaintCanvasContainer/ViewportContainer/Viewport/PaintCanvas/CanvasOutline")
onready var visual_grid_1 = get_parent().get_node("PaintCanvasContainer/ViewportContainer/Viewport/PaintCanvas/Grids/VisualGrid")
onready var visual_grid_2 = get_parent().get_node("PaintCanvasContainer/ViewportContainer/Viewport/PaintCanvas/Grids/VisualGrid2")

func _ready():
	#CanvasOutline settings
	get_node("CanvasOutline/Enabled/CheckButton").pressed = canvas_outline.visible
	get_node("CanvasOutline/Color/ColorPickerButton").color = canvas_outline.color
	get_node("CanvasOutline/Width/SpinBox").value = canvas_outline.width
	
	#Grid settings
	get_node("Grids/Grid1Color/ColorPickerButton").color = visual_grid_1.color
	get_node("Grids/Grid1Size/SpinBox").value = visual_grid_1.size
	get_node("Grids/Grid2Color/ColorPickerButton").color = visual_grid_2.color
	get_node("Grids/Grid2Size/SpinBox").value = visual_grid_2.size

func _on_Ok_pressed():
	hide()

func _on_CanvasOutline_Enabled_value_changed(button_pressed):
	canvas_outline.visible = button_pressed

func _on_CanvasOutline_Color_value_changed(color):
	canvas_outline.color = color

func _on_CanvasOutline_SpinBox_value_changed(value):
	canvas_outline.width = value

func _on_Grids_Grid1Color_value_changed(color):
	visual_grid_1.color = color

func _on_Grids_Grid1Size_value_changed(value):
	visual_grid_1.size = value

func _on_Grids_Grid2Color_value_changed(color):
	visual_grid_2.color = color

func _on_Grids_Grid2Size_value_changed(value):
	visual_grid_2.size = value
