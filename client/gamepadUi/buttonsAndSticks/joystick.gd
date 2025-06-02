extends Node2D
var maxDistance = 75
var prefix = ''

func _ready():
	prefix = 'L' if name == 'SL' else 'R'
	add_to_group('S' + prefix)

func _process(_delta: float):
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

func press(_stick):
	$AnimationPlayer.stop()
	$AnimationPlayer.play('press')

func release(_stick):
	$AnimationPlayer.stop()
	$AnimationPlayer.play_backwards('press')
