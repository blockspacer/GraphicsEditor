extends Control

var util = preload("res://addons/graphics_editor/Util.gd")

func _ready():
	var dialog_folder = get_script().resource_path.get_base_dir()
	var files = util.get_files_from_path(dialog_folder.plus_file("Dialogs"))
	for i in files:
		var file_name = util.get_file_name(i)
		if i.get_extension() == "tscn":
			var new_scene = load(i).instance()
			add_child(new_scene)

func show_dialog(dialog_name):
	var dialog_node = get_node_or_null(dialog_name)
	if dialog_node:
		dialog_node.set_anchors_preset(PRESET_CENTER)
		dialog_node.rect_position = Vector2((rect_size.x / 2) - (dialog_node.rect_size.x / 2), (rect_size.y / 2) - (dialog_node.rect_size.y / 2))
		dialog_node.show()
	else:
		push_error("Can't load dialog! Either missing node or file?")