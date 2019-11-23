tool
extends FileDialog

onready var canvas = get_parent().get_node("PaintCanvasContainer/ViewportContainer/Viewport/PaintCanvas")

var file_path = ""

func _ready():
	get_line_edit().connect("text_entered", self, "_on_LineEdit_text_entered")
	invalidate()
	clear_filters()
	add_filter("*.png ; PNG Images")

func load_file():
	canvas.load_image_from_file(file_path)

func _on_LineEdit_text_entered(text):
	load_file()

func _on_LoadFileDialog_confirmed():
	load_file()

func _on_LoadFileDialog_file_selected(path):
	file_path = path

func _on_LoadFileDialog_about_to_show():
	invalidate()

func _on_LoadFileDialog_visibility_changed():
	invalidate()
