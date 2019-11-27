tool
extends Control

#TODO: Make the settings auto generate!

onready var editor = get_parent().get_parent()
onready var canvas_outline = editor.get_node("PaintCanvasContainer/ViewportContainer/Viewport/PaintCanvas/CanvasOutline")
onready var visual_grid_1 = editor.get_node("PaintCanvasContainer/ViewportContainer/Viewport/PaintCanvas/Grids/VisualGrid")
onready var visual_grid_2 = editor.get_node("PaintCanvasContainer/ViewportContainer/Viewport/PaintCanvas/Grids/VisualGrid2")
onready var scroll_container = get_node("ScrollContainer")

#{
#	"CATEGORY": {
#		"SETTINGNAME": {
#			"node": "PATHTONODE",
#			"valueMod": "VALUETOMODIFY",
#			"setterType": "SETTERTYPE"
#		}
#	}
#}

#ValueSetterType List:
#ColorPicker
#CheckButton
#SpinBox

var setting_storage = {
	"Canvas Outline": {
		"Enabled": {
			"node": canvas_outline,
			"valueMod": "visible",
			"setterType": "CheckBox"
		},
		"Color": {
			"node": canvas_outline,
			"valueMod": "color",
			"setterType": "ColorPicker"
		},
		"Width": {
			"node": canvas_outline,
			"valueMod": "width",
			"setterType": "SpinBox"
		}
	},
	"Grids": {
		"Grid1_Color": {
			"node": visual_grid_1,
			"valueMod": "color",
			"setterType": "ColorPicker"
		},
		"Grid1_Size": {
			"node": visual_grid_1,
			"valueMod": "grid_size",
			"setterType": "SpinBox"
		},
		"Grid2_Color": {
			"node": visual_grid_2,
			"valueMod": "color",
			"setterType": "ColorPicker"
		},
		"Grid2_Size": {
			"node": visual_grid_2,
			"valueMod": "grid_size",
			"setterType": "SpinBox"
		},
	}
}

#TODO: Instead of this current system, we can make a function type of system instead like this
#generate_category(name)
#generate_property(category_name, node, valueMod) # setterType is automatically detected from the property it gets from the node

func _ready():
	generate_category_container("Canvas Outline")
	generate_property_container("Canvas Outline", canvas_outline, "Enabled", "visible")
	generate_property_container("Canvas Outline", canvas_outline, "Color", "color")
	generate_property_container("Canvas Outline", canvas_outline, "Width", "width")
	generate_category_container("Grids")
	generate_property_container("Grids", visual_grid_1, "Grid1 Enabled", "visible")
	generate_property_container("Grids", visual_grid_1, "Grid1 Color", "color")
	generate_property_container("Grids", visual_grid_1, "Grid1 Size", "size")
	generate_property_container("Grids", visual_grid_2, "Grid2 Enabled", "visible")
	generate_property_container("Grids", visual_grid_2, "Grid2 Color", "color")
	generate_property_container("Grids", visual_grid_2, "Grid2 Size", "size")

func generate_settings():
	for i in setting_storage:
		generate_category_container(i)
		for j in setting_storage[i]:
			var valuemod = setting_storage[i][j]["valueMod"]
			var settertype = setting_storage[i][j]["setterType"]
			generate_property_container(i, j, valuemod, settertype)

func generate_category_container(category):
	var vboxContainer = VBoxContainer.new()
	vboxContainer.name = category
	var label = Label.new()
	label.text = category + ":"
	label.valign = Label.ALIGN_CENTER
	vboxContainer.add_child(label)
	var vboxPropertiesContainer = VBoxContainer.new()
	vboxPropertiesContainer.name = "VBoxContainer"
	vboxContainer.add_child(vboxPropertiesContainer)
	get_node("ScrollContainer/VBoxContainer").add_child(vboxContainer)

func generate_property_container(category, node, propertyname, valuemod):
	var hbox = HBoxContainer.new()
	hbox.rect_min_size = Vector2(scroll_container.rect_size.x, 20)
	hbox.name = propertyname
	hbox.add_constant_override("separation", 0)
	var label = Label.new()
	label.rect_min_size = Vector2(scroll_container.rect_size.x / 2, 20)
	label.text = propertyname.capitalize()
	label.align = Label.ALIGN_CENTER
	label.valign = Label.ALIGN_CENTER
	var settertypenode
	print(node, valuemod)
	var get_value = node.get(valuemod)
	match typeof(get_value):
		TYPE_INT:
			settertypenode = SpinBox.new()
			settertypenode.max_value = 9999
			settertypenode.value = get_value
			settertypenode.connect("value_changed", self, "on_setting_changed", [node, valuemod, settertypenode, "value"])
			pass
		TYPE_REAL:
			settertypenode = SpinBox.new()
			settertypenode.max_value = 9999
			settertypenode.value = get_value
			settertypenode.connect("value_changed", self, "on_setting_changed", [node, valuemod, settertypenode, "value"])
			pass
		TYPE_COLOR:
			settertypenode = ColorPickerButton.new()
			settertypenode.color = get_value
			settertypenode.connect("color_changed", self, "on_setting_changed", [node, valuemod, settertypenode, "color"])
			pass
		TYPE_VECTOR2:
			pass
		TYPE_BOOL:
			settertypenode = CheckBox.new()
			settertypenode.text = "On"
			settertypenode.pressed = get_value
			var styleboxflat = StyleBoxFlat.new()
			styleboxflat.bg_color = Color(0.254902, 0.254902, 0.254902)
			settertypenode.add_stylebox_override("normal", styleboxflat)
			settertypenode.add_stylebox_override("hover", styleboxflat)
			settertypenode.add_stylebox_override("pressed", styleboxflat)
			settertypenode.connect("pressed", self, "on_setting_changed", [null, node, valuemod, settertypenode, "pressed"])
			pass
#	match settertype:
#		"ColorPicker":
#			settertypenode = ColorPickerButton.new()
#		"CheckBox":
#			settertypenode = CheckBox.new()
#			settertypenode.text = "On"
#			var styleboxflat = StyleBoxFlat.new()
#			styleboxflat.bg_color = Color(0.254902, 0.254902, 0.254902)
#			settertypenode.add_stylebox_override("normal", styleboxflat)
#			settertypenode.add_stylebox_override("hover", styleboxflat)
#			settertypenode.add_stylebox_override("pressed", styleboxflat)
#		"SpinBox":
#			settertypenode = SpinBox.new()
	if settertypenode == null:
		push_error("Setter type not found! Returning! DEBUG_INFO: %s | %s | %s" % [node, node.name, typeof(get_value)])
		return
	settertypenode.rect_min_size = Vector2(scroll_container.rect_size.x / 2, 20)
	hbox.add_child(label)
	hbox.add_child(settertypenode)
	get_node("ScrollContainer/VBoxContainer/%s/VBoxContainer" % [category]).add_child(hbox)

func _on_Ok_pressed():
	hide()

func on_setting_changed(default_signal, node, value_to_get, setter, value_setter_get):
	var setter_new_value = setter.get(value_setter_get)
	node.set(value_to_get, setter_new_value)

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
