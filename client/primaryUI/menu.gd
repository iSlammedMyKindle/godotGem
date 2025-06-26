extends Node2D

func _ready():
	get_tree().call_group('tabs', 'changeTab', 'General')


func _on_github_page_pressed():
	OS.shell_open("https://github.com/iSlammedMyKindle/godotGem")
