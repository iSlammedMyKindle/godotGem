extends Node2D

func _on_showAgain_pressed():
	visible = false

func _on_dontShowAgain_pressed():
	visible = false
	var config = get_node("..").config
	config.set_val("general", "hideGithubSplash", 1)
