tool
extends Control

enum Tools {
	PAINT,
	BRUSH,
	BUCKET,
	RAINBOW,
	LINE,
	RECT,
	DARKEN,
	BRIGHTEN
	COLORPICKER,
	CUT,
}

var paint_canvas_container_node
var paint_canvas_node
var grids_node
var colors_grid
var selected_color = Color(1, 1, 1, 1)
var util = preload("res://addons/graphics_editor/Util.gd")
var textinfo
onready var grid_size = paint_canvas_node.grid_size
onready var region_size = paint_canvas_node.region_size
var allow_drawing = true


var _left_mouse_pressed_start_pos = Vector2()
var _previous_tool

var _layer_button_ref = {}

var _total_added_layers = 1

var selected_brush_prefab = 0
var _last_drawn_pixel = Vector2.ZERO
var _last_preview_draw_cell_pos = Vector2.ZERO
var _selection = []
var _just_cut = false
var _show_cut = false
var _cut_pos = Vector2.ZERO
var _cut_size = Vector2.ZERO

var _actions_history = [] # for undo
var _redo_history = []

var Actions = {
	Tools.PAINT: load("res://addons/graphics_editor/actions/Pencil.gd").new(),
}


func _enter_tree():
	#--------------------
	#Setup nodes
	#--------------------
	paint_canvas_container_node = find_node("PaintCanvasContainer")
	paint_canvas_node = paint_canvas_container_node.find_node("PaintCanvas")
	grids_node = paint_canvas_node.find_node("Grids")
	textinfo = find_node("DebugTextDisplay")
	selected_color = find_node("ColorPicker").color
	colors_grid = find_node("Colors")
	
	set_process(true)
	#--------------------
	# Setup Actions
	#--------------------
	for key in Actions:
		Actions[key].painter = paint_canvas_node
	
	#--------------------
	#connect nodes
	#--------------------
	if not colors_grid.is_connected("color_change_request", self, "change_color"):
		colors_grid.connect("color_change_request", self, "change_color")
	
	if not is_connected("visibility_changed", self, "_on_Editor_visibility_changed"):
		connect("visibility_changed", self, "_on_Editor_visibility_changed")
	
	#--------------------
	#Setup the layer
	#--------------------
	var layer_container = find_node("Layers")
	
	for child in layer_container.get_children():
		if child.name == "Layer1" or child.name == "Button":
			continue
		print("too many children: ", child.name)
#		child.queue_free()
	
	#------------------
	#Setup visual grids
	#------------------
#	for i in grids_node.get_children():
#		i.rect_size = Vector2(paint_canvas_node.canvas_size.x * grid_size, paint_canvas_node.canvas_size.y * grid_size)
#	grids_node.get_node("VisualGrid").size = grid_size
#	grids_node.get_node("VisualGrid2").size = grid_size * region_size
	
	#-----------------------------------
	#Setup canvas node size and position
	#-----------------------------------
#	paint_canvas_node.rect_size = Vector2(paint_canvas_node.canvas_size.x * grid_size, 
#		paint_canvas_node.canvas_size.y * grid_size)
#	paint_canvas_node.rect_min_size = Vector2(paint_canvas_node.canvas_size.x * grid_size, 
#		paint_canvas_node.canvas_size.y * grid_size)
	
	#----------------------------------------------------------------
	#Setup is done so we can now allow the user to draw on the canvas
	#----------------------------------------------------------------
	paint_canvas_node.can_draw = true


func _ready():
	_add_init_layers()


func _add_init_layers():
	var i = 0
	for layer in paint_canvas_node.layers:
		if layer == paint_canvas_node.preview_layer:
			continue
		_layer_button_ref[layer] = find_node("Layers").get_child(i)
		print("layer: ", layer, " is ", find_node("Layers").get_child(i).name)
		i += 1
	_connect_layer_buttons()


func _input(event):
	if Input.is_key_pressed(KEY_Z):
		print("Z")
	elif Input.is_key_pressed(KEY_Y):
		print("Y")
	


var brush_mode = Tools.PAINT

var mouse_position = Vector2()
var canvas_position = Vector2()
var canvas_mouse_position = Vector2()
var cell_mouse_position = Vector2()
var cell_region_position = Vector2()
var cell_position_in_region = Vector2()
var cell_color = Color()

var last_mouse_position = Vector2()
var last_canvas_position = Vector2()
var last_canvas_mouse_position = Vector2()
var last_cell_mouse_position = Vector2()
var last_cell_color = Color()


# warning-ignore:unused_argument
func _process(delta):
	update_text_info()
	#It's a lot more easier to just keep updating the variables in here than just have a bunch of local variables
	#in every update function and make it very messy
	if paint_canvas_node == null:
		#_check_variables()
		set_process(false)
		return
	
	#Update commonly used variables
	grid_size = paint_canvas_node.grid_size
	region_size = paint_canvas_node.region_size
	mouse_position = paint_canvas_node.get_local_mouse_position()
	canvas_position = paint_canvas_container_node.rect_position
	canvas_mouse_position = Vector2(mouse_position.x - canvas_position.x, mouse_position.y - canvas_position.y)
	cell_mouse_position = Vector2(floor(canvas_mouse_position.x / grid_size), floor(canvas_mouse_position.y / grid_size))
	cell_region_position = Vector2(floor(cell_mouse_position.x / region_size), floor(cell_mouse_position.y / region_size))
	cell_position_in_region = paint_canvas_node.get_region_from_cell(cell_mouse_position.x, cell_mouse_position.y)
	cell_color = paint_canvas_node.get_pixel_cell_color(cell_mouse_position.x, cell_mouse_position.y)
	
	#Process the brush drawing stuff
	if (paint_canvas_node.mouse_in_region and paint_canvas_node.mouse_on_top) \
			or paint_canvas_node.preview_enabled:
		brush_process()
	
	#Render the highlighting stuff
	update()
	
	#Canvas Shift Moving
	if not mouse_position == last_mouse_position:
		if paint_canvas_node.has_focus():
			if Input.is_key_pressed(KEY_SHIFT):
				if Input.is_mouse_button_pressed(BUTTON_LEFT):
					var relative = mouse_position - last_mouse_position
					paint_canvas_node.rect_position += relative
				allow_drawing = false
			else:
				allow_drawing = true
	
	#Update last variables with the current variables
	last_mouse_position = mouse_position
	last_canvas_position = canvas_position
	last_canvas_mouse_position = canvas_mouse_position
	last_cell_mouse_position = cell_mouse_position
	last_cell_color = cell_color

var currently_selecting = false
func _draw():
	if paint_canvas_node == null:
		return
	if paint_canvas_node.mouse_in_region and paint_canvas_node.mouse_in_region:
		#draw cell_mouse_position
		if paint_canvas_node.cell_in_canvas_region(cell_mouse_position.x, cell_mouse_position.y):
			draw_rect(Rect2(Vector2(
					(cell_mouse_position.x * grid_size) + canvas_position.x, 
					(cell_mouse_position.y * grid_size) + canvas_position.y), 
					Vector2(grid_size, grid_size)), Color(0.8, 0.8, 0.8, 0.8), true)

func draw_outline_box(pos, size, color, width):
	#Top line
	draw_line(Vector2(0 + 1 + pos.x, 0 + pos.y), Vector2(pos.x + size.x, 0 + pos.y), color, width)
	#Left line
	draw_line(Vector2(0 + 1 + pos.x, 0 + pos.y), Vector2(0 + pos.x, pos.y + size.y), color, width)
	#Bottom line
	draw_line(Vector2(0 + 1 + pos.x, pos.y + size.y), Vector2(pos.x + size.x, pos.y + size.y), color, width)
	#Right line
	draw_line(Vector2(pos.x + size.x, 0 + pos.y), Vector2(pos.x + size.x, pos.y + size.y), color, width)

func pool_vector2_array_append_new_value(vec2array, vec2):
	for i in vec2array:
		if i == vec2:
			return
	vec2array.append(vec2)

func custom_rect_size_brush(x, y, color, size):
	for cx in range(x, x + size):
		for cy in range(y, y + size):
			paint_canvas_node.set_pixel_cell(cx, cy, color)
	pass


func _handle_cut():
	if Input.is_mouse_button_pressed(BUTTON_RIGHT):
		_just_cut = false
		_show_cut = false
		paint_canvas_node.preview_enabled = true
		paint_canvas_node.clear_layer("preview")
		brush_mode = _previous_tool
		paint_canvas_node.preview_enabled = false
		_selection = []
		return
	
	if Input.is_mouse_button_pressed(BUTTON_LEFT):
		for pixel_pos in paint_canvas_node.get_pixels_from_line(cell_mouse_position, last_cell_mouse_position):
			for pixel in _selection:
				var pos = pixel[0]
				pos -= _cut_pos
				pos += pixel_pos
				paint_canvas_node.set_pixel_cell_v(pos, pixel[1])
	else:
		if _last_preview_draw_cell_pos == cell_mouse_position:
			return
		paint_canvas_node.preview_enabled = true
		paint_canvas_node.clear_layer("preview")
		for pixel in _selection:
			var pos = pixel[0]
			pos -= _cut_pos
			pos += cell_mouse_position
			paint_canvas_node.set_pixel_cell_v(pos, pixel[1])
		paint_canvas_node.preview_enabled = false
		_last_preview_draw_cell_pos = cell_mouse_position


func brush_process():
	if not allow_drawing:
		return
	
	if _just_cut:
		_handle_cut()
		return
	if Input.is_mouse_button_pressed(BUTTON_LEFT):
		do_action(Actions[brush_mode], [cell_mouse_position, last_cell_mouse_position, selected_color])
		return
		match brush_mode:
			Tools.PAINT:
				paint_canvas_node.set_pixels_from_line(cell_mouse_position, last_cell_mouse_position, selected_color)
			Tools.BRUSH:
				for pixel_pos in paint_canvas_node.get_pixels_from_line(cell_mouse_position, last_cell_mouse_position):
					for off in BrushPrefabs.list[selected_brush_prefab]:
						paint_canvas_node.set_pixel_cell_v(pixel_pos + off, selected_color)
			Tools.LINE:
				paint_canvas_node.preview_enabled = true
				if _left_mouse_pressed_start_pos == Vector2.ZERO:
					_left_mouse_pressed_start_pos = cell_mouse_position
				paint_canvas_node.clear_layer("preview")
				paint_canvas_node.set_pixels_from_line(
						cell_mouse_position, _left_mouse_pressed_start_pos, selected_color)
			
			Tools.RECT:
				paint_canvas_node.preview_enabled = true
				if _left_mouse_pressed_start_pos == Vector2.ZERO:
					_left_mouse_pressed_start_pos = cell_mouse_position
				paint_canvas_node.clear_layer("preview")
				
				var p = _left_mouse_pressed_start_pos
				var s = cell_mouse_position - _left_mouse_pressed_start_pos
				
				paint_canvas_node.set_pixels_from_line(
						p, p + Vector2(s.x, 0), selected_color)
				paint_canvas_node.set_pixels_from_line(
						p, p + Vector2(0, s.y), selected_color)
				paint_canvas_node.set_pixels_from_line(
						p + s, p + s + Vector2(0, -s.y), selected_color)
				paint_canvas_node.set_pixels_from_line(
						p + s, p + s  + Vector2(-s.x, 0), selected_color)
				
			Tools.DARKEN:
				var pixels = paint_canvas_node.get_pixels_from_line(cell_mouse_position, last_cell_mouse_position)
				var val = 0.9
				for pixel in pixels:
					if _last_drawn_pixel == pixel:
						continue
					_last_drawn_pixel = pixel
					
					var new_color = paint_canvas_node.get_pixel_cell_color(pixel.x, pixel.y)
					new_color.r *= val
					new_color.g *= val
					new_color.b *= val
					paint_canvas_node.set_pixel_cell_v(pixel, new_color)
					
			Tools.BRIGHTEN:
				var pixels = paint_canvas_node.get_pixels_from_line(cell_mouse_position, last_cell_mouse_position)
				var val = 1.1
				for pixel in pixels:
					if _last_drawn_pixel == pixel:
						continue
					_last_drawn_pixel = pixel
						
					var new_color = paint_canvas_node.get_pixel_cell_color(pixel.x, pixel.y)
					new_color.r *= val
					new_color.g *= val
					new_color.b *= val
					paint_canvas_node.set_pixel_cell_v(pixel, new_color)
					
			Tools.COLORPICKER:
				change_color(paint_canvas_node.get_pixel_cell_color(cell_mouse_position.x, cell_mouse_position.y))
				
			Tools.CUT:
				paint_canvas_node.preview_enabled = true
				if _left_mouse_pressed_start_pos == Vector2.ZERO:
					_left_mouse_pressed_start_pos = cell_mouse_position
				paint_canvas_node.clear_layer("preview")
				
				var p = _left_mouse_pressed_start_pos
				var s = cell_mouse_position - _left_mouse_pressed_start_pos
				
				var selection_color = Color(0.8, 0.8, 0.8, 0.5)
				
				paint_canvas_node.set_pixels_from_line(
						p, p + Vector2(s.x, 0), selection_color)
				paint_canvas_node.set_pixels_from_line(
						p, p + Vector2(0, s.y), selection_color)
				paint_canvas_node.set_pixels_from_line(
						p + s, p + s + Vector2(0, -s.y), selection_color)
				paint_canvas_node.set_pixels_from_line(
						p + s, p + s  + Vector2(-s.x, 0), selection_color)
				
			Tools.BUCKET:
				paint_canvas_node.flood_fill(cell_mouse_position.x, cell_mouse_position.y, cell_color, selected_color)
			Tools.RAINBOW:
				paint_canvas_node.set_random_pixels_from_line(cell_mouse_position, last_cell_mouse_position)
			_:
				print("no brush selected")
#				paint_canvas_node.set_pixels_from_line(cell_mouse_position, last_cell_mouse_position, selected_color)
	elif Input.is_mouse_button_pressed(BUTTON_RIGHT):
		match brush_mode:
			Tools.PAINT:
				paint_canvas_node.set_pixels_from_line(cell_mouse_position, last_cell_mouse_position, Color(0, 0, 0, 0))
#			Tools.BUCKET:
#				paint_canvas_node.flood_fill(cell_mouse_position.x, cell_mouse_position.y, cell_color, Color(0, 0, 0, 0))
			Tools.BRUSH:
				for pixel_pos in paint_canvas_node.get_pixels_from_line(cell_mouse_position, last_cell_mouse_position):
					for off in BrushPrefabs.list[selected_brush_prefab]:
						paint_canvas_node.set_pixel_cell_v(pixel_pos + off, Color(0, 0, 0, 0))
			Tools.RAINBOW:
				paint_canvas_node.set_pixels_from_line(cell_mouse_position, last_cell_mouse_position, Color(0, 0, 0, 0))
			_:
				paint_canvas_node.set_pixels_from_line(cell_mouse_position, last_cell_mouse_position, Color(0, 0, 0, 0))
	
	if paint_canvas_node.preview_enabled:
		if not Input.is_mouse_button_pressed(BUTTON_LEFT):
			match brush_mode:
				Tools.LINE:
					paint_canvas_node.clear_layer("preview")
					paint_canvas_node.preview_enabled = false
					paint_canvas_node.set_pixels_from_line(
							cell_mouse_position, _left_mouse_pressed_start_pos, selected_color)
					_left_mouse_pressed_start_pos = Vector2.ZERO
					
				Tools.RECT:
					paint_canvas_node.clear_layer("preview")
					paint_canvas_node.preview_enabled = false
					
					var p = _left_mouse_pressed_start_pos
					var s = cell_mouse_position - _left_mouse_pressed_start_pos
					
					paint_canvas_node.set_pixels_from_line(
							p, p + Vector2(s.x, 0), selected_color)
					paint_canvas_node.set_pixels_from_line(
							p, p + Vector2(0, s.y), selected_color)
					paint_canvas_node.set_pixels_from_line(
							p + s, p + s + Vector2(0, -s.y), selected_color)
					paint_canvas_node.set_pixels_from_line(
							p + s, p + s  + Vector2(-s.x, 0), selected_color)
					_left_mouse_pressed_start_pos = Vector2.ZERO
					
				Tools.CUT:
					paint_canvas_node.clear_layer("preview")
					paint_canvas_node.preview_enabled = false
					
					var p = _left_mouse_pressed_start_pos
					var s = cell_mouse_position - _left_mouse_pressed_start_pos
					_cut_pos = p + s / 2
					_cut_size = s
					
					for x in range(abs(s.x)+1):
						for y in range(abs(s.y)+1):
							var px = x
							var py = y
							if s.x < 0:
								px *= -1
							if s.y < 0:
								py *= -1
							
							var pos = p + Vector2(px, py)
							var color = paint_canvas_node.get_pixel_cell_color(pos.x, pos.y)
							if color.a == 0:
								continue
							_selection.append([pos, color])
							paint_canvas_node.set_pixel_cell_v(pos, Color.transparent)
					_left_mouse_pressed_start_pos = Vector2.ZERO
					_just_cut = true
					paint_canvas_node.preview_enabled = true


func update_text_info():
	var text = ""
	
	var cell_color_text = cell_color
#	if paint_canvas_node.mouse_in_region and paint_canvas_container_node.mouse_on_top:
#		if Input.is_mouse_button_pressed(BUTTON_LEFT) or Input.is_mouse_button_pressed(BUTTON_RIGHT):
#			if paint_canvas_node.last_pixel.size() > 0:
#				cell_color_text = paint_canvas_node.last_pixel[2]
	cell_color_text = Color(0, 0, 0, 0)
	
	text += \
	str("FPS %s\t" + \
	"Mouse Position %s\t" + \
	"Canvas Mouse Position %s \t" + \
	"Canvas Position %s\t\n" + \
	"Cell Position %s \t" + \
	"Cell Color %s\t" + \
	"Cell Region %s \t" + \
	"Cell Position %s\t") % [
		str(Engine.get_frames_per_second()),
		str(mouse_position),
		str(canvas_mouse_position),
		str(canvas_position),
		str(cell_mouse_position),
		str(cell_color_text),
		str(cell_region_position),
		str(cell_position_in_region),
	]
	
	find_node("DebugTextDisplay").display_text(text)


func select_layer(layer_name: String):
	print("select layer: ", layer_name)
	paint_canvas_node.active_layer = layer_name


func _on_Save_pressed():
	get_node("SaveFileDialog").show()



#---------------------------------------
# Actions
#---------------------------------------


func do_action(action, data: Array):
	_actions_history.push_back(action)
	action.do_action(data)
	_redo_history.clear()


func redo_action():
	pass


func undo_action():
	var action = _actions_history.pop_back()
	_redo_history.append(action)
	action.undo_action()


#---------------------------------------
# Brushes
#---------------------------------------


func set_brush(new_mode):
	if brush_mode == new_mode:
		return
	_previous_tool = brush_mode
	brush_mode = new_mode


func change_color(new_color):
	if new_color.a == 0:
		return
	selected_color = new_color
	find_node("ColorPicker").color = selected_color


func _on_ColorPicker_color_changed(color):
	selected_color = color


func _on_PaintTool_pressed():
	brush_mode = Tools.PAINT


func _on_BucketTool_pressed():
	brush_mode = Tools.BUCKET


func _on_RainbowTool_pressed():
	set_brush(Tools.RAINBOW)


func _on_BrushTool_pressed():
	var prev_mode = brush_mode 
	set_brush(Tools.BRUSH)
	if prev_mode != brush_mode:
		return
	selected_brush_prefab += 1 
	selected_brush_prefab = selected_brush_prefab % BrushPrefabs.list.size()
	var value = float(selected_brush_prefab) / BrushPrefabs.list.size()
	
	find_node("BrushTool").get("custom_styles/normal").set("bg_color", Color(value, value, value, 1.0))


func _on_LineTool_pressed():
	set_brush(Tools.LINE)


func _on_RectTool_pressed():
	set_brush(Tools.RECT)


func _on_DarkenTool_pressed():
	set_brush(Tools.DARKEN)


func _on_BrightenTool_pressed():
	set_brush(Tools.BRIGHTEN)


func _on_ColorPickerTool_pressed():
	set_brush(Tools.COLORPICKER)


func _on_CutTool_pressed():
	set_brush(Tools.CUT)


func _on_Editor_visibility_changed():
	pause_mode = not visible


func _connect_layer_buttons():
	for layer_btn in get_tree().get_nodes_in_group("layer"):
		if layer_btn.is_connected("pressed", self, "select_layer"):
			continue
		layer_btn.connect("pressed", self, "select_layer", [get_layer_by_button_name(layer_btn.name)])
		layer_btn.find_node("Visible").connect("pressed", self, "toggle_layer_visibility", 
				[layer_btn.find_node("Visible"), get_layer_by_button_name(layer_btn.name)])
		layer_btn.find_node("Up").connect("pressed", self, "move_up", [layer_btn])
		layer_btn.find_node("Down").connect("pressed", self, "move_down", [layer_btn])


func toggle_layer_visibility(button, layer_name: String):
	print("toggling: ", layer_name)
	print(paint_canvas_node.layers.keys())
	paint_canvas_node.toggle_layer_visibility(layer_name)


func add_new_layer():
	var layers = get_tree().get_nodes_in_group("layer")
	var new_layer = layers.back().duplicate()
	find_node("Layers").add_child_below_node(layers.back(), new_layer, true)
	_total_added_layers += 1
	new_layer.text = "Layer " + str(_total_added_layers)
	
	var new_layer_name = paint_canvas_node.add_new_layer(new_layer.name) 
	
	_layer_button_ref[new_layer_name] = new_layer
	
	_connect_layer_buttons()
	
	print("added layer: ", new_layer_name, "(total:", layers.size(), ")")


func remove_active_layer():
	if _layer_button_ref.size() < 2:
		return
	
	_layer_button_ref[paint_canvas_node.active_layer].get_parent().remove_child(_layer_button_ref[paint_canvas_node.active_layer])
	_layer_button_ref[paint_canvas_node.active_layer].queue_free()
	_layer_button_ref.erase(paint_canvas_node.active_layer)
	paint_canvas_node.remove_layer(paint_canvas_node.active_layer)


func duplicate_active_layer():
	# copy the last layer button (or the initial one)
	var layer_buttons = get_tree().get_nodes_in_group("layer")
	var new_layer_button = layer_buttons.back().duplicate()
	find_node("Layers").add_child_below_node(layer_buttons.back(), new_layer_button, true)
	
	_total_added_layers += 1 # for keeping track...
	new_layer_button.text = "Layer " + str(_total_added_layers)
	
	var new_layer_name = paint_canvas_node.duplicate_layer(paint_canvas_node.active_layer, new_layer_button.name) 
	
	_layer_button_ref[new_layer_name] = new_layer_button
	
	_connect_layer_buttons()
	
	print("added layer: ", new_layer_name, " (total:", layer_buttons.size(), ")")


func get_layer_by_button_name(button_name: String):
	for layer_name in _layer_button_ref:
		var button = _layer_button_ref[layer_name]
		if button.name == button_name:
			return layer_name
	return null


func move_down(layer_btn, button_name: String):
	print("move_up: ", button_name)
	var layer_name = get_layer_by_button_name(button_name)
	var chunk_node = paint_canvas_node.layers[layer_name].chunks
	chunk_node.get_parent().move_child(chunk_node, max(chunk_node.get_index() + 1, 0))
	layer_btn.get_parent().move_child(layer_btn, max(layer_btn.get_index() + 1, 0))


func move_up(layer_btn, button_name: String):
	print("move_up: ", button_name)
	var layer_name = get_layer_by_button_name(button_name)
	var chunk_node = paint_canvas_node.layers[layer_name].chunks
	chunk_node.get_parent().move_child(chunk_node,
			min(chunk_node.get_index() - 1, chunk_node.get_parent().get_child_count() - 1))
	layer_btn.get_parent().move_child(layer_btn,
			min(layer_btn.get_index() - 1, layer_btn.get_parent().get_child_count() - 1))


func _on_Button_pressed():
	add_new_layer()



