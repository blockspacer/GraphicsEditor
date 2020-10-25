tool
extends GridContainer

signal color_change_request

func _enter_tree():
	for child in get_children():
		child.set("custom_styles/normal", StyleBoxFlat.new())
		child.get("custom_styles/normal").set("bg_color", Color(randf(), randf(), randf())) 
	for child in get_children():
		if child.is_connected("pressed", self, "change_color_to"):
			return
		child.connect("pressed", self, "change_color_to", [child.get("custom_styles/normal").bg_color])


func change_color_to(color):
	emit_signal("color_change_request", color)






