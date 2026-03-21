extends Node2D

# Boilerplate
var save
var sectionName = 'general'

func _ready() -> void:
	add_to_group('save')

func receive_save(config, _status):
	save = config
	var port = save.get_val(sectionName, 'port')
	if not port == null:
		$TextEdit.text = port
# End boilerplate

func _on_text_edit_text_changed() -> void:
	save.set_val(sectionName, 'port', $TextEdit.text if $TextEdit.text != '' else null)
