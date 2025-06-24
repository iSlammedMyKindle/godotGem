extends Node2D

func _ready():
	get_tree().call_group('tabs', 'changeTab', 'General')
