tool
extends Node

class time_debug:
	var start_time = 0.0
	var end_time = 0.0
	
	func start():
		start_time = OS.get_ticks_msec()
		return start_time
	
	func end():
		end_time = OS.get_ticks_msec()
		return end_time
	
	func get_time_passed():
		return end_time - start_time

static func color_from_array(color_array):
	var r = color_array[0]
	var g = color_array[1]
	var b = color_array[2]
	var a = color_array[3]
	return Color(r, g, b, a)

static func random_color():
	return Color(randf(), randf(), randf())

static func random_color_alt():
	var rand = randi() % 6
	
	match rand:
		0:
			return Color.red
		1:
			return Color.blue
		2:
			return Color.green
		3:
			return Color.orange
		4:
			return Color.yellow
		5:
			return Color.purple

static func get_line_string(file, number):
	return file.get_as_text().split("\n")[number - 1].strip_edges()

static func get_file_name(path):
	var file_name_raw = path.get_file()
	var file_extension = path.get_extension()
	var file_name = file_name_raw.substr(0, file_name_raw.length()-(file_extension.length()+1))
	return file_name

static func get_files_from_path(path):
	var file_array = PoolStringArray()
	var dir = Directory.new()
	if dir.open(path) == OK:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while (file_name != ""):
			if !dir.current_is_dir():
				file_array.append(path.plus_file(file_name))
			file_name = dir.get_next()
	return file_array

static func printv(variable):
	var stack = get_stack()[get_stack().size() - 1]
	var line = stack.line
	var source = stack.source
	var file = File.new()
	file.open(source, File.READ)
	var line_string = get_line_string(file, line)
	file.close()
	var left_p = line_string.find("(")
	var left_p_string = line_string.right(left_p + 1)
	var right_p = left_p_string.find(")")
	var variable_name = left_p_string.left(right_p)
	print("%s: %s" % [variable_name, variable])
