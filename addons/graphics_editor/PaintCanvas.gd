tool
extends Control

export var grid_size = 16 setget resize_grid
export var canvas_size = Vector2(100, 100) setget resize_canvas
export var chunk_size = Vector2(10, 10)
export var can_draw = true
onready var canvas_node = get_node("CanvasImage")
onready var util = get_node("Util")

var mouse_in_region
var last_pixel_drawn = []
var image = Image.new()
var image_render = Image.new()
var image_texture = ImageTexture.new()
signal grid_resized
signal canvas_resized

func _ready():
	image.create(canvas_size.x, canvas_size.y, true, Image.FORMAT_RGBA8)
	image_render.create(canvas_size.x, canvas_size.y, true, Image.FORMAT_RGBA8)
	rect_min_size = Vector2(canvas_size.x * grid_size, canvas_size.y * grid_size)
	rect_size = Vector2(canvas_size.x * grid_size, canvas_size.y * grid_size)
	canvas_node.rect_min_size = Vector2(canvas_size.x * grid_size, canvas_size.y * grid_size)
	canvas_node.rect_size = Vector2(canvas_size.x * grid_size, canvas_size.y * grid_size)
	image.lock()
	image_render.lock()

func _process(delta):
	update_canvas()

#----------------------
#---SETGET FUNCTIONS---
#----------------------

func resize_grid(new_size):
	grid_size = new_size
	if canvas_node:
		#generate_chunks()
		rect_min_size = Vector2(canvas_size.x * new_size, canvas_size.y * new_size)
		rect_size = Vector2(canvas_size.x * new_size, canvas_size.y * new_size)
		canvas_node.rect_min_size = Vector2(canvas_size.x * new_size, canvas_size.y * new_size)
		canvas_node.rect_size = Vector2(canvas_size.x * new_size, canvas_size.y * new_size)
		emit_signal("grid_resized", new_size)

func resize_canvas(new_size):
	canvas_size = new_size
	if canvas_node:
		image.unlock()
		image = Image.new()
		image.create(canvas_size.x, canvas_size.y, true, Image.FORMAT_RGBA8)
		image.lock()
		image_render.unlock()
		image_render.create(canvas_size.x, canvas_size.y, true, Image.FORMAT_RGBA8)
		image_render.lock()
		rect_min_size = Vector2(new_size.x * grid_size, new_size.y * grid_size)
		rect_size = Vector2(new_size.x * grid_size, new_size.y * grid_size)
		canvas_node.rect_min_size = Vector2(new_size.x * grid_size, new_size.y * grid_size)
		canvas_node.rect_size = Vector2(new_size.x * grid_size, new_size.y * grid_size)
		emit_signal("canvas_resized", new_size)

#---------------------
#---CHUNK FUNCTIONS---
#---------------------

func spawn_chunk(pos):
	pass

func update_chunk(pos):
	pass

func get_chunk_from_pixel(pos):
	pass

func set_chunk(pos):
	pass

func remove_chunk(pos):
	pass

func generate_chunks():
	pass

#---------------------
#---PIXEL FUNCTIONS---
#---------------------

func get_pixel(pos):
	if not pixel_in_canvas_region(pos):
		return null
	
	return image.get_pixelv(pos)

func set_pixel(pos, color):
	if not pixel_in_canvas_region(pos):
		return null
	
	last_pixel_drawn = [pos, color]
	return image.set_pixelv(pos, color)

func pixel_in_canvas_region(pos):
	if pos.x < canvas_size.x and pos.x > -1 and pos.y < canvas_size.y and pos.y > -1:
		return true
	return false

#--------------------
#--Canvas Rendering--
#--------------------

var image_pixel_array = []
func update_canvas():
	image_render.fill(Color(0, 0, 0, 0))
	for i in image_pixel_array:
		image_render.blend_rect(i, Rect2(Vector2.ZERO, canvas_size), Vector2.ZERO)
	image_texture.create_from_image(image_render)
	image_texture.set_flags(0)
	if canvas_node:
		canvas_node.texture = image_texture

#---------------------
#---IMAGE FUNCTIONS---
#---------------------

func load_image(image_data):
	var array_data = image_data_to_array(image_data)
	image.unlock()
	image.create(canvas_size.x, canvas_size.y, true, Image.FORMAT_RGBA8)
	image.lock()
	image_render.unlock()
	image_render.create(canvas_size.x, canvas_size.y, true, Image.FORMAT_RGBA8)
	image_render.lock()
	set_pixels_from_array(array_data)
	rect_min_size = Vector2(canvas_size.x * grid_size, canvas_size.y * grid_size)
	rect_size = Vector2(canvas_size.x * grid_size, canvas_size.y * grid_size)
	canvas_node.rect_min_size = Vector2(canvas_size.x * grid_size, canvas_size.y * grid_size)
	canvas_node.rect_size = Vector2(canvas_size.x * grid_size, canvas_size.y * grid_size)
	emit_signal("canvas_resized", canvas_size)

func load_image_from_file(file_path):
	image.unlock()
	image.load(file_path)
	image.lock()
	canvas_size = image.get_size()
	image_render.unlock()
	image_render.create(canvas_size.x, canvas_size.y, true, Image.FORMAT_RGBA8)
	image_render.lock()
	rect_min_size = Vector2(canvas_size.x * grid_size, canvas_size.y * grid_size)
	rect_size = Vector2(canvas_size.x * grid_size, canvas_size.y * grid_size)
	canvas_node.rect_min_size = Vector2(canvas_size.x * grid_size, canvas_size.y * grid_size)
	canvas_node.rect_size = Vector2(canvas_size.x * grid_size, canvas_size.y * grid_size)
	emit_signal("canvas_resized", canvas_size)

func expand_canvas(new_size):
	canvas_size = new_size
	if canvas_node:
		var array_data = image_data_to_array(image)
		image.unlock()
		image.create(new_size.x, new_size.y, true, Image.FORMAT_RGBA8)
		image.lock()
		image_render.unlock()
		image_render.create(new_size.x, new_size.y, true, Image.FORMAT_RGBA8)
		image_render.lock()
		set_pixels_from_array(array_data)
		rect_min_size = Vector2(new_size.x * grid_size, new_size.y * grid_size)
		rect_size = Vector2(new_size.x * grid_size, new_size.y * grid_size)
		canvas_node.rect_min_size = Vector2(new_size.x * grid_size, new_size.y * grid_size)
		canvas_node.rect_size = Vector2(new_size.x * grid_size, new_size.y * grid_size)
		emit_signal("canvas_resized", new_size)

func set_pixels_from_array(array):
	for i in array:
		set_pixel(i[0], i[1])

func image_data_to_array(image_data):
	var array = []
	if image_data:
		image_data.lock()
		var image_data_size = image_data.get_size()
		for x in image_data_size.x:
			for y in image_data_size.y:
				array.append([Vector2(x, y), image_data.get_pixel(x, y)])
	return array
