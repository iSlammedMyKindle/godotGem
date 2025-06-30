extends Node

# This is a wrapper file that gives access to saving on a single config object
# Nodes can get updates to the save in real time, so that the UI is never outdated. If one node saves, the others can react.

# Everything except for main can just get the save all at once, so groups will be called simultaneously in _ready to get the saves

var config = ConfigFile.new()
var status: int

func _ready():
	# Load the save
	status = config.load("user://godotGem.cfg")
	
	# While we *could* receive the config directly, it would be better to have this node sent in order to save something
	get_tree().call_group('save', 'receive_save', self, status)

func set_val(section, key, val):
	# Call all nodes looking for this value, if a node updates it's value, then the rest of the app reacts
	config.set_value(section, key, val)
	config.save("user://godotGem.cfg")
	get_tree().call_group('update_save_val', section, key, val)

# Wrapper function for readability (instead of doing config.get_value)
func get_val(section, key):
	return config.get_value(section, key);

# This is for main because this will load before main
# If dynamic objects get called it may also be good for that
func invoke_manual_receive(node: Node2D):
	node.receive_save(self, status)
