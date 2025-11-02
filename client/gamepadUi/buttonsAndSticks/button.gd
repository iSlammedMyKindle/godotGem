extends Node2D

var saveObj
var turboMode = 0
var turboActivated = false
var shaftTween
var originalScale
var buttonSounds = false
var shaftColors = {
	'333333': -1,
	'0da399': .2,
	'fbff00': .1,
	'ffaa00': .05
}


func _ready():
	add_to_group(self.name)
	add_to_group('save')
	if get_node_or_null('plate/letter') != null:
		$plate.get_node('letter').texture = load('res://assets/' + self.name + '.png')
		
func receive_save(save: Node, _status: int):
	saveObj = save
	turboActivated = save.get_val('general', 'turbofeedback', false)
	buttonSounds = save.get_val('general', 'buttonsounds', false)

func update_save_val(section: String, key: String, val):
	if key == 'turbofeedback': turboActivated = val
	if section == 'general' and key == 'buttonsounds':
		buttonSounds = val

# press / release vs press_internal / release_internal
# press / release is a direct input event coming from gamepadUI, while the _internal counterparts are for here, so that turbo is functional
func press(_btnname):
	if turboMode > 0:
		var time = shaftColors[shaftColors.keys()[turboMode]]
		$turboTimer.start(time)
	else: press_internal()

func press_internal():
	$AnimationPlayer.stop();
	$AnimationPlayer.play('press');
	# Ultimately this goes back to Main.gd
	if buttonSounds:
		sound()
	if turboActivated and turboMode > 0:
		var time = shaftColors[shaftColors.keys()[turboMode]]
		Input.start_joy_vibration(0, 0, 1, .05)
	get_tree().call_group('btnPresses', 'toggle', name, true) # Scope, all buttons recieve this

func release(_btnname):
	if not $turboTimer.paused:
		$turboTimer.stop()
		release_internal()
	else: release_internal()

func release_internal():
	$AnimationPlayer.stop();
	$AnimationPlayer.play_backwards('press');
	get_tree().call_group('btnPresses', 'toggle', name, false)

func sound():
	$audio.play()

func _on_texture_button_pressed() -> void:
	# Change the color based on index. If the index is too big, default to the original one
	turboMode = turboMode + 1
	if turboMode > shaftColors.keys().size() -1:
		turboMode = 0
	
	$shaft.modulate = Color(shaftColors.keys()[turboMode])
	
	if originalScale == null:
		originalScale = $shaft.scale

	$shaft.scale = Vector2(originalScale.x * 1.3, originalScale.y * 1.3)
	
	if shaftTween != null and shaftTween.is_running():
		shaftTween.stop()
	
	shaftTween = create_tween()
	shaftTween.tween_property($shaft, 'scale', originalScale, .15)
	shaftTween.set_trans(Tween.TRANS_BOUNCE)
	shaftTween.play()
