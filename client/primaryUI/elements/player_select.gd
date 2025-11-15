extends Node2D

var selectedPlayer = 1
var disabledColor = Color("808080")
var enabledColor = Color('FFF')

func toggleDisable(element: TextureButton, disabled: bool):
	element.disabled = disabled
	element.modulate = disabledColor if disabled else enabledColor

func _on_button_l_pressed():
	if selectedPlayer > 1:
		selectedPlayer = selectedPlayer - 1
		get_tree().call_group('player_select', 'player_change', selectedPlayer)
		$NumberBox/Label.text = str(selectedPlayer)
		if selectedPlayer == 1:
			toggleDisable($ButtonL/TextureButton, true)
		if $ButtonR/TextureButton.disabled:
			toggleDisable($ButtonR/TextureButton, false)

func _on_button_r_pressed():
	if selectedPlayer < 4:
		selectedPlayer = selectedPlayer + 1
		get_tree().call_group('player_select', 'player_change', selectedPlayer)
		$NumberBox/Label.text = str(selectedPlayer)
		if selectedPlayer == 4:
			toggleDisable($ButtonR/TextureButton, true)
		if $ButtonL/TextureButton.disabled:
			toggleDisable($ButtonL/TextureButton, false)
