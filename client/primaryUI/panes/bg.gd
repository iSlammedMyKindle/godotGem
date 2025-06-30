extends Node2D

func _ready():
	# Add to the group
	add_to_group('tabs')

func changeTab(tabName):
	visible = tabName == name
