extends Node2D
var config

func _ready():
	add_to_group('save')

func _input(_evt):
	if Input.is_action_just_pressed('togglehud'):
		visible = not visible

# Save data loads from [root] -> saveLogic
func receive_save(save: Node, status: int):
	config = save
	
	if status == OK and config.get_val("general", "ip") != null:
		$urlToConnect.text = config.get_val("general", "ip")
