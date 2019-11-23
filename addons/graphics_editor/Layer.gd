tool
extends Control
var image_storage = Image.new()
#TODO: Get image preview working!
var image_preview setget set_image_preview
var layer_visible = true

func _ready():
	var canvas_size = get_node("../../../../").canvas.image.get_size()
	image_storage.create(canvas_size.x, canvas_size.y, true, Image.FORMAT_RGBA8)

func set_image_preview(image_data):
		image_preview = image_data
		var texture = ImageTexture.new()
		texture.create_from_image(image_data)
		texture.set_flags(0)
		texture.setup_local_to_scene()
		get_node("TextureRect").texture = texture

func _on_LayerButton_pressed():
	get_node("../../../../").active_layer = name

func _on_Visible_pressed():
	layer_visible = !layer_visible

func _on_Delete_pressed():
	get_node("../../../../").remove_layer(name)
