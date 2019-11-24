extends Camera2D

#TODO: Make the camera movement snap to the nearest highlighted cell

var speed = 10
func _process(delta):
	if Input.is_key_pressed(KEY_LEFT):
		position += Vector2(-1, 0) * speed
	elif Input.is_key_pressed(KEY_RIGHT):
		position += Vector2(1, 0) * speed
	
	if Input.is_key_pressed(KEY_UP):
		position += Vector2(0, -1) * speed
	elif Input.is_key_pressed(KEY_DOWN):
		position += Vector2(0, 1) * speed