//Simulates a client connection. Multiples of these can happen at once.
import WebSocket from "ws";

var connection = new WebSocket('ws://0.0.0.0:9090');
var pressed = false;

connection.on('open',()=>{
    console.log('connected to bridge');
    setInterval(()=>connection.send([0, 0, pressed = !pressed]), 200);
});

connection.on('message', data=>{
    console.log('vrr', data);
});