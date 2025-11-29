using Nefarius.ViGEm.Client;
using Nefarius.ViGEm.Client.Targets;
using Nefarius.ViGEm.Client.Targets.Xbox360;
using System.Text.Json;
using System.Text;

//Server mode
using Fleck;

//Client Mode
using System.Net.WebSockets;

// This is a wrapper surrounding common properties of a player. This is not a controller, and in fact they are separate entities
class Player
{
    // Define variables
    public Guid id;
    public byte playerNumber;
    private IWebSocketConnection socket;

    public Player(IWebSocketConnection socket, Guid id, SocketCtx ctx, byte playerNumber)
    {
        this.id = id;
        this.playerNumber = playerNumber;
        this.socket = socket;

        ctx.Initialize(this.socket);
    }

    // Setup
    public void SendRumble(byte[] rumbleData)
    {
        this.socket.Send(rumbleData);
    }
}

class SocketCtx
{
    public required Action OnOpen;
    public required Action OnClose;
    public required Action<string> OnMessage;
    public required Action<byte[]> OnBinary;

    public void Initialize(IWebSocketConnection socket)
    {
        socket.OnOpen = OnOpen;
        socket.OnClose = OnClose;
        socket.OnMessage = OnMessage;
        socket.OnBinary = OnBinary;
    }
}

static class serverInstance
{
    public static Dictionary<Guid, Player> players = new Dictionary<Guid, Player>();
    public static IXbox360Controller[] controllers = new IXbox360Controller[4];

    public static int PlayerCount
    {
        get
        {
            return players.Count;
        }
    }

    public static byte[] PlayersPerController
    {
        get
        {
            byte[] counts = [0, 0, 0, 0];

            foreach (Player p in players.Values)
            {
                counts[p.playerNumber - 1]++;
            }

            return counts;
        }
    }

    public static void InitControllers()
    {
        for (int i = 0; i < controllers.Length; i++)
        {
            controllers[i] = new ViGEmClient().CreateXbox360Controller();
        }
    }

    // Given a new player, when they are added to the server, allow them to use a controller not in-use (including ones not turned on yet)
    public static void AddPlayerToServer(Player newPlayer)
    {
        // Loop through all quantities of controllers. If we find that all of them are being used, increment up
        bool connected = false;
        for (byte i = 0; !connected; i++)
        {
            foreach (byte count in PlayersPerController)
            {
                if (count != i) continue;
                if (count == 0) controllers[count].Connect();

                players.Add(newPlayer.id, newPlayer);
                newPlayer.playerNumber = count;
                connected = true;
                break;
            }
        }
    }

    public static void RemovePlayerFromServer(Player player)
    {
        players.Remove(player.id);
        DisconnectControllerAt(player.playerNumber);
    }

    // Go through the routine of disonnecting a controller, only if the index *after* lacks a player count
    public static void DisconnectControllerAt(byte index)
    {
        byte[] ppc = PlayersPerController;
        bool noMorePlayers = ppc[index] == 0;
        bool nextIndexEmpty = ppc[index + 1] == 0;
        bool atMaxPlayerCount = index == ppc.Length;

        // Given a disconnected player, if there is no one playing the controller number above, OR we're at max players, diconnect the controller if that was the last person using it.
        if (
            (atMaxPlayerCount && noMorePlayers) ||
            nextIndexEmpty && noMorePlayers
        )
        {
            controllers[index - 1].Disconnect();
        }
    }

    public static void SwitchPlayerToController(Player player, byte newControllerIndex)
    {
        // Switch the player to the new controller
        player.playerNumber = newControllerIndex;

        // Connect the new controller if needed
        if (PlayersPerController[newControllerIndex] == 0)
            controllers[newControllerIndex - 1].Connect();

        // Disconnect from the old controller if needed
        DisconnectControllerAt(player.playerNumber);
    }
}

class Program
{

    // We don't have anymore buttons above index 14, so these will be used to determine which axis is being detected.
    static readonly Dictionary<byte, Xbox360Property> analogMap = new()
    {
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

    //Ripped straight out of the bridge; the core purpose for now is literally to just send vibration feedback to everyone at once.
    //...This is more convoluted for some reason o_O
    static Dictionary<Guid, Action<byte[]>> clients = new Dictionary<Guid, Action<byte[]>>();

    //Below are a collection of actions that need to be defined here, because both modes require the same functionality
    static void connectionOpened(Guid connectionId, Action<byte[]> sendRumble)
    {
        if (connected == 0)
        {
            controller.Connect();
            connected++;
            clients.Add(connectionId, sendRumble);

            Console.WriteLine("Connected!");

            controller.FeedbackReceived += (controller, motorActivity) =>
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
            controller.Disconnect();
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
            controller.SetAxisValue((Xbox360Axis)analogMap[(byte)resArray.RootElement[0].GetInt16()],
            resArray.RootElement[1].GetInt16());

            //Joystick Y
            controller.SetAxisValue((Xbox360Axis)analogMap[(byte)(resArray.RootElement[0].GetInt16() + 1)],
            resArray.RootElement[2].GetInt16());
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

        //Initialize for client listening
        //When the server connects to the bridge, we don't need to worry about multiple clients connecting over here because the bridge takes care of that already!
        //Therefore the Guid will be blank.
        connectionOpened(new Guid(), rumble => connection.SendAsync(new ArraySegment<byte>(rumble), WebSocketMessageType.Binary, true, cancelTokenRumble.Token));

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

            else if (res.MessageType == WebSocketMessageType.Binary)
            {
                //If it's just a ping, pong:
                if (res.Count == 1 && bridgeData[0] == 1)
                    await connection.SendAsync(new byte[] { 1 }, WebSocketMessageType.Binary, true, cancelTokenSrc.Token);

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
                //socket.ConnectionInfo.Id should provide what we need in the event we have multiple clients connecting at once.
                Action<byte[]> sendRumble = rumble => socket.Send(rumble);

                //This is used in more than one place, so it's defined here.
                Action closeRoutine = () =>
                {
                    //Remove this connection from the list of connections
                    clients.Remove(socket.ConnectionInfo.Id);
                    connectionClosed();
                };

                manualClose = () =>
                {
                    socket.Close();
                    closeRoutine();
                };

                //This webSocket library does the Lord's work and automatically detects and parses strings :D
                var ctx = new SocketCtx()
                {
                    OnOpen = () => connectionOpened(socket.ConnectionInfo.Id, sendRumble),
                    OnClose = closeRoutine,
                    OnMessage = stringMsg,
                    OnBinary = binMsg,
                };

                // TODO: Temporary, needs to be done while instantiating a player object
                ctx.Initialize(socket);
            });
        }

        // https://learn.microsoft.com/en-us/dotnet/api/system.consolecanceleventargs?view=net-7.0
        Console.CancelKeyPress += new ConsoleCancelEventHandler((sender, args) =>
        {
            Console.WriteLine("Interrupt signal hit, closing connections...");

            //Close the connection cleanly. C# doesn't seem to like that this could potentially be null, so it's making me do this -_-
            if (manualClose != null) manualClose();
        });

        // Very basic loop to keep the program alive. It's event driven, so this loop won't impact anything as things are happenning in other threads.
        while (true) Thread.Sleep(1000);
    }
}