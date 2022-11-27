import WebSocket from "ws";

const fakeController = new WebSocket('ws://10.235.1.165:9090');
const controllerInputs = [false, false, false, false];
var index = 0;

fakeController.on("open", ()=>{
    setInterval(()=>{
        let finalVal = (controllerInputs[index] = !controllerInputs[index]) ? 1 : 255;
        console.log(finalVal);
        fakeController.send([0, index, finalVal]);
        index++;
        if(index > controllerInputs.length -1)
            index = 0;
    }, 100);
});