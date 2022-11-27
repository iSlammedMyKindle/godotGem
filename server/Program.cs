using Nefarius.ViGEm.Client;
using Fleck;

var server = new WebSocketServer("ws://0.0.0.0:9090");
var controller = new ViGEmClient().CreateXbox360Controller();
server.Start(socket =>{
    socket.OnOpen = ()=>{
        Console.WriteLine("connected!");
        controller.Connect();
    };

    socket.OnClose = ()=>{
        controller.Disconnect();
    };

    socket.OnBinary = message=>{
        Console.WriteLine(message[0].ToString() + ' ' + message[1].ToString() + ' ' + message[2].ToString());
        controller.SetButtonState(message[1], message[2] == 255);
    };
});

while(true){
    Thread.Sleep(1000);
}