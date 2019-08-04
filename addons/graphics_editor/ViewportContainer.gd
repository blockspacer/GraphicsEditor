extends ViewportContainer

func _ready():
	pass

func _notification(what):
	if what == Control.NOTIFICATION_RESIZED:
		get_node("Viewport").size = self.rect_size
		get_node("Viewport/Node2D/Camera2D").position = Vector2(self.rect_size.x / 2, self.rect_size.y / 2)