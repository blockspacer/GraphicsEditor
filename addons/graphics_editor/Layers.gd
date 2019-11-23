tool
extends Control

onready var canvas = get_node("../../PaintCanvasContainer/ViewportContainer/Viewport/PaintCanvas")
onready var layer_list = get_node("Panel/ScrollContainer/VBoxContainer")
var layer_scene = preload("res://addons/graphics_editor/Layer.tscn")
var active_layer setget set_active_layer

func _ready():
	if layer_list.get_children().size() <= 0:
		add_new_layer(true)

func _process(delta):
	var active_node = get_node_or_null("Panel/ScrollContainer/VBoxContainer/%s" % [active_layer])
	if active_node:
		active_node.image_storage = canvas.image.duplicate()
	canvas.image_pixel_array = get_all_layer_images()
	pass

func set_active_layer(new_layer):
	if active_layer:
		var cur_node = get_node_or_null("Panel/ScrollContainer/VBoxContainer/%s" % [active_layer])
		if cur_node:
			cur_node.get_node("Panel").modulate = Color(0.117647, 0.117647, 0.117647)
	active_layer = new_layer
	var new_node = get_node_or_null("Panel/ScrollContainer/VBoxContainer/%s" % [new_layer])
	if new_node and new_node.image_storage:
		new_node.get_node("Panel").modulate = Color(0.156863, 0.156863, 0.156863)
		canvas.load_image(new_node.image_storage)

func get_all_layer_images():
	var array = []
	for i in layer_list.get_children():
		if i.layer_visible:
			array.append(i.image_storage)
	return array

func increase_number_string(array, name_string, cur_int = 1):
	for i in array:
		if i == "%s %s" % [name_string, cur_int]:
			cur_int += 1
	return "%s %s" % [name_string, cur_int]

func _on_AddLayer_pressed():
	add_new_layer()

func add_new_layer(is_active = false):
	var get_children_name = PoolStringArray()
	for i in layer_list.get_children():
		get_children_name.append(i.name)
	var new_node_name = increase_number_string(get_children_name, "New Layer")
	var new_layer_node = layer_scene.instance()
	new_layer_node.get_node("Name").text = new_node_name
	new_layer_node.name = new_node_name
	layer_list.add_child(new_layer_node)
	if is_active:
		set_active_layer(new_node_name)

func remove_layer(layer_name):
	if layer_list.get_children().size() <= 1:
		print("There needs to be an active layer always!")
		return
	var node_to_remove = layer_list.get_node_or_null(layer_name)
	if node_to_remove:
		node_to_remove.queue_free()