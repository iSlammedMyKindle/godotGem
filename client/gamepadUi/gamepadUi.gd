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

func _ready():
	pass

func _input(event):
	for item in evtList:
		if Input.is_action_just_pressed(item) and not event is InputEventJoypadMotion:
			get_tree().call_group(item, 'press', item) # Scope: specific button group
			
		if Input.is_action_just_released(item) and not event is InputEventJoypadMotion:
			get_tree().call_group(item, 'release', item)
