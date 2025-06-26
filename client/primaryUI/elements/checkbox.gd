extends Node2D

var checked = false
var type = 'check'
var settingKey = '' #This will be used to bind a setting.
signal checkSig

# Texture land
var textures = {
	"checked":{
		"normal": null,
		"pressed": null,
	},
	"unchecked":{
		"normal": null,
		"pressed": null,
	}
}

func _ready():
	# configure the textures, we have the uncheked ones already on the button
	textures['unchecked']['normal'] = $Box.texture_normal
	textures['unchecked']['pressed'] = $Box.texture_pressed
	
	#Checked
	textures['checked']['normal'] = load("res://assets/checkedCheck.png")
	textures['checked']['pressed'] = load("res://assets/pressedCheckedCheck.png")


func _on_texture_button_button_up():
	checked = not checked
	
	var changedTextures = textures[("un" if not checked else "") + "checked"]
	$Box.texture_normal = changedTextures['normal']
	$Box.texture_pressed = changedTextures['pressed']
