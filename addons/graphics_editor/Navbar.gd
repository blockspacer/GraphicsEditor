tool
extends Control

#TODO: Finish the navbar system!
#Disable the quit button when running as an editor plugin!

var navbar_storage = {
	"File": ["New", "Load", "Save"],
	"Editor": ["Settings", "Toggle Grid", "Reset Camera Position"],
	"Image": ["Resize"]
}

func _ready():
	for i in get_node("Buttons").get_children():
		i.connect("item_pressed", self, "button_pressed")

func button_pressed(button_name, button_item):
	if button_name == "File":
		if button_item == "New":
			get_parent().get_node("NewImage").show()
		if button_item == "Load":
			get_parent().get_node("LoadFileDialog").show()
		if button_item == "Save":
			get_parent().get_node("SaveFileDialog").show()
		
		if button_item == "Quit":
			get_tree().quit()
	elif button_name == "Editor":
		if button_item == "Settings":
			get_parent().get_node("Settings").show()
		elif button_item == "Toggle Grid":
			var grids_node = get_parent().get_node("PaintCanvasContainer/ViewportContainer/Viewport/PaintCanvas/Grids")
			grids_node.visible = !grids_node.visible
		elif button_item == "Reset Camera Position":
			get_parent().camera.position = Vector2(0, 0)
	elif button_name == "Image":
		if button_item == "Resize":
			get_parent().get_node("ExpandCanvas").show()
