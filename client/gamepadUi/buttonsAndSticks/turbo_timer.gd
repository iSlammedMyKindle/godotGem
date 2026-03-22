extends Timer

# INCREDIBLY COMPLICATED OH NO
func _on_timeout():
	get_parent().release_internal()
	get_parent().press_internal()
