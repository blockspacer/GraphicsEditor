tool
extends FileDialog

var canvas

var file_path = ""


func _enter_tree():
	canvas = get_parent().find_node("PaintCanvas")


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
	image.create(canvas.canvas_size.x, canvas.canvas_size.y, true, Image.FORMAT_RGBA8)
	image.lock()
	
	var preview_layer_chunk_node = canvas.get_preview_layer().chunks
	
	for chunks_node in canvas.get_node("ChunkNodes").get_children():
		
		if chunks_node.name == preview_layer_chunk_node.name:
			continue
		
		if not chunks_node.visible:
			continue
		
		for chunk in chunks_node.get_children():
			var chunk_name = chunk.name
			var chunk_name_split = chunk_name.split("-")
			var chunk_x = int(chunk_name_split[1])
			var chunk_y = int(chunk_name_split[2])
			var chunk_image = chunk.image.duplicate()
			chunk_image.lock()
			var chunk_image_size = chunk_image.get_size()
			for x in chunk_image_size.x:
				for y in chunk_image_size.y:
					var pixel_color = chunk_image.get_pixel(x, y)
					var global_cell_x = (chunk_x * canvas.region_size) + x
					var global_cell_y = (chunk_y * canvas.region_size) + y
					
					if image.get_height() <= global_cell_y:
						continue
					if image.get_width() <= global_cell_x:
						continue
					if global_cell_x > canvas.canvas_size.x:
						continue
					if global_cell_y > canvas.canvas_size.y:
						continue
					
					image.lock()
					var current_color = image.get_pixel(global_cell_x, global_cell_y)
					if current_color.a != 0:
						image.set_pixel(global_cell_x, global_cell_y, current_color.blend(pixel_color))
					else:
						image.set_pixel(global_cell_x, global_cell_y, pixel_color)
	image.unlock()
	image.save_png(file_path)

func _on_SaveFileDialog_about_to_show():
	invalidate()

func _on_SaveFileDialog_visibility_changed():
	invalidate()
