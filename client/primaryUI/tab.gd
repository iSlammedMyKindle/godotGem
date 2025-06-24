extends Node2D

var origPos = 0
var enabledTexture
var inactiveTexture
var posTween: Tween

func _ready() -> void:
	origPos = $Body.position.y
	inactiveTexture = $Body.texture_normal
	enabledTexture = load('res://assets/activeTab.png')
	add_to_group('tabs')

func resetTween():
	if posTween != null:
		posTween.stop()
	posTween = create_tween()
	posTween.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)

func _on_body_mouse_entered() -> void:
	resetTween()
	posTween.tween_property($Body, ^"position:y", origPos * .8, .15)
	posTween.play()
	
func _on_body_mouse_exited() -> void:
	resetTween()
	posTween.tween_property($Body, ^"position:y", origPos, .15)
	posTween.play()

func _on_body_button_down() -> void:
	resetTween()
	posTween.tween_property($Body, ^"position:y", origPos * .5, .05)
	posTween.play()

func _on_body_button_up() -> void:
	_on_body_mouse_exited()


func _on_body_pressed() -> void:
	get_tree().call_group('tabs', 'changeTab', name)

# Group-called function that handles tab swapping logic
func changeTab(tabName = "")-> void:
	if tabName == name:
		$Body.texture_normal = enabledTexture;
		$Body.modulate = Color('#ffffff')
	else:
		$Body.texture_normal = inactiveTexture;
		$Body.modulate = Color('#cccccc')
		_on_body_mouse_exited()
