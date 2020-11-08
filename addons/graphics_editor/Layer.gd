extends Reference
class_name GELayer


var name
var pixels  # array of pixels (colors), idx repressents x and y
var layer_width
var visible = true setget set_visible
var locked = false

var texture: ImageTexture
var image: Image
var texture_rect_ref


func _init():
	texture = ImageTexture.new()
	pixels = []


func create(texture_rect_ref, width: int, height: int):
	self.texture_rect_ref = texture_rect_ref
	pixels = []
	for i in range(height * width):
		pixels.append(Color.transparent)
	layer_width = width
	
	image = Image.new()
	image.create(width, height, false, Image.FORMAT_RGBA8)
	update_texture()


func resize(width: int, height: int):
	var pixels_and_colors = []
	for i in range(pixels.size()):
		pixels_and_colors.append([
			GEUtils.to_2D(i, layer_width),
			pixels[i]
			])
	
	layer_width = width
	pixels.clear()
	pixels.resize(width * height)
	
	image.create(width, height, false, Image.FORMAT_RGBA8)
	
	for i in range(height * width):
		pixels[i] = Color.transparent
	
	for i in range(pixels_and_colors.size()):
		var pos = pixels_and_colors[i][0]
		var color = pixels_and_colors[i][1]
		if pos.x >= width or pos.y >= height:
			continue
		set_pixel(pos.x, pos.y, color)
	update_texture()


func set_pixel(x, y, color):
#	print("setting pixel: (", x, ", ", y, ") with ", color)
	pixels[GEUtils.to_1D(x, y, layer_width)] = color
	image.lock()
	image.set_pixel(x, y, color)
	image.unlock()


func get_pixel(x: int, y: int):
	if x < 0 or y < 0 or x >= image.get_width() or y >= image.get_height():
		return null
	image.lock()
	var pixel = image.get_pixel(x, y)
	image.unlock()
	return pixel


func clear():
	for idx in range(pixels.size()):
		if pixels[idx] != Color.transparent:
			pixels[idx] = Color.transparent
			var pos = GEUtils.to_2D(idx, layer_width)
			set_pixel(pos.x, pos.y, Color.transparent)
	update_texture()


func update_texture():
	texture.create_from_image(image, 0)
	texture_rect_ref.texture = texture
	texture_rect_ref.margin_right = 0
	texture_rect_ref.margin_bottom = 0


func set_visible(vis: bool):
	visible = vis
	texture_rect_ref.visible = visible


func toggle_lock():
	locked = not locked
