extends Node2D

var selectedPlayer = 1
var disabledColor = Color("808080")
var enabledColor = Color('FFF')

func _ready():
	add_to_group("player_select_ui")
	visible = false

func toggleDisable(element: TextureButton, disabled: bool):
	element.disabled = disabled
	element.modulate = disabledColor if disabled else enabledColor

func _on_button_l_pressed():
	if selectedPlayer > 1:
		setPlayerNumber(selectedPlayer - 1)

func _on_button_r_pressed():
	if selectedPlayer < 4:
		setPlayerNumber(selectedPlayer + 1)

func setPlayerNumber(playerNumber = 1):
	selectedPlayer = int(playerNumber)
	get_tree().call_group('player_select', 'player_change', selectedPlayer)
	$NumberBox/Label.text = str(selectedPlayer)
	toggleDisable($ButtonL/TextureButton, selectedPlayer == 1)
	toggleDisable($ButtonR/TextureButton, selectedPlayer == 4)

func setVisibility(vb: bool = false):
	visible = vb
