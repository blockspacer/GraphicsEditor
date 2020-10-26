tool
extends FileDialog

var canvas

var file_path = ""


func _enter_tree():
	canvas = get_parent().get_node("Panel/VBoxContainer/HBoxContainer/PaintCanvasContainer/Canvas")


func _ready():
	# warning-ignore:return_value_discarded
	get_line_edit().connect("text_entered", self, "_on_LineEdit_text_entered")
	invalidate()
	clear_filters()
	add_filter("*.png ; PNG Images")


func _on_SaveFileDialog_file_selected(path):
	file_path = path


# warning-ignore:unused_argument
func _on_LineEdit_text_entered(text):
	save_file()


func _on_SaveFileDialog_confirmed():
	save_file()


func save_file():
	var image = Image.new()
	image.create(canvas.canvas_width, canvas.canvas_height, true, Image.FORMAT_RGBA8)
	image.lock()
	
	for layer_name in canvas.layers:
		var layer = canvas.layers[layer_name]
		var idx = 0
		for color in layer.pixels:
			var pos = GEUtils.to_2D(idx, canvas.canvas_width)
			idx += 1
			
			image.lock()
			var current_color = image.get_pixel(pos.x, pos.y)
			if current_color.a != 0:
				image.set_pixel(pos.x, pos.y, current_color.blend(color))
			else:
				image.set_pixel(pos.x, pos.y, color)
	image.unlock()
	image.save_png(file_path)


func _on_SaveFileDialog_about_to_show():
	invalidate()


func _on_SaveFileDialog_visibility_changed():
	invalidate()
