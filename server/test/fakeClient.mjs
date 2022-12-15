//Informal used for debugging the server, but also having a little fun in the process
import WebSocket from "ws";

const fakeController = new WebSocket('ws://10.235.1.165:9090');
const controllerInputs = [false, false, false, false];
var index = 0;

let inputTest = ()=>{
    setInterval(()=>{
        let finalVal = (controllerInputs[index] = !controllerInputs[index]) ? 1 : 255;
        console.log(finalVal);
        fakeController.send([0, index, finalVal]);
        index++;
        if(index > controllerInputs.length -1)
            index = 0;
    }, 100);
}

function increment(){
    let index = 0;
    let pressedButtons = Array(15).fill(false);
    setInterval(()=>{
        fakeController.send([0, index, (pressedButtons[index] = !pressedButtons[index]) ? 0:255 ]);
        index++;
        if(index > pressedButtons.length -1) index = 0;
    },200)
}

//Tests the axis input value
function flekStringTest(){
    //Joysticks can move anywhere between -32767 and 32767. To simulate this with random numbers, we would need to subtract 32767 by (32767 * 2)
    setInterval(()=>fakeController.send(
        //leJank
        "["+([
            15 + (Math.floor(Math.random() * 2)), //Left or right joystick
            32767 - Math.floor(Math.random() * 65534),
            32767 - Math.floor(Math.random() * 65534),

        ].toString())+"]"), 100);
}

fakeController.on("open", ()=>{
    // inputTest()
    increment();
    // flekStringTest();
});

// controller vibration
fakeController.on("message", data=>{
    console.log("vrrr", data);
});