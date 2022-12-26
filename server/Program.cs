using Nefarius.ViGEm.Client;
using Nefarius.ViGEm.Client.Targets;
using Nefarius.ViGEm.Client.Targets.Xbox360;
using System.Text.Json;
using System.Text;

//Server mode
using Fleck;

//Client Mode
using System.Net.WebSockets;

class Program{

    // We don't have anymore buttons above index 14, so these will be used to determine which axis is being detected.
    static Dictionary<byte, Xbox360Property> analogMap = new Dictionary<byte, Xbox360Property>{
        {15, Xbox360Axis.LeftThumbX},
        {16, Xbox360Axis.LeftThumbY},
        {17, Xbox360Axis.RightThumbX},
        {18, Xbox360Axis.RightThumbY},
        {19, Xbox360Slider.LeftTrigger},
        {20, Xbox360Slider.RightTrigger}
    };

    static IXbox360Controller controller = new ViGEmClient().CreateXbox360Controller();
    static byte connected = 0;
    static Action? manualClose;

    //Below are a collection of actions that need to be defined here, because both modes require the same functionality
    static void connectionOpened(Action<byte[]> sendRumble)
    {
        if (connected == 0)
        {
            controller.Connect();
            connected++;

            Console.WriteLine("Connected!");

            controller.FeedbackReceived += (controller, motorActivity) =>
            {
                byte[] rumble = new byte[] { 0, motorActivity.SmallMotor, motorActivity.LargeMotor };
                sendRumble(rumble);
                Console.WriteLine("M " + 0 + " " + motorActivity.SmallMotor + " " + motorActivity.LargeMotor);
            };
        }

        else
        {
            Console.WriteLine("Controller tried re-connecting while still connected? Ok o_O");
            connected++;
        }
    }

    static void connectionClosed()
    {
        connected--;
        Console.WriteLine("A client disconnected");

        if (connected == 0)
        {
            controller.Disconnect();
            Console.WriteLine("The controller disconnected");
        }
    }

    static void stringMsg(string message)
    {
        //So far the only thing we're using this for is for joystick movement, there's no way to send the joystick strength in bytes without heavily compressing information.
        var resArray = JsonDocument.Parse(message);
        Console.WriteLine("JS " + message);

        if (resArray.RootElement.ValueKind == JsonValueKind.Array)
        {
            //Joystick X
            controller.SetAxisValue((Xbox360Axis)analogMap[(byte)resArray.RootElement[0].GetInt16()],
            (short)resArray.RootElement[1].GetInt16());

            //Joystick Y
            controller.SetAxisValue((Xbox360Axis)analogMap[(byte)(resArray.RootElement[0].GetInt16() + 1)],
            (short)resArray.RootElement[2].GetInt16());
        }
    }

    //Non-strings go here, most inputs will come down this way
    static void binMsg(byte[] message)
    {
        Console.WriteLine(message[0].ToString() + ' ' + message[1].ToString() + ' ' + message[2].ToString());
        if (message[1] < 18) controller.SetButtonState(message[1], message[2] == 255);
        else if (message[1] == 19 || message[1] == 20) controller.SetSliderValue((Xbox360Slider)analogMap[message[1]], message[2]);
    }

    private static async void connectToBridge(string address)
    {
        //Token for not being able to connect:
        var cancelTokenSrc = new CancellationTokenSource();
        cancelTokenSrc.Token.Register(() => Console.WriteLine("Server couldn't connect to / disconnect from the bridge for some reason... (cancelled)"));

        //Token for failing to send rumble
        var cancelTokenRumble = new CancellationTokenSource();
        cancelTokenRumble.Token.Register(() => Console.WriteLine("Rumble failed to send... (cancelled)"));

        //Token for failing to receive data from bridge
        var cancelTokenReceive = new CancellationTokenSource();
        cancelTokenRumble.Token.Register(() => Console.WriteLine("Could not get data from bridge! (cancelled)"));

        var connection = new ClientWebSocket();
        manualClose = ()=>{
            connection.CloseAsync(WebSocketCloseStatus.NormalClosure, "Closed upon godotGem bridge request", cancelTokenSrc.Token);
            connectionClosed();
        };

        try{
            await connection.ConnectAsync(new Uri("ws://" + address + ":9090"), cancelTokenSrc.Token);
            await connection.SendAsync(new ArraySegment<byte>(new ASCIIEncoding().GetBytes("server")), WebSocketMessageType.Text, true, cancelTokenSrc.Token);
            Console.WriteLine("Connected to bridge!");
        }
        catch(Exception e){
            Console.WriteLine("Failed to connect to bridge: "+e.ToString());
        }

        //Initialize for client listening
        connectionOpened(rumble => connection.SendAsync(new ArraySegment<byte>(rumble), WebSocketMessageType.Binary, true, cancelTokenRumble.Token));

        //Store results that come in from receiving stuff. The buffer should be waaay more than what we should ever get.
        byte[] bridgeData = new byte[1024];

        //After conecting, we're basically just taking in inputs, and sending vibrations back to the bridge
        while (connection.State != WebSocketState.CloseReceived)
        {
            WebSocketReceiveResult res = await connection.ReceiveAsync(bridgeData, cancelTokenReceive.Token);
            if (res.MessageType == WebSocketMessageType.Text)
            {
                //Convert shtuffz to textz! (...There should be a better way to do this XP)
                stringMsg(new string(new ASCIIEncoding().GetString(new ArraySegment<byte>(bridgeData, 0, res.Count))));
            }

            else if (res.MessageType == WebSocketMessageType.Binary){
                //If it's just a ping, pong:
                if(res.Count == 1 && bridgeData[0] == 1)
                    await connection.SendAsync(new byte[]{1}, WebSocketMessageType.Binary, true, cancelTokenSrc.Token);

                //Otherwise handle button/trigger data
                else binMsg(bridgeData);
            }
        }

        //At this point we need to close the connection properly
        try
        {
            manualClose();
        }
        catch (Exception e)
        {
            Console.WriteLine("Well... shoot -_- " + e.ToString());
        }
    }

    public static void Main(string[] args){

        bool badArgs = false;
        bool bridgeMode = false; //Bool here because that collection of if-statements would make things cluttered if it lived there

        if(args.Length > 0){
            if(args.Length == 2){
                //The "server" beceomes a client that connects to an outside resource
                if(args[0] == "-b") bridgeMode = true;
                
                else badArgs = true;
            }
            else badArgs = true;
        }

        if(badArgs){
            Console.WriteLine("You can launch this program without arguments.\nIf you want to use bridge mode instead of server mode, use \"-b\", followed by a space and the destination url for the bridge you wish to connect to.");
            return;
        }

        if(bridgeMode){
            //Create a new connection to the bridge
            connectToBridge(args[1]);
        }

        else{
            WebSocketServer server = new WebSocketServer("ws://0.0.0.0:9090");
            server.Start(socket =>
            {
                //socket.ConnectionInfo.Id should provide what we need in the event we have multiple clients connecting at once.
                Action<byte[]> sendRumble = rumble => socket.Send(rumble);
                socket.OnOpen = () => connectionOpened(sendRumble);
                socket.OnClose = connectionClosed;

                manualClose = ()=>socket.Close();

                //This webSocket library does the Lord's work and automatically detects and parses strings :D
                socket.OnMessage = stringMsg;
                socket.OnBinary = binMsg;
            });
        }

        // https://learn.microsoft.com/en-us/dotnet/api/system.consolecanceleventargs?view=net-7.0
        Console.CancelKeyPress += new ConsoleCancelEventHandler((sender, args)=>{
            Console.WriteLine("Interrupt signal hit, closing connections...");
            //Close the connection cleanly. C# doesn't seem to like that this could potentially be null, so it's making me do this -_-
            if(manualClose != null) manualClose();
        });

        // Very basic loop to keep the program alive. It's event driven, so this loop won't impact anything as things are happenning in other threads.
        while(true) Thread.Sleep(1000);
    }
}