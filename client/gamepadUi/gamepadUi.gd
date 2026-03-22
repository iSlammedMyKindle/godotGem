extends Node2D

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

var stickToDpad = {
	'emuU': ['LStickU', 'Up'],
	'emuD': ['LStickD', 'Down'],
	'emuL': ['LStickL', 'Left'],
	'emuR': ['LStickR', 'Right'],
}

var saveObj = null
var keyToCon = false
var dpadEmulation = false

func _ready():
	add_to_group('save')

func receive_save(save: Node, _status: int):
	saveObj = save
	keyToCon = saveObj.get_val('other', 'keytocontroller', false)
	$controllerShell.self_modulate = Color(saveObj.get_val('color', 'controllercolor', 'ffffff'))
	
func update_save_val(_sec: String, key: String, val):
	print('yay')
	if key == 'keytocontroller':
		keyToCon = val
	if key == 'controllercolor':
		$controllerShell.self_modulate = Color(val)

func _process(_delta):
	# This is for keyboard D-Pad emulation; pressing shift should switch between joystick and D-Pad
	if not keyToCon: return
	for item in stickToDpad.keys():
		if Input.is_action_just_pressed(item):
			var emuPress = InputEventAction.new()
			emuPress.action = stickToDpad[item][1 if dpadEmulation else 0]
			emuPress.pressed = true
			Input.parse_input_event(emuPress)
		if Input.is_action_just_released(item):
			var emuPress = InputEventAction.new()
			emuPress.action = stickToDpad[item][1 if dpadEmulation else 0]
			emuPress.pressed = false
			Input.parse_input_event(emuPress)

func _input(event):
	for item in evtList:
		if Input.is_action_just_pressed(item) and not event is InputEventJoypadMotion:
			if event is InputEventKey and not keyToCon: return
			
			get_tree().call_group(item, 'press', item) # Scope: specific button group
			
		if Input.is_action_just_released(item) and not event is InputEventJoypadMotion:
			if event is InputEventKey and not keyToCon: return
			
			get_tree().call_group(item, 'release', item)
	# Toggle this to treat the joystick as a D-Pad, useful for the keyboard joystick emulation
	if Input.is_action_just_pressed("toggleDpadEmulation"): dpadEmulation = not dpadEmulation
