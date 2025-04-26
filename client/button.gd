extends Node2D

func _ready():
	add_to_group(self.name)
	if get_node_or_null('plate/letter') != null:
		$plate.get_node('letter').texture = load('res://assets/' + self.name + '.png')

func press(_btnname):
	$AnimationPlayer.stop();
	$AnimationPlayer.play('press');

func release(_btnname):
	$AnimationPlayer.stop();
	$AnimationPlayer.play_backwards('press');
