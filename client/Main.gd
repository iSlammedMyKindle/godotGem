extends Node2D

var client = WebSocketClient.new()
var connected = false
var config = ConfigFile.new()

# This list is under the mercy of ViGEm. The buttons are sorted out here based on it's indexing, *not* godot's
var evtList = {
	"Up":0,
	"Down":1,
	"Left":2,
	"Right":3,
	"Start":4,
	"Select":5,
	"SL":6,
	"SR":7,
	"LB":8,
	"RB":9,
	"Guide":10,
	"A":11,
	"B":12,
	"X":13,
	"Y":14,
}

var joySticks = [
	['LStickL', 'LStickR', 'LStickD', 'LStickU' ],
	['RStickL', 'RStickR', 'RStickD', 'RStickU'],
]

var previousStickValues = [
	[0,0],
	[0,0]
]

var previousTriggerValues = [0,0]

# Called when the node enters the scene tree for the first time.
func _ready():
	client.connect("connection_established", self, "_connected")
	client.connect("data_received", self, "_on_data")
	# client.connect("connection_error", self, "_closed")
	# client.connect("connection_closed", self, "_closed")

	# Load the config file:
	var err = config.load("user://godotGem.cfg")
	if err == OK:
		$urlToConnect.text = config.get_value("general","ip")
	
	if config.get_value("general", "hideGithubSplash")	== null:
		$firstTimeRun.visible = true
		

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	client.poll()

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
			setWriteMode(0)
			var resStr = "["+str(15+(index*2))+","+str(resArray[0])+","+str(resArray[1])+"]"
			client.get_peer(1).put_packet(resStr.to_utf8())
		index += index+1

	#Left & Right Triggers
	var trigIndex = 0
	for item in previousTriggerValues:
		var action = "Trig" + ("L" if trigIndex == 0 else "R")
		var strength = int(Input.get_action_strength(action) * 255)

		if previousTriggerValues[trigIndex] != strength:
			previousTriggerValues[trigIndex] = strength
			setWriteMode(1)
			var resArray = PoolByteArray();
			resArray.push_back(0)
			resArray.push_back(19+trigIndex)
			resArray.push_back(strength)

			client.get_peer(1).put_packet(resArray)
			
		trigIndex += trigIndex+1;

func _connected(_proto = ""):
	connected = true
	$connectionStatus.text = "connected to "+$urlToConnect.text;
	config.set_value("general", "ip", $urlToConnect.text)
	config.save("user://godotGem.cfg")

func _on_data():
	#So far this is for rumble data only. First index of the array is target controller, second is small motor, and third is the large motor
	var data = client.get_peer(1).get_packet()
	if data[1] == 0 and data[2] == 0:
		Input.stop_joy_vibration(0)
		return
	
	Input.start_joy_vibration(0, (1 / 255.0) * data[1], (1 / 255.0) * data[2])

func _on_Button_pressed():
	var wsPeer = client.get_peer(1)

	if wsPeer.is_connected_to_host():
		wsPeer.close()
		$Button.text = "Connect!"
		$connectionStatus.text = "Connect to this address:"
	else:
		$Button.text = "Disconnect"
		$connectionStatus.text = "Connecting..."
		print($urlToConnect.text)
		var status = client.connect_to_url('ws://'+$urlToConnect.text+':9090')
		if status != OK:
			$connectionStatus.text = "Unable to connect: "+status

func _on_BlinderBtn_pressed():
	$AnimationPlayer.play('fade')
		

func _input(event):
	if event is InputEventMouseButton and event.pressed and $Blinder.visible:
		$AnimationPlayer.stop()
		$AnimationPlayer.play_backwards('fade')

		return
	for item in evtList.keys():
		if connected:
			if Input.is_action_just_pressed(item) and not event is InputEventJoypadMotion:
				var controllerBuffer = PoolByteArray()
				#This byte is for the controller number (P1, P2, etc)
				controllerBuffer.push_back(0)
				# controller button index
				controllerBuffer.push_back(evtList[item])
				# Specifies input strength. If this is a button, just do either 0, or 255
				controllerBuffer.push_back(255)

				setWriteMode(1)
				client.get_peer(1).put_packet(controllerBuffer)
				print(item + " " + str(event.button_index), str(controllerBuffer));

			elif Input.is_action_just_released(item) and not event is InputEventJoypadMotion:
				#Basically same as above, only we tell the server we released the button
				var controllerBuffer = PoolByteArray()
				controllerBuffer.push_back(0)
				controllerBuffer.push_back(evtList[item])
				controllerBuffer.push_back(0)
				
				setWriteMode(1)
				client.get_peer(1).put_packet(controllerBuffer)

# 0 for utf8 text and 1 for bytes
func setWriteMode(writeMode):
	if client.get_peer(1).get_write_mode() != writeMode:
		client.get_peer(1).set_write_mode(writeMode)


func _on_githubPage_pressed():
	OS.shell_open("https://github.com/iSlammedMyKindle/godotGem")
