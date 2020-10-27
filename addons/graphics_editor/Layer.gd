extends Reference
class_name GELayer


var name
var pixels  # array of pixels (colors), idx repressents x and y
var layer_width
var visible = true


func _init():
	pixels = []


func resize(width: int, height: int):
	pixels = []
	for i in range(height * width):
		pixels.append(Color.transparent)
	layer_width = width


func set_pixel(x, y, color):
#	print("setting pixel: (", x, ", ", y, ") with ", color)
	pixels[GEUtils.to_1D(x, y, layer_width)] = color


func get_pixel(x: int, y: int):
	return pixels[x + y * layer_width]


func clear():
	for idx in range(pixels.size()):
		if pixels[idx] != Color.transparent:
			pixels[idx] = Color.transparent
