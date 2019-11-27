tool
extends Control

onready var paint_canvas_container_node = get_node("PaintCanvasContainer")
onready var paint_canvas_node = paint_canvas_container_node.get_node("ViewportContainer/Viewport/PaintCanvas")
onready var paint_canvas_image_node = paint_canvas_node.get_node("CanvasImage")
onready var camera = paint_canvas_container_node.get_node("ViewportContainer/Viewport/Camera2D")
onready var grids_node = paint_canvas_node.get_node("Grids")
onready var tool_manager = get_node("ToolManager")
onready var textinfo = get_node("BottomPanel/TextInfo")
onready var layers = get_node("ToolMenu/Layers")
onready var grid_size = paint_canvas_node.grid_size
onready var chunk_size = paint_canvas_node.chunk_size
var selected_color = Color(1, 1, 1, 1)
var util = preload("res://addons/graphics_editor/Util.gd")
var allow_drawing = true

#TODO:
#Work on the brush system!
#Make a GUI Notification script!

func _ready():
	#-----------------
	#Setup active tool
	#-----------------
	tool_manager.set_active_tool("Pencil")
	
	#---------------------------
	#Setup the info bottom panel
	#---------------------------
	add_text_info_variables()
	
	#------------------
	#Setup visual grids
	#------------------
	paint_canvas_node.connect("grid_resized", self, "grid_resized")
	grid_resized(paint_canvas_node.grid_size)
	
	#-----------------------------------------------------------------------
	#Set the selected color to what the color picker has selected as default
	#-----------------------------------------------------------------------
	selected_color = get_node("ToolMenu/Buttons/ColorPicker").color

#TODO: Make the paint canvas chunk size not a vector2?
func grid_resized(size):
	grids_node.get_node("VisualGrid").rect_size = paint_canvas_node.canvas_size * size
	grids_node.get_node("VisualGrid").size = size
	grids_node.get_node("VisualGrid2").rect_size = paint_canvas_node.canvas_size * size
	grids_node.get_node("VisualGrid2").size = size * paint_canvas_node.chunk_size.x

var mouse_position = Vector2()
var canvas_position = Vector2()
var canvas_mouse_position = Vector2()
var cell_mouse_position = Vector2()
var cell_region_position = Vector2()
var cell_position_in_region = Vector2()
var cell_color = Color()
func process_common_used_variables():
	grid_size = paint_canvas_node.grid_size
	chunk_size = paint_canvas_node.chunk_size
	mouse_position = get_local_mouse_position()
	canvas_mouse_position = paint_canvas_node.get_local_mouse_position()
	cell_mouse_position = Vector2(floor(canvas_mouse_position.x / grid_size), floor(canvas_mouse_position.y / grid_size))
	cell_region_position = Vector2(floor(cell_mouse_position.x / chunk_size.x), floor(cell_mouse_position.y / chunk_size.y))
	cell_position_in_region = paint_canvas_node.pixel_in_canvas_region(cell_mouse_position)
	cell_color = paint_canvas_node.get_pixel(cell_mouse_position)

var last_mouse_position = Vector2()
var last_canvas_position = Vector2()
var last_canvas_mouse_position = Vector2()
var last_cell_mouse_position = Vector2()
var last_cell_color = Color()
func process_last_common_used_variables():
	last_mouse_position = mouse_position
	last_canvas_position = canvas_position
	last_canvas_mouse_position = canvas_mouse_position
	last_cell_mouse_position = cell_mouse_position
	last_cell_color = cell_color

var active_tool
func process_active_tool():
	active_tool = get_node("ToolManager").get_active_tool()
	active_tool.cell_mouse_position = cell_mouse_position
	active_tool.last_cell_mouse_position = last_cell_mouse_position
	active_tool.selected_color = selected_color
	active_tool.cell_color = cell_color

# warning-ignore:unused_argument
func _process(delta):
	#It's a lot more easier to just keep updating the variables in here than just have a bunch of local variables
	#in every update function and make it very messy
		
	#Update commonly used variables
	process_common_used_variables()
	
	#Process the active tool
	process_active_tool()
	
	#Process the brush drawing stuff
	if paint_canvas_container_node.mouse_in_region and paint_canvas_container_node.mouse_on_top:
		brush_process()
	
	#Render the highlighting stuff
	update()
	
	#Canvas Shift Moving
	if mouse_position != last_mouse_position:
		if paint_canvas_container_node.has_focus():
			if Input.is_key_pressed(KEY_SHIFT) or Input.is_mouse_button_pressed(BUTTON_MIDDLE):
				if Input.is_mouse_button_pressed(BUTTON_LEFT) or Input.is_mouse_button_pressed(BUTTON_MIDDLE):
					var relative = mouse_position - last_mouse_position
					camera.position -= relative * camera.zoom
				allow_drawing = false
			else:
				allow_drawing = true
	
	#Update text info
	update_text_info()
	
	#Update last variables with the current variables
	process_last_common_used_variables()

func brush_process():
	if Input.is_mouse_button_pressed(BUTTON_LEFT):
		if allow_drawing:
			active_tool.on_left_mouse_click()
			
	elif Input.is_mouse_button_pressed(BUTTON_RIGHT):
		if allow_drawing:
			active_tool.on_right_mouse_click()

var zoom_amount = 0.5
func _input(event):
	if event is InputEventMouseButton:
		if event.is_pressed():
			if paint_canvas_container_node.mouse_in_region and paint_canvas_container_node.mouse_on_top:
				if event.button_index == BUTTON_WHEEL_UP:
					if camera.zoom - Vector2(zoom_amount, zoom_amount) > Vector2(0, 0):
						camera.zoom -= Vector2(zoom_amount, zoom_amount)
				elif event.button_index == BUTTON_WHEEL_DOWN:
					camera.zoom += Vector2(zoom_amount, zoom_amount)

func add_text_info_variables():
	textinfo.add_text_info("FPS")
	textinfo.add_text_info("Mouse Position")
	textinfo.add_text_info("Canvas Mouse Position")
	textinfo.add_text_info("Canvas Position")
	textinfo.add_text_info("Cell Position")
	var cell_color_texture_rect = ColorRect.new()
	cell_color_texture_rect.name = "Cell Color"
	cell_color_texture_rect.rect_size = Vector2(14, 14)
	cell_color_texture_rect.rect_position.x = 120
	textinfo.add_text_info("Cell Color", cell_color_texture_rect)
	textinfo.add_text_info("Cell Region")
	textinfo.add_text_info("Cell Position in Region")

func update_text_info():
	textinfo.update_text_info("FPS", Engine.get_frames_per_second())
	textinfo.update_text_info("Mouse Position", mouse_position)
	textinfo.update_text_info("Canvas Mouse Position", canvas_mouse_position)
	textinfo.update_text_info("Canvas Position", canvas_position)
	textinfo.update_text_info("Cell Position", cell_mouse_position)
	var cell_color_text = cell_color
	if paint_canvas_container_node.mouse_in_region and paint_canvas_container_node.mouse_on_top:
		if Input.is_mouse_button_pressed(BUTTON_LEFT) or Input.is_mouse_button_pressed(BUTTON_RIGHT):
			if paint_canvas_node.last_pixel_drawn.size() > 0:
				cell_color_text = paint_canvas_node.last_pixel_drawn[1]
	if cell_color_text == null:
		cell_color_text = Color(0, 0, 0, 0)
	textinfo.update_text_info("Cell Color", cell_color_text, "Cell Color", "color", cell_color_text)
	textinfo.update_text_info("Cell Region", cell_region_position)
	textinfo.update_text_info("Cell Position in Region", cell_position_in_region)

func _on_PaintTool_pressed():
	tool_manager.set_active_tool("Pencil")

func _on_BucketTool_pressed():
	tool_manager.set_active_tool("Bucket")

func _on_ColorPicker_color_changed(color):
	selected_color = color

func _on_Save_pressed():
	get_node("SaveFileDialog").show()

func _on_RainbowTool_pressed():
	tool_manager.set_active_tool("Rainbow")
