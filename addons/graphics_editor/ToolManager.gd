tool
extends Node

var active_tool

func _ready():
	pass

func set_active_tool(tool_to_use):
	var tool_manager_folder = get_script().resource_path.get_base_dir()
	var tool_scripts = get_files_from_path(tool_manager_folder.plus_file("Tools"))
	for i in tool_scripts:
		var file_name_raw = i.get_file()
		var file_extension = i.get_extension()
		var file_name = file_name_raw.substr(0, file_name_raw.length()-(file_extension.length()+1))
		if file_name == tool_to_use:
			var node = Node.new()
			node.name = file_name
			var script_file = load(i)
			node.set_script(script_file)
			add_child(node)
			active_tool = node
			return node
	push_error("Can't find tool from script files! Either file missing or wrong name?")

func get_active_tool():
	return active_tool

func get_files_from_path(path):
	var script_array = PoolStringArray()
	var dir = Directory.new()
	if dir.open(path) == OK:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while (file_name != ""):
			if !dir.current_is_dir():
				script_array.append(path.plus_file(file_name))
			file_name = dir.get_next()
	return script_array
