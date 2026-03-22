extends TextureButton

var activated = false

func _on_pressed() -> void:
	if activated: $SettingsAnimations.play_backwards("toggle")
	else: $SettingsAnimations.play('toggle')

	activated = not activated
