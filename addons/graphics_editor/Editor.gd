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

var layer_buttons: Control
var paint_canvas_container_node
var paint_canvas: GECanvas
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

var _selection_cells = []
var _selection_colors = []

var _just_cut = false
var _show_cut = false
var _cut_pos = Vector2.ZERO
var _cut_size = Vector2.ZERO

var _actions_history = [] # for undo
var _redo_history = []
var _current_action



func _enter_tree():
	#--------------------
	#Setup nodes
	#--------------------
	paint_canvas_container_node = find_node("PaintCanvasContainer")
	textinfo = find_node("DebugTextDisplay")
	selected_color = find_node("ColorPicker").color
	colors_grid = find_node("Colors")
	paint_canvas = get_node("Panel/VBoxContainer/HBoxContainer/PaintCanvasContainer/Canvas")
	layer_buttons = find_node("LayerButtons")
	
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
	_layer_button_ref[layer_buttons.get_child(0).name] = layer_buttons.get_child(0) #ugly
	_connect_layer_buttons()


func _input(event):
	if Input.is_key_pressed(KEY_Z):
		undo_action()
	elif Input.is_key_pressed(KEY_Y):
		print("Y")
	
	if (paint_canvas.mouse_in_region and paint_canvas.mouse_on_top):
		match brush_mode:
			Tools.BUCKET:
				if _current_action == null:
					_current_action = get_action()
				if event is InputEventMouseButton:
					if event.button_index == BUTTON_LEFT:
						if event.pressed:
							do_action([cell_mouse_position, last_cell_mouse_position, selected_color])


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


func _reset_cut_tool():
	_just_cut = false
	_show_cut = false
	_selection_cells.clear()
	_selection_colors.clear()


func _handle_cut():
	if Input.is_mouse_button_pressed(BUTTON_RIGHT):
		paint_canvas.clear_preview_layer()
		_reset_cut_tool()
		set_brush(_previous_tool)
		return
	
	if Input.is_mouse_button_pressed(BUTTON_LEFT):
		for pixel_pos in GEUtils.get_pixels_in_line(cell_mouse_position, last_cell_mouse_position):
			for idx in range(_selection_cells.size()):
				var pixel = _selection_cells[idx]
				var color = _selection_colors[idx]
				pixel -= _cut_pos 
				pixel += pixel_pos
				paint_canvas.set_pixel_v(pixel, color)
	else:
		if _last_preview_draw_cell_pos == cell_mouse_position:
			return
		paint_canvas.clear_preview_layer()
		for idx in range(_selection_cells.size()):
			var pixel = _selection_cells[idx]
			var color = _selection_colors[idx]
			pixel -= _cut_pos
			pixel += cell_mouse_position
			paint_canvas.set_preview_pixel_v(pixel, color)
		_last_preview_draw_cell_pos = cell_mouse_position


func brush_process():
	if _just_cut:
		_handle_cut()
		return
	
	if Input.is_mouse_button_pressed(BUTTON_LEFT):
		if _current_action == null:
			_current_action = get_action()
		
		match brush_mode:
			Tools.PAINT:
				do_action([cell_mouse_position, last_cell_mouse_position, selected_color])
			Tools.BRUSH:
				do_action([cell_mouse_position, last_cell_mouse_position, selected_color, selected_brush_prefab])
			Tools.LINE:
				do_action([cell_mouse_position, last_cell_mouse_position, selected_color])
			Tools.RECT:
				do_action([cell_mouse_position, last_cell_mouse_position, selected_color])
			Tools.DARKEN:
				do_action([cell_mouse_position, last_cell_mouse_position, selected_color])
			Tools.BRIGHTEN:
				do_action([cell_mouse_position, last_cell_mouse_position, selected_color])
			Tools.COLORPICKER:
				change_color(paint_canvas.get_pixel(cell_mouse_position.x, cell_mouse_position.y))
			Tools.CUT:
				do_action([cell_mouse_position, last_cell_mouse_position, selected_color])
			Tools.RAINBOW:
				do_action([cell_mouse_position, last_cell_mouse_position])
	else:
		if _current_action and _current_action.can_commit():
			commit_action()
	
	if Input.is_mouse_button_pressed(BUTTON_RIGHT):
		return
		if _current_action == null:
			_current_action = get_action()
		
		match brush_mode:
			Tools.PAINT:
				do_action([cell_mouse_position, last_cell_mouse_position, Color(0, 0, 0, 0)])
			Tools.BRUSH:
				do_action([cell_mouse_position, last_cell_mouse_position, Color(0, 0, 0, 0), selected_brush_prefab])


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
	var commit_data = _current_action.commit_action(paint_canvas)
	var action = get_action()
	action.action_data = _current_action.action_data.duplicate(true)
	
	_actions_history.push_back(action)
	
	match brush_mode:
		Tools.CUT:
			if _just_cut:
				continue
			_cut_pos = _current_action.mouse_start_pos
			_cut_size = _current_action.mouse_end_pos - _current_action.mouse_start_pos
			_selection_cells = _current_action.action_data.do.cells.duplicate()
			_selection_colors = _current_action.action_data.do.colors.duplicate()
			_just_cut = true
	
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
		Tools.LINE:
			return GELine.new()
		Tools.RAINBOW:
			return GERainbow.new()
		Tools.BUCKET:
			return GEBucket.new()
		Tools.RECT:
			return GERect.new()
		Tools.DARKEN:
			return GEDarken.new()
		Tools.BRIGHTEN:
			return GEBrighten.new()
		Tools.CUT:
			return GECut.new()
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
	
	match _previous_tool:
		Tools.CUT:
			paint_canvas.clear_preview_layer()
			_just_cut = false
		Tools.BUCKET:
			_current_action = null
	print("Selected: ", Tools.keys()[brush_mode])


func change_color(new_color):
	if new_color.a == 0:
		return
	selected_color = new_color
	find_node("ColorPicker").color = selected_color


func _on_ColorPicker_color_changed(color):
	selected_color = color


func _on_PaintTool_pressed():
	set_brush(Tools.PAINT)


func _on_BucketTool_pressed():
	set_brush(Tools.BUCKET)


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


#---------------------------------------
# Layer
#---------------------------------------

func toggle_layer_visibility(button, layer_name: String):
	print("toggling: ", layer_name)
	paint_canvas.toggle_layer_visibility(layer_name)


func select_layer(layer_name: String):
	print("select layer: ", layer_name)
	paint_canvas.select_layer(layer_name)


func add_new_layer():
	var new_layer = layer_buttons.get_child(0).duplicate()
	layer_buttons.add_child_below_node(layer_buttons.get_child(layer_buttons.get_child_count() - 1), new_layer, true)
	_total_added_layers += 1
	new_layer.text = "Layer " + str(_total_added_layers)
	
	var layer: GELayer = paint_canvas.add_new_layer(new_layer.name) 
	
	_layer_button_ref[new_layer.name] = new_layer
	
	_connect_layer_buttons()
	
	print("added layer: ", layer.name)


func remove_active_layer():
	if layer_buttons.get_child_count() <= 1:
		return
	var layer_name = paint_canvas.active_layer.name
	paint_canvas.remove_layer(layer_name)
	layer_buttons.remove_child(_layer_button_ref[layer_name])
	_layer_button_ref[layer_name].queue_free()
	_layer_button_ref.erase(layer_name)
	


func duplicate_active_layer():
	# copy the last layer button (or the initial one)
	
	var new_layer_button = layer_buttons.get_child(0).duplicate()
	layer_buttons.add_child_below_node(
			layer_buttons.get_child(layer_buttons.get_child_count() - 1), new_layer_button, true)
	
	_total_added_layers += 1 # for keeping track...
	new_layer_button.text = "Layer " + str(_total_added_layers)
	
	var new_layer = paint_canvas.duplicate_layer(paint_canvas.active_layer.name, new_layer_button.name) 
	
	_layer_button_ref[new_layer.name] = new_layer_button
	
	new_layer_button.disconnect("pressed", self, "select_layer")
	new_layer_button.find_node("Visible").disconnect("pressed", self, "toggle_layer_visibility")
	new_layer_button.find_node("Up").disconnect("pressed", self, "move_down")
	new_layer_button.find_node("Down").disconnect("pressed", self, "move_up")
	
	new_layer_button.connect("pressed", self, "select_layer", [new_layer_button.name])
	new_layer_button.find_node("Visible").connect("pressed", self, "toggle_layer_visibility", 
			[new_layer_button.find_node("Visible"), new_layer_button.name])
	new_layer_button.find_node("Up").connect("pressed", self, "move_down", [new_layer_button])
	new_layer_button.find_node("Down").connect("pressed", self, "move_up", [new_layer_button])
	
	print("added layer: ", new_layer.name, " (total:", layer_buttons.size(), ")")


func move_up(layer_btn):
	var new_idx = min(layer_btn.get_index() + 1, layer_buttons.get_child_count())
	print("move_down: ", layer_btn.name, " from ", layer_btn.get_index(), " to ", new_idx)
	layer_buttons.move_child(layer_btn, new_idx)
	paint_canvas.move_layer_back(layer_btn.name)


func move_down(layer_btn):
	var new_idx = max(layer_btn.get_index() - 1, 0)
	print("move_up: ", layer_btn.name, " from ", layer_btn.get_index(), " to ", new_idx)
	layer_buttons.move_child(layer_btn, new_idx)
	paint_canvas.move_layer_forward(layer_btn.name)


func _connect_layer_buttons():
	for layer_btn in layer_buttons.get_children():
		if layer_btn.is_connected("pressed", self, "select_layer"):
			continue
		layer_btn.connect("pressed", self, "select_layer", [layer_btn.name])
		layer_btn.find_node("Visible").connect("pressed", self, "toggle_layer_visibility", 
				[layer_btn.find_node("Visible"), layer_btn.name])
		layer_btn.find_node("Up").connect("pressed", self, "move_down", [layer_btn])
		layer_btn.find_node("Down").connect("pressed", self, "move_up", [layer_btn])


func _on_Button_pressed():
	add_new_layer()



