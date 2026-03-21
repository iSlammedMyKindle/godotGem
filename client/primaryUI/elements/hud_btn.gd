extends Node2D

var index = 0
var frameRates = [
	0,
	15,
	30,
	60
]

var colors = [
	"d43d35",
	"68bcf7",
	"ff85d2",
	"e219ff"
]

func _on_btn_button_down() -> void:
	$LabelContainer.position.y = 5

func _on_btn_button_up() -> void:
	$LabelContainer.position.y = 0

func _on_btn_pressed() -> void:
	index = index + 1 if not index == frameRates.size() -1 else 0
	modulate = Color(colors[index])
	
	# Actually set the FPS
	Engine.max_fps = frameRates[index]
	
	$LabelContainer/Num.text = str(frameRates[index])

	var zeroIndex = index == 0
	$LabelContainer/Num.visible = not zeroIndex
	$LabelContainer/Inf.visible = zeroIndex
