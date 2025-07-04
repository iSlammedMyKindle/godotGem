extends Node2D
var bgIndex: Dictionary
var currBg: String
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
	currBg = "Default"
	
	bgIndex = {
		'Default': $background,
		'Green': $chromaGreen,
		'Magenta': $chromaMagenta
	}
	
	add_to_group('save')

func bgAnim():
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property($background, "modulate", colors[colorIndex], 2)
	tween.play()
	
	colorIndex += 1
	if colorIndex > colors.size()-1: colorIndex = 0

func _on_timer_timeout() -> void:
	bgAnim()

# Save logic
func receive_save(saveNode: Node, _status):
	var currSavedBg = saveNode.get_val('bg', 'color', null)
	
	# Change the background
	if not bgIndex.has(currSavedBg): return
	
	if not currSavedBg == "Default": $Timer.stop()
	
	bgIndex[currBg].visible = false
	currBg = currSavedBg
	bgIndex[currBg].visible = true

func update_save_val(sec, key, val):
	if not (sec == 'bg' and key == 'color'): return
	
	if val == 'Default' and $Timer.is_stopped(): $Timer.start()
	
	bgIndex[currBg].visible = false
	currBg = val
	bgIndex[currBg].visible = true
