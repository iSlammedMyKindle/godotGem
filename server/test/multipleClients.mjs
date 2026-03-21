// Informal test used for debugging the server, but also having a little fun in the process
import WebSocket from "ws";

// Get number of clients from command line arguments
const numClients = parseInt((process.argv[2])) || 1;
const delay = parseInt((process.argv[3])) || 200;

function increment(ws) {
    let index = 0;
    let pressedButtons = Array(15).fill(false);
    setInterval(() => {
        const binData = new Uint8Array([0, index, pressedButtons[index] = !pressedButtons[index] ? 0 : 255]);
        ws.send(binData);
        index++;
        if (index > pressedButtons.length - 1) index = 0;
    }, 200)
}

// Set up listeners for each client
function initClient(client, i = 0) {
    client.on("open", () => {
        console.log(`Client ${i + 1} connected`);
        // increment(client);
    });

    client.on("message", data => {
        console.log(`Client ${i + 1} received:`, data);
    });

    client.on("error", error => {
        console.error(`Client ${i + 1} error:`, error);
    });
}

// We're going to create an intentionally race-conditioned instance creation so that everything is split up in the server
function* createClients(count = 1) {
    for (let i = 0; i < count; i++) {
        yield new Promise((res, _rej) => {
            setTimeout(() => {
                const client = new WebSocket('ws://0.0.0.0:9090')
                initClient(
                    client,
                    i
                );
                res(client);
            }, delay);
        })
    }
}

const clientGenerator = createClients(numClients);

const allClients = [];
let nextClient = clientGenerator.next();

while (nextClient.value && await nextClient.value) {
    allClients.push(nextClient.value);
    console.log('Initializing client')
    nextClient = clientGenerator.next();
}

process.on('SIGINT', async () => {
    console.log('Closing clients...');
    for (const clientPromise of allClients) {
        (await clientPromise)?.close?.();
    }
});