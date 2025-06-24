extends Label

# Lazy method of changing the shadow color
var enabledShadowColor = "#633902"

func _ready():
	add_to_group('tabs')

func changeTab(tabName):
	if tabName == text:
		print(tabName)
		label_settings.shadow_color = Color('#00000000')
	else: label_settings.shadow_color = Color(enabledShadowColor)
