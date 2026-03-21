extends Sprite2D

# The shadow looks really cool on the default background, but if someone's using this with OBS, it wouldn't make sense sadly, so it's removed upon a chroma key'd background
func _ready():
	add_to_group('save')

func receive_save(saveNode: Node, _status):
	var currSavedBg = saveNode.get_val('color', 'color', "Default")
	
	# Change the background
	visible = currSavedBg == 'Default'

func update_save_val(sec, key, val):
	if sec == 'color' and key == 'color':
		visible = val == 'Default'
