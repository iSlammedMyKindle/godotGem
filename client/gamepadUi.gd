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
	"Right"
]

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _input(event):
	for item in evtList:
		if Input.is_action_just_pressed(item) and not event is InputEventJoypadMotion:
			get_node(item).disabled = false;
			#print(item + " " + str(event.button_index));
		if Input.is_action_just_released(item) and not event is InputEventJoypadMotion:
			get_node(item).disabled = true;
