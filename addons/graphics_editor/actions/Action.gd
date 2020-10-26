extends Node
class_name GEAction


var action_data = {}


func _init():
	action_data["do"] = {}
	action_data["undo"] = {}


func do_action(canvas, data: Array):
	print("NO IMPL do_action")


func commit_action(canvas):
	print("NO IMPL commit_action ")


func undo_action(canvas):
	print("NO IMPL undo_action ")


func can_commit() -> bool:
	return not action_data.do.empty()


