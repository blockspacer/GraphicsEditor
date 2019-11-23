extends WindowDialog

onready var paint_canvas = get_node("/root/Editor/PaintCanvasContainer/ViewportContainer/Viewport/PaintCanvas")

func _ready():
	pass

func _on_Ok_pressed():
	var new_canvas_size = Vector2()
	new_canvas_size.x = get_node("CanvasSize/SpinBox").value
	new_canvas_size.y = get_node("CanvasSize/SpinBox2").value
	paint_canvas.expand_canvas(new_canvas_size)
	hide()
