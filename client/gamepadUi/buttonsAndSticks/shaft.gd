extends Node2D

var shaftColors = [ '333333', '0da399', 'fbff00', 'e16f00' ]
var originalScale
var shaftTween
var tweenedObj

var turboStatuses = {
	"Up": 0,
	"Right": 0,
	"Down": 0,
	"Left": 0,
}

var tweens = {
	"Up" : null,
	"Right" : null,
	"Down" : null,
	"Left" : null,
}

var presses = {
	"Up" : false,
	"Right" : false,
	"Down" : false,
	"Left" : false,
}

var opposites = {
	"Up" : "Down",
	"Right" : "Left",
	"Down" : "Up",
	"Left" : "Right",
}

func _ready():
	add_to_group('Up')
	add_to_group('Down')
	add_to_group('Left')
	add_to_group('Right')

func press(udlr):
	presses[udlr] = true
	if tweens[udlr] and tweens[udlr].is_running():
		tweens[udlr].stop()
	
	tweens[udlr] = create_tween()
	
	var opposite = presses[opposites[udlr]];
	
	var currTween = tweens[udlr] as Tween
	currTween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	currTween.tween_property(
		get_node(udlr),
		"modulate",
		Color(1, 0, 0, 1) if opposite else Color(0, 0, 0, 0),
		.200
	)
	
	# Color in the opposite Dpad entry if somehow both of those are being pressed at the same time
	if opposite:
		currTween.parallel()
		currTween.tween_property(get_node(opposites[udlr]), "modulate", Color(1,0,0,1), .200)
	
	currTween.play()

func release(udlr):
	presses[udlr] = false
	if tweens[udlr] and tweens[udlr].is_running():
		tweens[udlr].stop()
	
	tweens[udlr] = create_tween()
		
	var currTween = tweens[udlr] as Tween
	currTween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	currTween.tween_property(get_node(udlr), "modulate", Color(shaftColors[turboStatuses[udlr]]), .200)
	currTween.play()

func setTurbo(btnName):
	# Increase the index if we're still in margin
	turboStatuses[btnName] = turboStatuses[btnName] + 1
	if turboStatuses[btnName] > shaftColors.size() -1:
		turboStatuses[btnName] = 0
	
	var targetNode = get_node('./'+btnName)
	targetNode.modulate = Color(shaftColors[turboStatuses[btnName]])
	
	if originalScale == null:
		originalScale = targetNode.scale

	targetNode.scale = Vector2(originalScale.x * 1.3, originalScale.y * 1.3)
	
	if shaftTween != null and shaftTween.is_running():
		shaftTween.stop()
		tweenedObj.scale = originalScale
	
	tweenedObj = targetNode
	shaftTween = create_tween()
	shaftTween.tween_property(targetNode, 'scale', originalScale, .15)
	shaftTween.set_trans(Tween.TRANS_BOUNCE)
	shaftTween.play()
