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


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _input(event):
	for item in evtList:
		if Input.is_action_just_pressed(item) and not event is InputEventJoypadMotion:
			if get_node_or_null(item) is Button:
				get_node(item).disabled = false;
			else: get_tree().call_group(item, 'press', item)
			
		if Input.is_action_just_released(item) and not event is InputEventJoypadMotion:
			if get_node_or_null(item) is Button:
				get_node(item).disabled = true;
			else: get_tree().call_group(item, 'release', item)
