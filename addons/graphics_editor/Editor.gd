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
var paint_canvas
var grids_node
var colors_grid
var selected_color = Color(1, 1, 1, 1)
var util = preload("res://addons/graphics_editor/Util.gd")
var textinfo
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
var _current_action

enum Action {
	PAINT,
}


func _enter_tree():
	#--------------------
	#Setup nodes
	#--------------------
	paint_canvas_container_node = find_node("PaintCanvasContainer")
	textinfo = find_node("DebugTextDisplay")
	selected_color = find_node("ColorPicker").color
	colors_grid = find_node("Colors")
	paint_canvas = get_node("Panel/VBoxContainer/HBoxContainer/PaintCanvasContainer/Canvas")
	print(paint_canvas)
	set_process(true)
	
	#--------------------
	#connect nodes
	#--------------------
	if not colors_grid.is_connected("color_change_request", self, "change_color"):
		colors_grid.connect("color_change_request", self, "change_color")
	
	if not is_connected("visibility_changed", self, "_on_Editor_visibility_changed"):
		connect("visibility_changed", self, "_on_Editor_visibility_changed")


func _ready():
	set_brush(Tools.PAINT)


func _input(event):
	if Input.is_key_pressed(KEY_Z):
		undo_action()
	elif Input.is_key_pressed(KEY_Y):
		print("Y")
	


var brush_mode

var mouse_position = Vector2()
var canvas_position = Vector2()
var canvas_mouse_position = Vector2()
var cell_mouse_position = Vector2()
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
	if paint_canvas == null:
		#_check_variables()
		set_process(false)
		return
	
	#Update commonly used variables
	var grid_size = paint_canvas.pixel_size
	mouse_position = paint_canvas.get_local_mouse_position()
	canvas_position = paint_canvas_container_node.rect_position
	canvas_mouse_position = Vector2(mouse_position.x - canvas_position.x, mouse_position.y - canvas_position.y)
	cell_mouse_position = Vector2(floor(canvas_mouse_position.x / grid_size), floor(canvas_mouse_position.y / grid_size))
	cell_color = paint_canvas.get_pixel(cell_mouse_position.x, cell_mouse_position.y)
	
	if (paint_canvas.mouse_in_region and paint_canvas.mouse_on_top):
		brush_process()
	
	#Render the highlighting stuff
	update()
	
	#Canvas Shift Moving
	if not mouse_position == last_mouse_position:
		if paint_canvas.has_focus():
			if Input.is_key_pressed(KEY_SHIFT):
				if Input.is_mouse_button_pressed(BUTTON_LEFT):
					var relative = mouse_position - last_mouse_position
					paint_canvas.rect_position += relative
				allow_drawing = false
			else:
				allow_drawing = true
	
	#Update last variables with the current variables
	last_mouse_position = mouse_position
	last_canvas_position = canvas_position
	last_canvas_mouse_position = canvas_mouse_position
	last_cell_mouse_position = cell_mouse_position
	last_cell_color = cell_color


func _handle_cut():
	if Input.is_mouse_button_pressed(BUTTON_RIGHT):
		_just_cut = false
		_show_cut = false
		paint_canvas.clear_preview_layer()
		brush_mode = _previous_tool
		_selection = []
		return
	
#	if Input.is_mouse_button_pressed(BUTTON_LEFT):
#		for pixel_pos in paint_canvas.get_pixels_from_line(cell_mouse_position, last_cell_mouse_position):
#			for pixel in _selection:
#				var pos = pixel[0]
#				pos -= _cut_pos
#				pos += pixel_pos
#				paint_canvas.set_pixel_v(pos, pixel[1])
	else:
		if _last_preview_draw_cell_pos == cell_mouse_position:
			return
		paint_canvas.clear_preview_layer()
		for pixel in _selection:
			var pos = pixel[0]
			pos -= _cut_pos
			pos += cell_mouse_position
			paint_canvas.set_pixel_v(pos, pixel[1])
		_last_preview_draw_cell_pos = cell_mouse_position


func brush_process():
	if _just_cut:
		_handle_cut()
		return
	
	if Input.is_mouse_button_pressed(BUTTON_LEFT):
#		var arr = GEUtils.get_pixels_in_line(cell_mouse_position, last_cell_mouse_position)
#		paint_canvas.set_pixel_arr(arr, selected_color)
		
		
		if _current_action == null:
			_current_action = get_action()
		
		match brush_mode:
			Tools.PAINT:
				do_action([cell_mouse_position, last_cell_mouse_position, selected_color])
			Tools.BRUSH:
				do_action([cell_mouse_position, last_cell_mouse_position, selected_color, selected_brush_prefab])
		return
	else:
		if _current_action and _current_action.can_commit():
			commit_action()
	
	return
	if Input.is_mouse_button_pressed(BUTTON_LEFT):
		match brush_mode:
			Tools.PAINT:
				paint_canvas.set_pixel_arr(GEUtils.get_pixels_in_line(cell_mouse_position, last_cell_mouse_position), selected_color)
			Tools.BRUSH:
				for pixel_pos in GEUtils.get_pixels_in_line(cell_mouse_position, last_cell_mouse_position):
					for off in BrushPrefabs.list[selected_brush_prefab]:
						paint_canvas.set_pixel_v(pixel_pos + off, selected_color)
			Tools.LINE:
				if _left_mouse_pressed_start_pos == Vector2.ZERO:
					_left_mouse_pressed_start_pos = cell_mouse_position
				paint_canvas.clear_preview_layer()
				paint_canvas.set_pixels_from_line(
						cell_mouse_position, _left_mouse_pressed_start_pos, selected_color)
			
			Tools.RECT:
				if _left_mouse_pressed_start_pos == Vector2.ZERO:
					_left_mouse_pressed_start_pos = cell_mouse_position
				paint_canvas.clear_preview_layer()
				
				var p = _left_mouse_pressed_start_pos
				var s = cell_mouse_position - _left_mouse_pressed_start_pos
				
				paint_canvas.set_pixels_from_line(
						p, p + Vector2(s.x, 0), selected_color)
				paint_canvas.set_pixels_from_line(
						p, p + Vector2(0, s.y), selected_color)
				paint_canvas.set_pixels_from_line(
						p + s, p + s + Vector2(0, -s.y), selected_color)
				paint_canvas.set_pixels_from_line(
						p + s, p + s  + Vector2(-s.x, 0), selected_color)
				
			Tools.DARKEN:
				var pixels = paint_canvas.get_pixels_from_line(cell_mouse_position, last_cell_mouse_position)
				var val = 0.9
				for pixel in pixels:
					if _last_drawn_pixel == pixel:
						continue
					_last_drawn_pixel = pixel
					
					var new_color = paint_canvas.get_pixel_cell_color(pixel.x, pixel.y)
					new_color.r *= val
					new_color.g *= val
					new_color.b *= val
					paint_canvas.set_pixel_v(pixel, new_color)
					
			Tools.BRIGHTEN:
				var pixels = paint_canvas.get_pixels_from_line(cell_mouse_position, last_cell_mouse_position)
				var val = 1.1
				for pixel in pixels:
					if _last_drawn_pixel == pixel:
						continue
					_last_drawn_pixel = pixel
						
					var new_color = paint_canvas.get_pixel_cell_color(pixel.x, pixel.y)
					new_color.r *= val
					new_color.g *= val
					new_color.b *= val
					paint_canvas.set_pixel_v(pixel, new_color)
					
			Tools.COLORPICKER:
				change_color(paint_canvas.get_pixel_cell_color(cell_mouse_position.x, cell_mouse_position.y))
				
			Tools.CUT:
				if _left_mouse_pressed_start_pos == Vector2.ZERO:
					_left_mouse_pressed_start_pos = cell_mouse_position
				paint_canvas.clear_preview_layer()
				
				var p = _left_mouse_pressed_start_pos
				var s = cell_mouse_position - _left_mouse_pressed_start_pos
				
				var selection_color = Color(0.8, 0.8, 0.8, 0.5)
				
				paint_canvas.set_pixels_from_line(
						p, p + Vector2(s.x, 0), selection_color)
				paint_canvas.set_pixels_from_line(
						p, p + Vector2(0, s.y), selection_color)
				paint_canvas.set_pixels_from_line(
						p + s, p + s + Vector2(0, -s.y), selection_color)
				paint_canvas.set_pixels_from_line(
						p + s, p + s  + Vector2(-s.x, 0), selection_color)
				
			Tools.BUCKET:
				paint_canvas.flood_fill(cell_mouse_position.x, cell_mouse_position.y, cell_color, selected_color)
			Tools.RAINBOW:
				paint_canvas.set_random_pixels_from_line(cell_mouse_position, last_cell_mouse_position)
			_:
				print("no brush selected")
#				paint_canvas.set_pixels_from_line(cell_mouse_position, last_cell_mouse_position, selected_color)
	
	else:
		if _current_action and _current_action.can_commit():
			commit_action()
	
	if Input.is_mouse_button_pressed(BUTTON_RIGHT):
		return
		
		match brush_mode:
			Tools.PAINT:
				paint_canvas.set_pixels_from_line(cell_mouse_position, last_cell_mouse_position, Color(0, 0, 0, 0))
#			Tools.BUCKET:
#				paint_canvas.flood_fill(cell_mouse_position.x, cell_mouse_position.y, cell_color, Color(0, 0, 0, 0))
			Tools.BRUSH:
				for pixel_pos in paint_canvas.get_pixels_from_line(cell_mouse_position, last_cell_mouse_position):
					for off in BrushPrefabs.list[selected_brush_prefab]:
						paint_canvas.set_pixel_v(pixel_pos + off, Color(0, 0, 0, 0))
			Tools.RAINBOW:
				paint_canvas.set_pixels_from_line(cell_mouse_position, last_cell_mouse_position, Color(0, 0, 0, 0))
			_:
				paint_canvas.set_pixels_from_line(cell_mouse_position, last_cell_mouse_position, Color(0, 0, 0, 0))
	
	if not Input.is_mouse_button_pressed(BUTTON_LEFT):
		match brush_mode:
			Tools.LINE:
				paint_canvas.clear_preview_layer()
				paint_canvas.set_pixels_from_line(
						cell_mouse_position, _left_mouse_pressed_start_pos, selected_color)
				_left_mouse_pressed_start_pos = Vector2.ZERO
				
			Tools.RECT:
				paint_canvas.clear_preview_layer()
				
				var p = _left_mouse_pressed_start_pos
				var s = cell_mouse_position - _left_mouse_pressed_start_pos
				
				paint_canvas.set_pixels_from_line(
						p, p + Vector2(s.x, 0), selected_color)
				paint_canvas.set_pixels_from_line(
						p, p + Vector2(0, s.y), selected_color)
				paint_canvas.set_pixels_from_line(
						p + s, p + s + Vector2(0, -s.y), selected_color)
				paint_canvas.set_pixels_from_line(
						p + s, p + s  + Vector2(-s.x, 0), selected_color)
				_left_mouse_pressed_start_pos = Vector2.ZERO
				
			Tools.CUT:
				paint_canvas.clear_preview_layer()
				
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
						var color = paint_canvas.get_pixel_cell_color(pos.x, pos.y)
						if color.a == 0:
							continue
						_selection.append([pos, color])
						paint_canvas.set_pixel_v(pos, Color.transparent)
				_left_mouse_pressed_start_pos = Vector2.ZERO
				_just_cut = true


func update_text_info():
	var text = ""
	
	var cell_color_text = cell_color
	cell_color_text = Color(0, 0, 0, 0)
	
	text += \
	str("FPS %s\t" + \
	"Mouse Position %s\t" + \
	"Canvas Mouse Position %s \t" + \
	"Canvas Position %s\t\n" + \
	"Cell Position %s \t" + \
	"Cell Color %s\t") % [
		str(Engine.get_frames_per_second()),
		str(mouse_position),
		str(canvas_mouse_position),
		str(canvas_position),
		str(cell_mouse_position),
		str(cell_color_text),
	]
	
	find_node("DebugTextDisplay").display_text(text)


func select_layer(layer_name: String):
	print("select layer: ", layer_name)


func _on_Save_pressed():
	get_node("SaveFileDialog").show()



#---------------------------------------
# Actions
#---------------------------------------


func do_action(data: Array):
	if _current_action == null:
		_redo_history.clear()
	_current_action.do_action(paint_canvas, data)


func commit_action():
	if not _current_action:
		return
	
	print("commit action")
	_current_action.commit_action(paint_canvas)
	var action = get_action()
	action.action_data = _current_action.action_data.duplicate(true)
	_actions_history.push_back(action)
	_current_action = null
	return
	action.action_data = _current_action.action_data
	if not "action_data" in action:
		print(action.get_class())
		return
	_current_action = null


func redo_action():
	pass


func undo_action():
	var action = _actions_history.pop_back()
	if not action:
		return 
	action.undo_action(paint_canvas)
	print("undo action")


func get_action():
	match brush_mode:
		Tools.PAINT:
			return GEPencil.new()
		Tools.BRUSH:
			return GEBrush.new()
		_:
			print("no tool!")
			return null


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
	print(paint_canvas.layers.keys())
	paint_canvas.toggle_layer_visibility(layer_name)


func add_new_layer():
	var layers = get_tree().get_nodes_in_group("layer")
	var new_layer = layers.back().duplicate()
	find_node("Layers").add_child_below_node(layers.back(), new_layer, true)
	_total_added_layers += 1
	new_layer.text = "Layer " + str(_total_added_layers)
	
	var new_layer_name = paint_canvas.add_new_layer(new_layer.name) 
	
	_layer_button_ref[new_layer_name] = new_layer
	
	_connect_layer_buttons()
	
	print("added layer: ", new_layer_name, "(total:", layers.size(), ")")


func remove_active_layer():
	if _layer_button_ref.size() < 2:
		return
	
	_layer_button_ref[paint_canvas.active_layer].get_parent().remove_child(_layer_button_ref[paint_canvas.active_layer])
	_layer_button_ref[paint_canvas.active_layer].queue_free()
	_layer_button_ref.erase(paint_canvas.active_layer)
	paint_canvas.remove_layer(paint_canvas.active_layer)


func duplicate_active_layer():
	# copy the last layer button (or the initial one)
	var layer_buttons = get_tree().get_nodes_in_group("layer")
	var new_layer_button = layer_buttons.back().duplicate()
	find_node("Layers").add_child_below_node(layer_buttons.back(), new_layer_button, true)
	
	_total_added_layers += 1 # for keeping track...
	new_layer_button.text = "Layer " + str(_total_added_layers)
	
	var new_layer_name = paint_canvas.duplicate_layer(paint_canvas.active_layer, new_layer_button.name) 
	
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
	var chunk_node = paint_canvas.layers[layer_name].chunks
	chunk_node.get_parent().move_child(chunk_node, max(chunk_node.get_index() + 1, 0))
	layer_btn.get_parent().move_child(layer_btn, max(layer_btn.get_index() + 1, 0))


func move_up(layer_btn, button_name: String):
	print("move_up: ", button_name)
	var layer_name = get_layer_by_button_name(button_name)
	var chunk_node = paint_canvas.layers[layer_name].chunks
	chunk_node.get_parent().move_child(chunk_node,
			min(chunk_node.get_index() - 1, chunk_node.get_parent().get_child_count() - 1))
	layer_btn.get_parent().move_child(layer_btn,
			min(layer_btn.get_index() - 1, layer_btn.get_parent().get_child_count() - 1))


func _on_Button_pressed():
	add_new_layer()



