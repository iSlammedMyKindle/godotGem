extends Node3D

# The current position gets animated here. Stop the animation if we're gonna move somewhere else
var pressTween

var presses = {
	"Up":false,
	"Down": false,
	"Left": false,
	"Right": false
}

var turboStates = {
	"Up": 0,
	"Down": 0,
	"Left": 0,
	"Right": 0
}

var turboSpeeds = [ -1, .1, .05, .025 ]

func _ready():
	
	# When turbo is activated on one of the buttons, record it:
	add_to_group('setTurbo')
	
	for btn in presses.keys():
		# The DPad is more than one button, for each direction, it should be added to a group
		add_to_group(btn)
		var timerNode = get_node('timer'+(btn[0]))
		timerNode.timeout.connect(func(): 
			turboToggle(btn))

# Upon the turbo being incremented for a turbo state, record that in our object above:
func setTurbo(udlr):
	turboStates[udlr] = turboStates[udlr] + 1
	if turboStates[udlr] > turboSpeeds.size() -1:
		turboStates[udlr] = 0

# Specifically for each timer node, so that we can continue the turbo-cycle
func turboToggle(udlr):
	# Toggling works a little different here because the animation system gets confused when there's immediately a press & release
	# So instead, there is a rapid toggle between true & false
	if presses[udlr]:
		release_internal(udlr)
		Input.start_joy_vibration(0, 0, 1, .05)
	else:
		press_internal(udlr)

func rock():
	if pressTween and pressTween.is_running():
		pressTween.stop()
	pressTween = create_tween()
	pressTween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SPRING)
	
	var y = -.25 if presses['Left'] else .10 if presses['Right'] else 0.0
	var x = -.25 if presses['Up'] else .10 if presses['Down'] else 0.0
	
	pressTween.tween_property($MeshInstance3D, "rotation", Vector3(x, y, 0), .1)
	pressTween.play()

func press(btnname):
	if turboStates[btnname] > 0:
		var time = turboSpeeds[turboStates[btnname]]
		get_node('timer' + (btnname[0])).start(time)
	else: press_internal(btnname)

func press_internal(udlr: String):
	# Press the button so we know which ones to change
	get_tree().call_group('btnPresses', 'toggle', udlr, true)
	presses[udlr] = true
	rock()
	get_tree().call_group('dpadAudio', 'playSound')

func release(btnname):
	var timerNode = get_node('timer' + (btnname[0]))
	if not timerNode.paused:
		timerNode.stop()
		release_internal(btnname)
	else: release_internal(btnname)

func release_internal(udlr):
	get_tree().call_group('btnPresses', 'toggle', udlr, false)
	presses[udlr] = false
	rock()
