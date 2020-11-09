extends Node
class_name GEAction


var action_data = {}


func _init():
	action_data["redo"] = {}
	action_data["undo"] = {}
	action_data["preview"] = {}


func do_action(canvas, data: Array):
	if not "cells" in action_data.redo:
		action_data.redo["cells"] = []
		action_data.redo["colors"] = []
	
	if not "cells" in action_data.undo:
		action_data.undo["cells"] = []
		action_data.undo["colors"] = []
	
	if not "cells" in action_data.preview:
		action_data.preview["cells"] = []
		action_data.preview["colors"] = []
	
	if not "layer" in action_data:
		action_data["layer"] = canvas.active_layer


func commit_action(canvas):
	print("NO IMPL commit_action ")
	return []


func undo_action(canvas):
	print("NO IMPL undo_action ")


func redo_action(canvas):
	print("NO IMPL redo_action ")


func can_commit() -> bool:
	return not action_data.redo.empty()


