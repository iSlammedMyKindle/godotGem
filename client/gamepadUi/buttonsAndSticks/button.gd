extends Node2D

var saveObj
var turboMode = 0
var turboActivated = false
var shaftTween
var originalScale
var shaftColors = [
	'333333',
	'0da399',
	'fbff00',
	'ffaa00'
]

func _ready():
	add_to_group(self.name)
	add_to_group('save')
	if get_node_or_null('plate/letter') != null:
		$plate.get_node('letter').texture = load('res://assets/' + self.name + '.png')
		
func receive_save(save: Node, _status: int):
	saveObj = save
	turboActivated = save.get_val('general', 'turbofeedback', false)

func update_save_val(_section: String, key: String, val):
	if key == 'turbofeedback': turboActivated = val

func press(_btnname):
	$AnimationPlayer.stop();
	$AnimationPlayer.play('press');

func release(_btnname):
	$AnimationPlayer.stop();
	$AnimationPlayer.play_backwards('press');

func sound():
	$audio.play()

func _on_texture_button_pressed() -> void:
	
	if not turboActivated: return
	
	# Change the color based on index. If the index is too big, default to the original one
	turboMode = turboMode + 1
	if turboMode > shaftColors.size() -1:
		turboMode = 0
	
	$shaft.modulate = Color(shaftColors[turboMode])
	
	if originalScale == null:
		originalScale = $shaft.scale

	$shaft.scale = Vector2(originalScale.x * 1.3, originalScale.y * 1.3)
	
	if shaftTween != null and shaftTween.is_running():
		shaftTween.stop()
	
	shaftTween = create_tween()
	shaftTween.tween_property($shaft, 'scale', originalScale, .15)
	shaftTween.set_trans(Tween.TRANS_BOUNCE)
	shaftTween.play()
