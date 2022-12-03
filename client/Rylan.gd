extends Sprite

var kCode = [12, 12, 13, 13, 14, 15, 14, 15, 1, 0, 11]
var correctIndex = 0

func _input(evt):
	if evt is InputEventMouseButton:
		#Yay one-time long if-statement
		if evt.position.x >= position.x and evt.position.x < (position.x + position.x) and evt.position.y > position.y and evt.position.y < (position.y + position.y):
			visible = false
	elif evt is InputEventJoypadButton and evt.pressed:
		# print(str(correctIndex) + " " + str(evt.button_index) + " " + str(kCode[correctIndex]) + " " + str(kCode[correctIndex] == evt.button_index))
		if kCode[correctIndex] == evt.button_index:
			if correctIndex == kCode.size()-1:
				$AnimationPlayer.stop()
				$AnimationPlayer.play('spin')
				correctIndex = 0
			else: correctIndex += 1
		else: correctIndex = 0
