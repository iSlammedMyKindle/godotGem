using Nefarius.ViGEm.Client;
using Nefarius.ViGEm.Client.Targets;
using Nefarius.ViGEm.Client.Targets.Xbox360;
using System.Text.Json;
using System.Text;
using Constants;

//Server mode
using Fleck;

//Client Mode
using System.Net.WebSockets;

class Program
{

    static IXbox360Controller? controller;
    static byte connected = 0;
    static Action? manualClose;

    //Ripped straight out of the bridge; the core purpose for now is literally to just send vibration feedback to everyone at once.
    //...This is more convoluted for some reason o_O
    static Dictionary<Guid, Action<byte[]>> clients = new Dictionary<Guid, Action<byte[]>>();

    //Below are a collection of actions that need to be defined here, because both modes require the same functionality
    static void connectionOpened(Guid connectionId, Action<byte[]> sendRumble)
    {
        if (connected == 0)
        {
            controller?.Connect();
            connected++;
            clients.Add(connectionId, sendRumble);

            Console.WriteLine("Connected!");

            controller?.FeedbackReceived += (controller, motorActivity) =>
            {
                byte[] rumble = { 0, motorActivity.SmallMotor, motorActivity.LargeMotor };

                foreach (Action<byte[]> act in clients.Values)
                    act(rumble);

                Console.WriteLine("M " + 0 + " " + motorActivity.SmallMotor + " " + motorActivity.LargeMotor);
            };
        }

        else
        {
            Console.WriteLine("Controller tried re-connecting while still connected? Ok o_O");
            connected++;
            clients.Add(connectionId, sendRumble);
        }
    }

    static void connectionClosed()
    {
        connected--;
        Console.WriteLine("A client disconnected");

        if (connected == 0)
        {
            controller?.Disconnect();
            Console.WriteLine("The virtual controller disconnected");
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
            controller?.SetAxisValue((Xbox360Axis)Mappings.ANALOG_MAP[(byte)resArray.RootElement[0].GetInt16()],
            resArray.RootElement[1].GetInt16());

            //Joystick Y
            controller?.SetAxisValue((Xbox360Axis)Mappings.ANALOG_MAP[(byte)(resArray.RootElement[0].GetInt16() + 1)],
            resArray.RootElement[2].GetInt16());
        }
    }

    //Non-strings go here, most inputs will come down this way
    static void binMsg(byte[] message)
    {
        Console.WriteLine(message[0].ToString() + ' ' + message[1].ToString() + ' ' + message[2].ToString());
        if (message[1] < 18)
            controller?.SetButtonState(message[1], message[2] == 255);

        else if (message[1] == 19 || message[1] == 20)
        {
            controller?.SetSliderValue(
                (Xbox360Slider)Mappings.ANALOG_MAP[message[1]],
                message[2]
            );
        }
    }

    private static async void connectToBridge(string address)
    {
        // Token for not being able to connect:
        controller = new ViGEmClient().CreateXbox360Controller();
        var cancelTokenSrc = new CancellationTokenSource();
        cancelTokenSrc.Token.Register(() => Console.WriteLine("Server couldn't connect to / disconnect from the bridge for some reason... (cancelled)"));

        // Token for failing to send rumble
        var cancelTokenRumble = new CancellationTokenSource();
        cancelTokenRumble.Token.Register(() => Console.WriteLine("Rumble failed to send... (cancelled)"));

        // Token for failing to receive data from bridge
        var cancelTokenReceive = new CancellationTokenSource();
        cancelTokenRumble.Token.Register(() => Console.WriteLine("Could not get data from bridge! (cancelled)"));

        var connection = new ClientWebSocket();
        manualClose = () =>
        {
            connection.CloseAsync(WebSocketCloseStatus.NormalClosure, "Closed upon godotGem bridge request", cancelTokenSrc.Token);
            connectionClosed();
        };

        try
        {
            await connection.ConnectAsync(new Uri("ws://" + address + ":9090"), cancelTokenSrc.Token);
            await connection.SendAsync(new ArraySegment<byte>(new ASCIIEncoding().GetBytes("server")), WebSocketMessageType.Text, true, cancelTokenSrc.Token);
            Console.WriteLine("Connected to bridge!");
        }
        catch (Exception e)
        {
            Console.WriteLine("Failed to connect to bridge: " + e.ToString());
        }

        // Initialize for client listening
        // When the server connects to the bridge, we don't need to worry about multiple clients connecting over here because the bridge takes care of that already!
        // Therefore the Guid will be blank.
        connectionOpened(new Guid(), rumble => connection.SendAsync(new ArraySegment<byte>(rumble), WebSocketMessageType.Binary, true, cancelTokenRumble.Token));

        // Store results that come in from receiving stuff. The buffer should be waaay more than what we should ever get.
        byte[] bridgeData = new byte[1024];

        // After conecting, we're basically just taking in inputs, and sending vibrations back to the bridge
        while (connection.State != WebSocketState.CloseReceived)
        {
            WebSocketReceiveResult res = await connection.ReceiveAsync(bridgeData, cancelTokenReceive.Token);
            if (res.MessageType == WebSocketMessageType.Text)
            {
                // Convert shtuffz to textz! (...There should be a better way to do this XP)
                stringMsg(new string(new ASCIIEncoding().GetString(new ArraySegment<byte>(bridgeData, 0, res.Count))));
            }

            else if (res.MessageType == WebSocketMessageType.Binary)
            {
                // If it's just a ping, pong:
                if (res.Count == 1 && bridgeData[0] == 1)
                    await connection.SendAsync(new byte[] { 1 }, WebSocketMessageType.Binary, true, cancelTokenSrc.Token);

                // Otherwise handle button/trigger data
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

    public static void Main(string[] args)
    {

        bool badArgs = false;
        bool bridgeMode = false; //Bool here because that collection of if-statements would make things cluttered if it lived there

        // Initialize controllers
        serverInstance.InitControllers();

        if (args.Length > 0)
        {
            if (args.Length == 2)
            {
                //The "server" beceomes a client that connects to an outside resource
                if (args[0] == "-b") bridgeMode = true;

                else badArgs = true;
            }
            else badArgs = true;
        }

        if (badArgs)
        {
            Console.WriteLine("You can launch this program without arguments.\nIf you want to use bridge mode instead of server mode, use \"-b\", followed by a space and the destination url for the bridge you wish to connect to.");
            return;
        }

        if (bridgeMode)
        {
            //Create a new connection to the bridge
            connectToBridge(args[1]);
        }

        else
        {
            WebSocketServer server = new WebSocketServer("ws://0.0.0.0:9090");
            server.Start(socket =>
            {
                Player newPlayer = new Player(socket, socket.ConnectionInfo.Id);

                //This is used in more than one place, so it's defined here.
                Action closeRoutine = () =>
                {
                    //Remove this connection from the list of connections
                    if (newPlayer != null)
                    {
                        serverInstance.RemovePlayerFromServer(newPlayer);
                        Console.WriteLine("Connection at " + socket.ConnectionInfo.ClientIpAddress + " closed");
                    }
                };

                //This webSocket library does the Lord's work and automatically detects and parses strings :D
                var ctx = new SocketCtx()
                {
                    OnOpen = () =>
                    {
                        serverInstance.AddPlayerToServer(newPlayer);
                        Console.WriteLine("New connection at " + socket.ConnectionInfo.ClientIpAddress);
                        newPlayer.SendMessage("Connected to the server as Player " + (newPlayer.playerNumber + 1) + "!", true);
                    },
                    OnClose = closeRoutine,
                    OnMessage = (msg) => serverInstance.stringMsg(msg, newPlayer),
                    OnBinary = (msg) => serverInstance.binMsg(msg, newPlayer),
                };

                newPlayer.InitSocket(ctx);
            });
        }

        // https://learn.microsoft.com/en-us/dotnet/api/system.consolecanceleventargs?view=net-7.0
        Console.CancelKeyPress += new ConsoleCancelEventHandler((sender, args) =>
        {
            Console.WriteLine("Interrupt signal hit, closing connections...");

            // Close the connection cleanly. C# doesn't seem to like that this could potentially be null, so it's making me do this -_-
            // UPDATE - 2.0 drives me to atcually use this now; for now this will be exclusively for the bridge mode
            if (manualClose != null) manualClose();

            else
            {
                // We're in server mode, disconnect everyone
                foreach (var player in serverInstance.players.Values)
                    serverInstance.RemovePlayerFromServer(player);
            }
        });

        // Very basic loop to keep the program alive. It's event driven, so this loop won't impact anything as things are happenning in other threads.
        while (true) Thread.Sleep(1000);
    }
}