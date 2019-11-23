tool
extends ColorPickerButton

var color_picking = false
var mouse_on_top = false

func _ready():
	var color_picker = get_picker()
	var color_picker_button = color_picker.get_children()[0].get_children()[1]
	color_picker_button.disconnect("pressed", color_picker, "_screen_pick_pressed")
	color_picker_button.connect("pressed", self, "color_picker_button_pressed")

func _process(delta):
	if color_picking and not mouse_on_top:
		var editor = get_node("/root/Editor")
		var paint_canvas = get_node("/root/Editor/PaintCanvasContainer/ViewportContainer/Viewport/PaintCanvas")
		var highlighted_color = paint_canvas.get_pixel(editor.cell_mouse_position)
		if not highlighted_color == null:
			color = highlighted_color

func color_picker_button_pressed():
	if not color_picking:
		color_picking = true

func _on_ColorPicker_focus_exited():
	color_picking = false

func _on_ColorPicker_mouse_entered():
	mouse_on_top = true

func _on_ColorPicker_mouse_exited():
	mouse_on_top = false
