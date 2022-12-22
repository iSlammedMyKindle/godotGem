//Simulates a client connection, only one of these can happen at a time.
import WebSocket from 'ws';

var connection = new WebSocket('ws://0.0.0.0:9090');

connection.on("open",()=>{
    connection.send('server');
    // setTimeout(()=>connection.close(), 2000);
    setInterval(()=>connection.send([0, Math.floor(Math.random()*256), Math.floor(Math.random()*256)]), 1000);
});

connection.on('message', data=>{
    console.log('bridge: ', data);
});

connection.on('close', ()=>{
    console.log('connection to server got closed');
});