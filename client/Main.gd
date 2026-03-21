extends Node2D

var client = WebSocketPeer.new()
var connected = false
var connecting = false
var config = ConfigFile.new()
var ignoreVibrationBool = false
var currentController = 0
var port = '9090'

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
	# Port
	var configPort = config.get_val("general", "port")
	port = configPort if not configPort == null else '9090'

func update_save_val(sec, key, val):
	if sec == 'general':
		if key == 'ignoreVibration':
			ignoreVibrationBool = val
		if key == 'port':
			port = val if not val == null else '9090'

# Called when the node enters the scene tree for the first time.
func _ready():
	# Save Logic
	add_to_group('save')
	
	# There's a group for each button, but a single group is going to fair better in order to get *all* of them
	add_to_group('btnPresses')
	$saveLogic.invoke_manual_receive(self )
	
	# Player select logic, as seen in player_select.gd
	add_to_group('player_select')

func _process(_delta):
	client.poll()
	var state = client.get_ready_state()
	if state == WebSocketPeer.STATE_OPEN:
		connected = true
		if connecting:
			connecting = false;
			$HUD/connectionStatus.text = "connected to " + $HUD/urlToConnect.text;
			config.set_val("general", "ip", $HUD/urlToConnect.text)
		# Old function that'll be used in this slightly new method according to 4.6 docs
		while client.get_available_packet_count():
			on_data()
	elif state == WebSocketPeer.STATE_CLOSED:
		connected = false
		get_tree().call_group("player_select_ui", "setVisibility", false)

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
			resArray.push_back(currentController)
			resArray.push_back(19 + trigIndex)
			resArray.push_back(strength)

			client.send(resArray)
			
		trigIndex += trigIndex + 1;

func on_data():
	# Alright, so we get the data, but we're going to "cheaply" guess what we're receiving - if the length is 3, we have a
	# Byte array, but otherwise, we're going to assume strings. Not secure by the slightest, but ultimately that's an easy way to decipher it
	var isString = false
	var data: PackedByteArray = client.get_packet()
	var decodedData
	
	if data.size() > 3:
		isString = true
		decodedData = data.get_string_from_utf8()
	else: decodedData = data
	
	# This is JSON and we'll need to parse it to get the contents
	if isString:
		print(decodedData)
		var res: Dictionary = JSON.parse_string(decodedData)
		if res != null:
			if typeof(res) == TYPE_DICTIONARY:
				if res.has("announcement"):
					$HUD/connectionStatus.text = res["announcement"]
				if res.has("controller"):
					get_tree().call_group("player_select_ui", "setVisibility", true)
					get_tree().call_group("player_select_ui", "setPlayerNumber", res["controller"] + 1)
			else: print("JSON not what we expected")
		else: print("Whoop, well that wasn't JSON at all, skipping this one")
		return
	
	# Logic for vibrating the controller
	# First index of the array is target controller, second is small motor, and third is the large motor
	if ignoreVibrationBool: return
	
	if decodedData[1] == 0 and decodedData[2] == 0:
		Input.stop_joy_vibration(0)
	else: Input.start_joy_vibration(0, (1 / 255.0) * decodedData[1], (1 / 255.0) * decodedData[2])
	

func _on_Button_pressed():
	if connected:
		client.close()
		$HUD/Button.text = "Connect!"
		$HUD/connectionStatus.text = "Connect to this address:"
	else:
		$HUD/Button.text = "Disconnect"
		$HUD/connectionStatus.text = "Connecting..."
		print($HUD/urlToConnect.text)

		var status = client.connect_to_url('ws://' + $HUD/urlToConnect.text + ':' + port)
		
		connecting = true
		if status != OK:
			$HUD/connectionStatus.text = "Unable to connect: " + str(status)
			connecting = false
			get_tree().call_group("player_select_ui", "setVisibility", false)

func _on_BlinderBtn_pressed():
	$Blinder/blinderAnimation.play('fade')

func _input(event):
	if event is InputEventMouseButton and event.pressed and $Blinder.visible:
		$Blinder/blinderAnimation.stop()
		$Blinder/blinderAnimation.play_backwards('fade')
		
func set_ui_visibility(visible: bool):
	$Bg.visible = visible
	$gamepadUI.visible = visible

func toggle(btn: String, press: bool):
	#print('btn ', btn, 'press ', str(press))
	if not connected: return
	
	var controllerBuffer = PackedByteArray()
	controllerBuffer.push_back(currentController)  # This byte is for the controller number (P1, P2, etc)
	controllerBuffer.push_back(evtList[btn])  # controller button index
	controllerBuffer.push_back(255 if press else 0)  # Specifies input strength. If this is a button, just do either 0, or 255

	client.send(controllerBuffer)

func player_change(player_number: int):
	print('Selected Player: ' + str(player_number))
	if connected:
		currentController = player_number - 1
		client.send_text(JSON.stringify({
			"controller": currentController
		}))
