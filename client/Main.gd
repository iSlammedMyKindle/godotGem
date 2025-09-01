extends Node2D

var client = WebSocketPeer.new()
var connected = false
var connecting = false
var config = ConfigFile.new()
var ignoreVibrationBool = false

# This list is under the mercy of ViGEm. The buttons are sorted out here based on it's indexing, *not* godot's
var evtList = {
	"Up": 0,
	"Down": 1,
	"Left": 2,
	"Right": 3,
	"Start": 4,
	"Select": 5,
	"SL": 6,
	"SR": 7,
	"LB": 8,
	"RB": 9,
	"Guide": 10,
	"A": 11,
	"B": 12,
	"X": 13,
	"Y": 14,
}

var joySticks = [
	['LStickL', 'LStickR', 'LStickD', 'LStickU'],
	['RStickL', 'RStickR', 'RStickD', 'RStickU'],
]

var previousStickValues = [
	[0, 0],
	[0, 0]
]

var previousTriggerValues = [0, 0]

# Save data loads from [root] -> saveLogic
func receive_save(save: Node, _status: int):
	config = save
	
	if config.get_val("general", "hideGithubSplash") == null:
		$firstTimeRun.visible = true

func update_save_val(sec, key, val):
	if sec == 'general' and key == 'ignoreVibration':
		ignoreVibrationBool = val

# Called when the node enters the scene tree for the first time.
func _ready():
	add_to_group('save')
	$saveLogic.invoke_manual_receive(self)
	
	client.connect("data_received", Callable(self, "_on_data"))
		

func _process(_delta):
	client.poll()
	var state = client.get_ready_state()
	if state == WebSocketPeer.STATE_OPEN:
		connected = true
		if connecting:
			connecting = false;
			$HUD/connectionStatus.text = "connected to " + $HUD/urlToConnect.text;
			config.set_val("general", "ip", $HUD/urlToConnect.text)
	elif state == WebSocketPeer.STATE_CLOSED:
		connected = false

# Responsible for joysticks and trigger inputs
func _physics_process(_delta):
	if not connected: return

	var index = 0
	for stick in joySticks:
		var resArray = [int(Input.get_axis(stick[0], stick[1]) * 32767), int(Input.get_axis(stick[2], stick[3]) * 32767)];

		if (not previousStickValues[index][0] == resArray[0]) or (not previousStickValues[index][1] == resArray[1]):
			previousStickValues[index] = resArray
			# Send this off to the server This is a joystick position that hasn't been sent
			# In order: joystick index (either 15 or 16), joystick X strength, joystick Y strength
			var resStr = "[" + str(15 + (index * 2)) + "," + str(resArray[0]) + "," + str(resArray[1]) + "]"
			client.send_text(resStr)
		index += index + 1

	#Left & Right Triggers
	var trigIndex = 0
	for item in previousTriggerValues:
		var action = "Trig" + ("L" if trigIndex == 0 else "R")
		var strength = int(Input.get_action_strength(action) * 255)

		if previousTriggerValues[trigIndex] != strength:
			previousTriggerValues[trigIndex] = strength
			var resArray = PackedByteArray();
			resArray.push_back(0)
			resArray.push_back(19 + trigIndex)
			resArray.push_back(strength)

			client.send(resArray)
			
		trigIndex += trigIndex + 1;

func _on_data():
	#So far this is for rumble data only. First index of the array is target controller, second is small motor, and third is the large motor
	if ignoreVibrationBool:
		return
		
	var data = client.get_peer(1).get_packet()
	if data[1] == 0 and data[2] == 0:
		Input.stop_joy_vibration(0)
		return
	
	Input.start_joy_vibration(0, (1 / 255.0) * data[1], (1 / 255.0) * data[2])

func _on_Button_pressed():
	if connected:
		client.close()
		$HUD/Button.text = "Connect!"
		$HUD/connectionStatus.text = "Connect to this address:"
	else:
		$HUD/Button.text = "Disconnect"
		$HUD/connectionStatus.text = "Connecting..."
		print($HUD/urlToConnect.text)

		var status = client.connect_to_url('ws://' + $HUD/urlToConnect.text + ':9090')
		
		connecting = true
		if status != OK:
			$HUD/connectionStatus.text = "Unable to connect: " + str(status)
			connecting = false

func _on_BlinderBtn_pressed():
	$Blinder/blinderAnimation.play('fade')

func _input(event):
	if event is InputEventMouseButton and event.pressed and $Blinder.visible:
		$Blinder/blinderAnimation.stop()
		$Blinder/blinderAnimation.play_backwards('fade')
		return
	for item in evtList.keys():
		if connected:
			if Input.is_action_just_pressed(item) and not event is InputEventJoypadMotion:
				var controllerBuffer = PackedByteArray()
				#This byte is for the controller number (P1, P2, etc)
				controllerBuffer.push_back(0)
				# controller button index
				controllerBuffer.push_back(evtList[item])
				# Specifies input strength. If this is a button, just do either 0, or 255
				controllerBuffer.push_back(255)

				client.send(controllerBuffer)
				print(item + " " + str(event.button_index), str(controllerBuffer));

			elif Input.is_action_just_released(item) and not event is InputEventJoypadMotion:
				#Basically same as above, only we tell the server we released the button
				var controllerBuffer = PackedByteArray()
				controllerBuffer.push_back(0)
				controllerBuffer.push_back(evtList[item])
				controllerBuffer.push_back(0)
				
				client.send(controllerBuffer)
