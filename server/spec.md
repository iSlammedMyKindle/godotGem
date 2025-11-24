# WebSocket Specification for the godotGem protocol

In this doc, the goal will be to spell out the main properties of a connection. When initially building this, there was consideration for future implemenation on features such as tracking what player will use what controller. However, the connection system itself has never been described, and will be needed in order to implement both new features, new servers, and describe how clients deliver information too.

In the end, this should provide someone enough info to create their own implementation of either client, or server, without having to reference the code itself.

# Index of Buttons, Joysticks, and Triggers

For the server to know what button is being pressed, it needs an index. This table is based on the requirements of ViGEm, and then adding onto it to accomodate joysticks & triggers (which aren't indexed like a button). It's done this way for consistency for this custom protocol

| Index | Name     |
|-------|----------|
| 0     | Up       |
| 1     | Down     |
| 2     | Left     |
| 3     | Right    |
| 4     | Start    |
| 5     | Select   |
| 6     | SL       |
| 7     | SR       |
| 8     | LB       |
| 9     | RB       |
| 10    | Guide    |
| 11    | A        |
| 12    | B        |
| 13    | X        |
| 14    | Y        |
| 15    | Stick LX |
| 16    | Stick LY |
| 17    | Stick RX |
| 18    | Stick RY |
| 19    | LT       |
| 20    | RT       |

# Establishing a connection

## Server

The server will initially display that it's establishing a connection on `ws://0.0.0.0:9090`. While the port `9090` is accurate, the address is actually going to be whatever is on the local network / WAN.

Connections are *not* encrypted (`e.g wss`), making use of a normal `ws` connection. On `ws` connections there are no SSL certificates that required. Though, if someone implements this spec, they will need to self-provide a certificate should they choose to use `wss`.

For the uninitiated, WebSocket is an lower-level protocol based on HTTP or HTTPS. Therefore the same types of securities also apply here if `wss` is applied (`TLS`).

### Controller assigning

When the server has a new client connection, it should assign any new players to an unassigned controller. Controllers themselves do not connect until either:

* An additional client connects (assigning to P2 e.g)
* Player manually assigns to a new controller

Given a player does manually assign a controller that isn't turned on, for example P3, then the first and second controllers ***Must*** remain turned on, until they switch to P2, in which case P3 can be turned off (no connected clients using it)

If all controllers are assigned, it should assign the player to the fewest assigned players. For example:

Given 4 controllers, with most being assigned 2 players

```json
[
    2,
    1,
    2,
    2
]
```

The logical choice is to add a player would be Player 2's controller, since only one player is present there.
It's highly unlikely that *this* many clients would be connected to 4 controllers, but in the event this does happen; it's entirely possible to assign people to controllers in an orderly fashion.

Players can also manually assign themselves to a controller number. In this case the assigning logic would still apply.

# Client

There is not any sort of handshake that a client needs to do in order to connect. In other websocket implementations I've done, that typically involves telling the server what you wish to listen to. In this case, godotGem simply connects, and the server will respond back saying it got connected.

As mentioned above, the connection will be the server's LAN/WAN address, plus the port number. When connected, the server will not send a receipt that it connected, except if that server is a `bridge` (as of this writing).

If a bridge connects, the bridge sends back the text `server` to the client [I have no idea *why*; if it's not important, I'll probably delete that later down the road]

There is no limit to how many clients can connect.

## Examples

### JS

```js
// Stolen from fakeClient.mjs (see server section of repo) OR tGem
import WebSocket from "ws";
const serverConnection = new WebSocket('ws://0.0.0.0:9090');

fakeController.on("open", () => {
    // Do something like press a button!
});

// controller vibration
fakeController.on("message", data => {
    console.log("vrrr", data);
});
```

# Client -> server

These sections refer to how message bodies are composed. The most common pattern seen will be a byte buffer with 3 indicies. ( e.g `[0, 11, 255]` ) For other cases, such as joysticks, those will instead be stringified JSON.

There will be a few examples in each category, one written in `GDScript`, `JavaScript`, and `C#` (useful for bridge implementations)

## Button Press / Trigger Pull

A button press is an array of bytes, with a size of 3. Example:

```
[ 0, 11, 255 ]
```

Where:

| Index | Name              | Potential Values                                |
|-------|-------------------|-------------------------------------------------|
| `0`   | Controller Number | `0`, `1`, `2`, `3`                              |
| `1`   | Button / Trigger  | `0-14` (Buttons), `19-20` (Triggers)            |
| `2`   | Button State      | Unpressed: `0` , Pressed: `255`                 |
| `2`   | Trigger Strength  | Any range `0 - 255` ( `123`, `255`, `45`, etc ) |

### Examples

#### JS

```js
// Press the "A" button on player 1:
const binData = new Uint8Array([0, 11, 255]);
fakeController.send(binData);
```

#### GDScript

```gd
# Release the "B" button on player 2:
var controllerBuffer = PackedByteArray([ 1, 12, 0 ])

client.send(controllerBuffer)
```

#### C#

```cs
// Half-way pull the left trigger on P3:
socket.send(new byte[]{ 2, 19, 127 })
```

## Joystick

Joystick inputs are done through a JSON array, in order to send both `X` and `Y` values at the same time.

Where:

| Index | Name                         | Potential Values                     |
|-------|------------------------------|--------------------------------------|
| `0`   | Stick Index                  | `15` (LStick), `17` (RStick)         |
| `1`   | X                            | Range: `-32767` to `32767` (Float16) |
| `2`   | Y                            | Range: `-32767` to `32767` (Float16) |
| `3`   | Controller Number (optional) | `0`, `1`, `2`, `3`                   |

The indexes for the individual sticks aren't necessary (`16`, `18`), as when `X` and `Y` are used internally, the system automatically just adds by `1` (15 + 1, 17 + 1)

Inputs are only sent when they are new. In the GDScript client, handling of the joystick is done under `phys_process`, which runs 60 frames per second. To avoid sending more information than needed, it remembers the previous value sent. If it's the same, avoid sending it to prevent traffic on the network.

### Examples

#### JavaScript

```js
// Move the left joystick 75% to the right
// Previously collected ctx indicates this is player 1
controller.send(JSON.stringify(
    [
        15,
        16383,
        0
    ]
));
```

#### GDScript

```gd
# Move the right joystick 25% downward
# Implicit context (last array index) mentions we're doing this to player 2, despite being another player
# *Must* be a string
var resStr = "[" + str(17) + "," + str(0) + "," + str(-16383) + "," + str(1) + "]"
client.send_text(resStr)
```

#### C#

```cs
// CSharp as of the creation of godotGem doesn't have a websocket client, in this example, we're using fleck
using Fleck;
IWebSocketConnection[] server = new IWebSocketConnection[1];

// [...]

// Move the left joystick all the way to the left, implicitly mention player 3's controller (last index)
server[0].Send("[15, -32767, 0, 2]");
```

### Notes

It appears as of this writing I did not implement the player index. For minimal friction, the player index will be *after* the `X` and `Y` coordinates. This will ensure backward compatibility with new clients connecting to old servers.

Eventually, there would need to be a refactor if we add new features, as it wouldn't make sense to jam the player index to the end, when button/trigger arrays have indexes at the beginning.

another potential option would be to presume the number based on already given context. This could remove the extra float off the message, but may impose an edgecase with automation (e.g a client wanting to control multiple controllers at once, or automatically send signals routinely in the case of tGem)

What this may result in, is the ability to do both, with context inferrence taking priority, unless it's explicitly implied that "this controller must be used"

This doc will therefore assume player index is at the end of this JSON Array

## Selecting a player

# Server -> client

## Vibration
