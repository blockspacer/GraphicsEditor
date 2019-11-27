tool
extends FileDialog

onready var canvas = get_parent().get_parent().get_node("PaintCanvasContainer/ViewportContainer/Viewport/PaintCanvas")

var file_path = ""

func _ready():
	get_line_edit().connect("text_entered", self, "_on_LineEdit_text_entered")
	invalidate()
	clear_filters()
	add_filter("*.png ; PNG Images")

func save_file():
	canvas.image.unlock()
	canvas.image.save_png(file_path)
	canvas.image.lock()

func _on_LineEdit_text_entered(text):
	save_file()

func _on_SaveFileDialog_confirmed():
	save_file()

func _on_SaveFileDialog_file_selected(path):
	file_path = path

func _on_SaveFileDialog_about_to_show():
	invalidate()

func _on_SaveFileDialog_visibility_changed():
	invalidate()
