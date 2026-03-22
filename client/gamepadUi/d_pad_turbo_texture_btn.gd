extends TextureButton


func _on_pressed():
	get_tree().call_group(name, 'setTurbo', name)
