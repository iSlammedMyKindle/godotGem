extends Node2D
var maxDistance = 75
var prefix = ''
var prev = 0
var volume = 0
var save: Node
var buttonSounds = false

func _ready():
	prefix = 'L' if name == 'SL' else 'R'
	add_to_group('S' + prefix)
	add_to_group('save')

# Boilerplate code I stole from gamepadUi.gd
func receive_save(node, _status):
	save = node
	buttonSounds = save.get_val('general', 'buttonsounds', false)
	
func update_save_val(sec, key, val):
	if sec == 'general' and key == 'buttonsounds':
		buttonSounds = val
# End save boilerplate

func _process(delta: float):
	
	# Create X & Y values to represent a traditional value (from -1 to 1)
	var positiveX = Input.get_action_strength( prefix + 'StickR') > 0
	var positiveY = Input.get_action_strength( prefix + 'StickD') > 0
	var x = Input.get_action_strength( prefix + 'StickR' if positiveX else prefix + 'StickL')
	if not positiveX:
		x = 0 - x
		
	var y = Input.get_action_strength( prefix + 'StickD' if positiveY else prefix + 'StickU')
	if not positiveY:
		y = 0 - y
	
	$container/bottom.position = Vector2(maxDistance * x, maxDistance * y)
	$container/bottom/top.position = Vector2(maxDistance * x * .12, maxDistance * y * .12)
	
	# Sound - The joysticks will have a "wooshing" effect like in tetris worlds. It'll be fluid - depending on where the joystick is in conjunction with the entire space, the volume will adjust
	if not buttonSounds: return

	var newVal = snappedf((x+y), 0.1)
	if newVal != prev:
		# Perform some subtraction on the largest and smallest numbers, then raise the volume by that amount
		var diff = abs(newVal) - abs(prev) if abs(newVal) > abs(prev) else abs(prev) - abs(newVal)
		volume = volume + diff
		#print(diff)
	
	if volume > .25:
		volume = .25
	if volume != 0:
		volume = volume - (1.25 * delta)
		#print(volume)
	if volume < 0: volume = 0
	
	
	$analogSfx.volume_linear = volume
	# To protect my ears against bad numbers (during development it blasted to 2000DB... not fun)
	if $analogSfx.volume_linear > 2:
		$analogSfx.stop()
	#$analogSfx.volume_linear > 0 and
	elif not $analogSfx.playing:
		$analogSfx.play()

	if prev != newVal:
		prev = newVal

func press(_stick):
	$AnimationPlayer.stop()
	$AnimationPlayer.play('press')

func release(_stick):
	$AnimationPlayer.stop()
	$AnimationPlayer.play_backwards('press')

func sound():
	$audio.play()
