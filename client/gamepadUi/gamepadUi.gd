extends Node2D

var save: Node
var buttonSounds = false

var evtList = [
	"A",
	"B",
	"X",
	"Y",
	"LB",
	"RB",
	"Start",
	"Select",
	"Up",
	"Down",
	"Left",
	"Right",
	"SL",
	"SR",
	"Guide"
]

func _ready():
	add_to_group('save')

# buttonsounds is lowercase on purpose (done in general.gd)
func receive_save(node, _status):
	save = node
	buttonSounds = save.get_val('general', 'buttonsounds', false)

func update_save_val(sec, key, val):
	if sec == 'general' and key == 'buttonsounds':
		buttonSounds = val

func _input(event):
	for item in evtList:
		if Input.is_action_just_pressed(item) and not event is InputEventJoypadMotion:
			get_tree().call_group(item, 'press', item)
			if buttonSounds: get_tree().call_group(item, 'sound')
			
		if Input.is_action_just_released(item) and not event is InputEventJoypadMotion:
			get_tree().call_group(item, 'release', item)
