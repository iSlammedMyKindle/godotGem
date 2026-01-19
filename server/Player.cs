using Fleck;

// This is a wrapper surrounding common properties of a player. This is not a controller, and in fact they are separate entities
class Player
{
    // Define variables
    public Guid id;
    public byte playerNumber;
    private IWebSocketConnection socket;

    public Player(IWebSocketConnection socket, Guid id, SocketCtx? ctx = null, byte playerNumber = 0)
    {
        this.id = id;
        this.playerNumber = playerNumber;
        this.socket = socket;

        if (ctx != null)
            ctx.Initialize(this.socket);
    }

    // Used in places where a catch-22 is hit and we need to self-reference the player within the context of the socket
    public void InitSocket(SocketCtx value)
    {
        value.Initialize(socket);
    }

    public void CloseSocket()
    {
        if (socket.IsAvailable)
            socket.Close();
    }

    // Setup
    public void SendRumble(byte[] rumbleData)
    {
        socket.Send(rumbleData);
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