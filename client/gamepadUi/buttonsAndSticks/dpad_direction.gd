extends MeshInstance3D

# This is mainly here so that the directional posistions of each part of the DPad can be lit-up for heat-mapping
var originalPlateColor

var heatMap = {
	'selfPress': 0.0,
	'everyoneElse': 0.0
}

func _ready():
	originalPlateColor = mesh.material.albedo_color
	add_to_group('heatMap')

func heatMapPress(btnName):
	if btnName == name:
		heatMap.selfPress = heatMap.selfPress + 1.0
	else: heatMap.everyoneElse = heatMap.everyoneElse + 1.0
	
	var fadeMath = ((1.0 / (heatMap.selfPress + heatMap.everyoneElse)) * heatMap.selfPress)
	mesh.material.albedo_color = originalPlateColor + Color( fadeMath, 0, 0, 0)

func resetColor(): mesh.material.albedo_color = originalPlateColor
