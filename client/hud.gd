extends Node2D

func _input(_evt):
	if Input.is_action_just_pressed('togglehud'):
		visible = not visible
