using Nefarius.ViGEm.Client;
using Nefarius.ViGEm.Client.Targets.Xbox360;
using Fleck;
using System.Text.Json;

var server = new WebSocketServer("ws://0.0.0.0:9090");
var controller = new ViGEmClient().CreateXbox360Controller();

// We don't have anymore buttons above index 14, so these will be used to determine which axis is being detected.
Dictionary<byte, Xbox360Property> analogMap = new Dictionary<byte, Xbox360Property>{
    {15, Xbox360Axis.LeftThumbX},
    {16, Xbox360Axis.LeftThumbY},
    {17, Xbox360Axis.RightThumbX},
    {18, Xbox360Axis.RightThumbY},
    {19, Xbox360Slider.LeftTrigger},
    {20, Xbox360Slider.RightTrigger}
};

server.Start(socket =>{
    //socket.ConnectionInfo.Id should provide what we need in the event we have multiple clients connecting at once.
    socket.OnOpen = ()=>{
        Console.WriteLine("connected!");

        // controller.FeedbackReceived += (param1, param2) =>{
        //     Console.WriteLine("asdf");
        // };

        controller.Connect();
    };

    socket.OnClose = ()=>{
        controller.Disconnect();
        Console.WriteLine("Disconnected");
    };

    //This webSocket library does the Lord's work and automatically detects and parses strings :D
    socket.OnMessage = message =>{
        //So far the only thing we're using this for is for joystick movement, there's no way to send the joystick strength in bytes without heavily compressing information.
        var resArray = JsonDocument.Parse(message);

        Console.WriteLine("JS " + message);

        if(resArray.RootElement.ValueKind == JsonValueKind.Array){
            //Joystick X
            controller.SetAxisValue((Xbox360Axis) analogMap[(byte)resArray.RootElement[0].GetInt16()], 
            (short)resArray.RootElement[1].GetInt16());

            //Joystick Y
            controller.SetAxisValue((Xbox360Axis) analogMap[(byte)(resArray.RootElement[0].GetInt16() + 1)], 
            (short)resArray.RootElement[2].GetInt16());
        }
    };

    //Non-strings go here, most inputs will come down this way
    socket.OnBinary = message=>{
        Console.WriteLine(message[0].ToString() + ' ' + message[1].ToString() + ' ' + message[2].ToString());

        if(message[1] < 18) controller.SetButtonState(message[1], message[2] == 255);
        else if(message[1] == 19 || message[1] == 20) controller.SetSliderValue((Xbox360Slider)analogMap[message[1]], message[2]);
    };
});

// Very basic loop to keep the program alive. It's event driven, so this loop won't impact anything as things are happenning in other threads.
while(true) Thread.Sleep(1000);