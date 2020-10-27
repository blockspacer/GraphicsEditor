extends Node
class_name GEAction


var action_data = {}


func _init():
	action_data["do"] = {}
	action_data["undo"] = {}
	action_data["preview"] = {}


func do_action(canvas, data: Array):
	if not "cells" in action_data.do:
		action_data.do["cells"] = []
		action_data.do["colors"] = []
	
	if not "cells" in action_data.undo:
		action_data.undo["cells"] = []
		action_data.undo["colors"] = []
	
	if not "cells" in action_data.preview:
		action_data.preview["cells"] = []
		action_data.preview["colors"] = []
	
	if "layer" in action_data.do:
		action_data.do["layer"] = canvas.active_layer
		action_data.undo["layer"] = canvas.active_layer


func commit_action(canvas):
	print("NO IMPL commit_action ")
	return []


func undo_action(canvas):
	print("NO IMPL undo_action ")


func can_commit() -> bool:
	return not action_data.do.empty()


