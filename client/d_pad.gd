extends Node3D

# The current position gets animated here. Stop the animation if we're gonna move somewhere else
var pressTween

var presses = {
	"Up":false,
	"Down": false,
	"Left": false,
	"Right": false
}

func _ready():
	# The Dpad has these four groups to join, since well; it's more than one button
	add_to_group('Up')
	add_to_group('Down')
	add_to_group('Left')
	add_to_group('Right')

func rock():
	if pressTween and pressTween.is_running():
		print('uh')
		pressTween.stop()
	pressTween = create_tween()
	pressTween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SPRING)
	
	var y = -.25 if presses['Left'] else .25 if presses['Right'] else 0
	var x = -.25 if presses['Up'] else .25 if presses['Down'] else 0
	
	pressTween.tween_property($MeshInstance3D, "rotation", Vector3(x, y, 0), .100)
	pressTween.play()

func press(udlr: String):
	# Press the button so we know which ones to change
	presses[udlr] = true
	rock()
	print('test')

func release(udlr):
	presses[udlr] = false
	rock()
	print('test2')
