using Fleck;

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