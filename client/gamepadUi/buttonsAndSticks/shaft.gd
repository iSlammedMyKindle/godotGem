extends Node2D

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
	currTween.tween_property(get_node(udlr), "modulate", Color(0, 0, 0, 1), .200)
	currTween.play()
