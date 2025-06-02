extends Node2D

var originalHeight = 0
var bottom = 0
var popped = false
var heat

func _ready():
	# I'm not assuming the heat will be a weird shape, it's just a rectangle with 4 sides equal to eachother mostly
	heat = $container/heat
	originalHeight = heat.polygon[0].y
	bottom = heat.polygon[3].y
	
	# Set the polygon to be default height
	heat.polygon[0].y = bottom
	heat.polygon[1].y = bottom
	
func _process(_delta):
	
	var strength = Input.get_action_strength("TrigR" if name == "TrigR" else "TrigL")
	
	# Change the strength levels
	heat.polygon[0].y = bottom + (originalHeight * strength * 2)
	heat.polygon[1].y = bottom + (originalHeight * strength * 2)
	
	# Calculate the color of the bar
	var redToGreen = strength <= .5
	
	if redToGreen: heat.color = Color(1 * (1 - (strength * 1.5) ), 1 * strength * 1.5, 0 )
	
	# Ohterwise Green to blue
	else: heat.color = Color(0, 1 * (1 - (strength / 1.5) ), 1 * (strength / 1.5 ) )
	
	# Play bump animation if we hit full strength!
	if strength == 1 and not popped:
		popped = true
		$AnimationPlayer.play("pop")
	elif strength < 1 and popped: popped = false
