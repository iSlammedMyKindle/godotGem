extends Node2D
var colors = [
	Color("#e06441"),
	Color("#d6cb6b"),
	Color("#00ed8c"),
	Color("#00e1f5"),
	Color("#a07cfc"),
	Color("fa46c4"),
	Color("#ff4a4a")
]

var colorIndex = 0

func _ready():
	$background.modulate = colors[0];
	
	# Animate the background
	bgAnim()

func bgAnim():
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property($background, "modulate", colors[colorIndex], 10)
	tween.tween_callback(bgAnim)
	tween.play()
	
	colorIndex += 1
	if colorIndex > colors.size()-1: colorIndex = 0
