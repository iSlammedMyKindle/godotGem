extends Node2D

var client = WebSocketClient.new()
var connected = false

var evtList = {
	"A":0,
	"B":1,
	"X":2,
	"Y":3,
	"LB":4,
	"RB":5,
	"Start":11,
	"Select":10,
	"Up":12,
	"Down":13,
	"Left":14,
	"Right":15
}

# Called when the node enters the scene tree for the first time.
func _ready():
	client.connect("connection_established", self, "_connected")
	# client.connect('data_received', self, '_on_data')
	# client.connect("connection_error", self, "_closed")
	# client.connect("connection_closed", self, "_closed")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	client.poll()

func _connected(proto = ""):
	connected = true
	$connectionStatus.text = "connected to "+$urlToConnect.text;

func _on_Button_pressed():
	$connectionStatus.text = "Connecting..."
	print($urlToConnect.text)
	var status = client.connect_to_url('ws://'+$urlToConnect.text+':9090')
	if status != OK:
		$connectionStatus.text = "Unable to connect: "+status


func _input(event):
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
				client.get_peer(1).put_packet(controllerBuffer)
				print(item + " " + str(event.button_index), str(controllerBuffer));

			elif Input.is_action_just_released(item) and not event is InputEventJoypadMotion:
				#Basically same as above, only we tell the server we released the button
				var controllerBuffer = PoolByteArray()
				controllerBuffer.push_back(0)
				controllerBuffer.push_back(evtList[item])
				controllerBuffer.push_back(0)
				
				client.get_peer(1).put_packet(controllerBuffer)
