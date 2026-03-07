
# GodotGem Server Specification
The server needs to do the following:
1. Make decisions about which controller to assign a client to.
1. Receive and execute controller inputs from clients.

## Development Tools Used
The server makes use of the following technologies:
- [tokio](https://crates.io/crates/tokio): Multithreaded async runtime. 
- [tokio_tungstenite](https://crates.io/crates/tokio-tungstenite): Websocket creation and management.
- [virtual_gamepad](https://github.com/RylanYancey/virtual-gamepad): Emulation of gamepads, created specifically for godotGem.

## Sending Controller Updates (Binary API)
The godotGem server exposes a binary API for controller updates. It is an array of 6 bytes that encodes a button ID, quantized X and Y values, and a controller ID. The server will determine that an update is a controller update and not a `ClientMessage` when the content type on the Websocket `Message` is `Binary` instead of `Text`. 

For Button and Analog Trigger inputs, the Y-axis value will be ignored entirely. Joystick inputs should be in the range [-1.0,1.0]. For Analog Triggers, the X-axis value will be used as the pressure value, and must be in the range [0.0,1.0]. For Buttons, the X-axis value will mean "pressed" if it is greater than 0.5, and "released" otherwise. You will need to send a button update both when a button is pressed _and_ when it is released. 

You can find the full list of supported `GamepadButton` IDs [here](https://github.com/RylanYancey/virtual-gamepad/blob/0a18cf69ba40370df888af9608d57765b007d21f/src/lib.rs#L34). 

**Binary Layout**\
A controller update is an array of 6 bytes. The server will expect all 6 bytes to be present in the message, even if they are unused. The X/Y axis values should be an f32 quantized as an i16. A value of 1.0 would become 32767, a value of -1.0 would become -32768. You can do this by just multiplying the float by 32767 and casting to a 16-bit signed integer. As mentioned above, the X-axis value acts as the pressure value for triggers, and as the activation value for buttons.
 - Gamepad Button ID (1 byte)
 - X-Axis value (2 bytes, quantized f32)
 - Y-Axis value (2 bytes, quantized f32)
 - Controller ID (1 byte, or 255 for not used)

 **Helper Functions**
  - [How to quantize an f32?](https://github.com/RylanYancey/virtual-gamepad/blob/0a18cf69ba40370df888af9608d57765b007d21f/src/lib.rs#L206)

## Client Messages
There are no client messages yet. 

## Server Messages
- ControllerAssigned: Sent when the server assigns or re-assigns a controller to a client.
