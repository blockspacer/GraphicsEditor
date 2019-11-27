tool
extends Control

var navbar_storage = {
	"File": {
		"items": ["New", "Load", "Save", "Quit"],
		"export_only": ["Quit"]
	},
	"Editor": {
		"items": ["Settings", "Toggle Grid", "Reset Camera Position"],
	},
	"Image": {
		"items": ["Resize"]
	}
}

onready var dialogs = get_parent().get_node("Dialogs")

func _ready():
	var x_to_add = 0
	var menu_button_script = load("res://addons/graphics_editor/MenuButtonExtended.gd")
	for i in navbar_storage:
		var menu_button = MenuButton.new()
		menu_button.name = i
		menu_button.rect_size = Vector2(90, 20)
		menu_button.rect_position = Vector2(x_to_add, 0)
		x_to_add += menu_button.rect_size.x
		menu_button.switch_on_hover = true
		menu_button.flat = false
		menu_button.text = i
		menu_button.set_script(menu_button_script)
		var items_to_remove = []
		if Engine.editor_hint:
			if navbar_storage[i].get("export_only"):
				for j in navbar_storage[i]["export_only"]:
					items_to_remove.append(j)
		if navbar_storage[i].get("items"):
			for j in navbar_storage[i]["items"]:
				var item_index = items_to_remove.find(j)
				if item_index == -1:
					menu_button.get_popup().add_item(j)
		get_node("Buttons").add_child(menu_button)
	for i in get_node("Buttons").get_children():
		i.connect("item_pressed", self, "button_pressed")

func button_pressed(button_name, button_item):
	if button_name == "File":
		if button_item == "New":
			dialogs.show_dialog("NewImage")
		if button_item == "Load":
			dialogs.show_dialog("LoadFileDialog")
		if button_item == "Save":
			dialogs.show_dialog("SaveFileDialog")
		if button_item == "Quit":
			get_tree().quit()
	elif button_name == "Editor":
		if button_item == "Settings":
			dialogs.show_dialog("Settings")
			#get_parent().get_node("Settings").show()
		elif button_item == "Toggle Grid":
			var grids_node = get_parent().get_node("PaintCanvasContainer/ViewportContainer/Viewport/PaintCanvas/Grids")
			grids_node.visible = !grids_node.visible
		elif button_item == "Reset Camera Position":
			get_parent().camera.position = Vector2(0, 0)
	elif button_name == "Image":
		if button_item == "Resize":
			dialogs.show_dialog("ExpandCanvas")