extends Control

var message
var time

func _ready():
	get_node("Label").text = message
	get_node("Timer").start(time)

func _on_Timer_timeout():
	queue_free()

func _on_Button_pressed():
	queue_free()
