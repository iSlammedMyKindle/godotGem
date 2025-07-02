extends Node2D

var checkIndex
var save
var sectionName = 'bg'

func _ready():
	# Add to the group
	add_to_group('tabs')
	add_to_group('save')
	
	checkIndex = {
		$Default: "Default",
		$Green: "Green",
		$Magenta: "Magenta",
	}
	
	# Initialize the connections
	for node in checkIndex.keys():
		node.get_node('Label').text = checkIndex[node]
		node.radioSig.connect(onSettingChecked)
		
func onSettingChecked(caller: Node2D):
	save.set_val(sectionName, 'color' , caller.name)

# From save_logic
func receive_save(config, _status):
	save = config
	var savedVal = save.get_val(sectionName, 'color' , null)
	print('BG: '+ str(savedVal))
	
	if savedVal == null:
		$Default/Box.button_pressed = true
		return

	# Assuming this node exists, just grab the color name
	get_node(savedVal+'/Box').button_pressed = true

func changeTab(tabName: String):
	visible = tabName.to_lower() == sectionName
