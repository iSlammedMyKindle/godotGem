extends Node2D

func _ready():
	$ignoreVibration/Label.text = "Ignore Vibration";
	$ignoreVibration.settingKey = 'ignoreVibration';

	$turboFeedback/Label.text = "Turbo Feedback";
	$turboFeedback.settingKey = 'turboFeedback';
	
	$buttonSounds/Label.text = "Button Sounds";
	$buttonSounds.settingKey = 'buttonSounds';
	
	$touchScreenButtons/Label.text = "Touch Screen Buttons";
	$touchScreenButtons.settingKey = 'ignoreVibration';
	
	# Add to the group
	add_to_group('tabs')

func changeTab(tabName):
	visible = tabName == name
