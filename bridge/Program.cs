using Fleck;

WebSocketServer bridge = new WebSocketServer("ws://0.0.0.0:9090");
bool serverConnected = false;
Guid serverGuid = new Guid(); //Assigned here to make the c# compiler happy
IWebSocketConnection[] server = new IWebSocketConnection[1];

Dictionary<Guid, IWebSocketConnection> clients = new Dictionary<Guid, IWebSocketConnection>();

bridge.Start(socket=>{

    socket.OnOpen = ()=>{
        Console.WriteLine("Connected to: " + socket.ConnectionInfo.Host);
        clients.Add(socket.ConnectionInfo.Id, socket);
    };

    socket.OnMessage = message =>{
        if(message == "server"){
            //Remove the server from the list of clients
            clients.Remove(socket.ConnectionInfo.Id);

            if(!serverConnected){
                server[0] = socket;
                serverConnected = true;
                serverGuid = socket.ConnectionInfo.Id;
                Console.WriteLine("This connection is now the host: " + server[0].ConnectionInfo.Host);
            }

            else{
                Console.WriteLine("Server connection already established. Closing connection from: "+socket.ConnectionInfo.Host);
                socket.Close();
            }
        }

        else if(socket.ConnectionInfo.Id != serverGuid && server[0] != null){
            //Client connections, we send these signals over to the server. It is likely a joystick.
            server[0].Send(message);
        }
    };

    socket.OnBinary = message=>{
        //Subsequent server connections can be picked up if we want to compare the guid
        if(socket.ConnectionInfo.Id == serverGuid){
            //code basically purely for controller vibrations go here
            foreach(KeyValuePair<Guid, IWebSocketConnection> entry in clients){
                entry.Value.Send(message);
            }
        }
        //Just forward this to the server (If it is the server), nothing much to do here
        else if(server[0] != null)
            server[0].Send(message);

        //Simple vibration feedback if we don't have a server connected. (Because controller vibration is fun)
        else if(message[2] == 255)
            socket.Send(new byte[]{0, 255, 255});

        else if(message[2] == 0)
            socket.Send(new byte[]{0, 0, 0});
    };

    socket.OnClose = ()=>{
        Console.WriteLine("Closed connection from: "+socket.ConnectionInfo.Host);
        if(serverConnected && serverGuid == socket.ConnectionInfo.Id){
            serverConnected = false;
            server[0] = null;
            Console.WriteLine("Server is no longer set (Was "+socket.ConnectionInfo.Host+")");
        }
    };
});

while(true) Thread.Sleep(1000);