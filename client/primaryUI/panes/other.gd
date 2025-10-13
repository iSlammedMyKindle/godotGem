extends Node2D

var checkIndex
var save
var sectionName = 'other'

func _ready():
	# Add to the group
	add_to_group('tabs')
	add_to_group('save')
	
	checkIndex = {
		$keyToController: "Key To Controller",
	}
	
	# Initialize the connections
	for node in checkIndex.keys():
		node.get_node('Label').text = checkIndex[node]
		node.checkSig.connect(onSettingChecked)

func changeTab(tabName: String):
	visible = tabName.to_lower() == sectionName

func onSettingChecked(caller: Node2D, checked: bool):
	save.set_val(sectionName, caller.name.to_lower(), checked)

# From save_logic
func receive_save(config, _status):
	save = config
	
	# Go through all keys and set the values
	for node in checkIndex.keys():
		var savedVal = save.get_val(sectionName, node.name.to_lower(), false)
		if not savedVal == null:
			node.setCheckbox(savedVal)
	
# We don't need to do anyting here, all that would do is re-check the checkboxes!
func update_save_val(_section, _key, _val):
	pass
