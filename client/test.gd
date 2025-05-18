extends Node3D

func _process(_delta):
	$MeshInstance3D.rotation_degrees = Vector3(
		$MeshInstance3D.rotation_degrees.x + .16,
		$MeshInstance3D.rotation_degrees.y + .16,
		$MeshInstance3D.rotation_degrees.z + .16,
	)
	print($MeshInstance3D.rotation_degrees)
