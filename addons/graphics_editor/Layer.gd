tool
extends Control
onready var layers = get_node("../../../../")
onready var canvas = layers.canvas
var image_storage = Image.new()
#TODO: Get image preview working!
var image_preview setget set_image_preview
var layer_visible = true setget set_layer_visible

func _ready():
	var canvas_size = canvas.image.get_size()
	image_storage.create(canvas_size.x, canvas_size.y, true, Image.FORMAT_RGBA8)

func set_image_preview(image_data):
		image_preview = image_data
		var texture = ImageTexture.new()
		texture.create_from_image(image_data)
		texture.set_flags(0)
		texture.setup_local_to_scene()
		get_node("TextureRect").texture = texture

func set_layer_visible(value):
	layer_visible = value
	if layer_visible:
		get_node("Visible").modulate = Color(1, 1, 1)
	else:
		get_node("Visible").modulate = Color(0.572549, 0.572549, 0.572549)
	
func _on_LayerButton_pressed():
	layers.active_layer = name

func _on_Visible_pressed():
	set_layer_visible(!layer_visible)

func _on_Delete_pressed():
	layers.remove_layer(name)
