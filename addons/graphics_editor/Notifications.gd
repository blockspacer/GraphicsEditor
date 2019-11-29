extends Control

var limit = 3

var notification_storage = []

func create(message, time):
	var msg_scene = load("res://addons/graphics_editor/Notification.tscn").instance()
	msg_scene.message = message
	msg_scene.time = time
	if get_node("VBoxContainer").get_children().size() >= limit:
		notification_storage.push_back([message, time])
		return
	msg_scene.connect("tree_exited", self, "notification_deleted")
	get_node("VBoxContainer").add_child(msg_scene)
	get_node("VBoxContainer").move_child(msg_scene, 0)

func notification_deleted():
	if get_node("VBoxContainer").get_children().size() <= limit:
		if notification_storage.size() > 0:
			create(notification_storage[0][0], notification_storage[0][1])
			notification_storage.remove(0)