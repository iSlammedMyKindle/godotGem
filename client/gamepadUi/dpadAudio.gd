extends AudioStreamPlayer2D

# This is here because I wasn't able to figure out how to make the subviewport of the dpad make noise on short notice
# I bet there's a solution out there, would be worth exploring
func _ready():
	add_to_group('dpadAudio')

func playSound():
	play()
