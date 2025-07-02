extends Node2D

# Wow there was basicallly no logic left after setting the button group in godot
var type = 'radio'
signal radioSig()

func _on_box_button_down():
	radioSig.emit(self)
