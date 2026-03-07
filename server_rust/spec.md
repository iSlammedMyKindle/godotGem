
# GodotGem Server Specification
The server needs to do the following:
1. Make decisions about which controller to assign a client to.
1. Receive and execute controller inputs from clients.

## Development Tools Used
The server makes use of the following technologies:
- [tokio](https://crates.io/crates/tokio): Multithreaded async runtime. 
- [tokio_tungstenite](https://crates.io/crates/tokio-tungstenite): Websocket creation and management.
- [virtual_gamepad](https://github.com/RylanYancey/virtual-gamepad): Emulation of gamepads, created specifically for godotGem.

## Sending Controller Updates (JSON API)
A controller update is dispatched by sending a `ClientMessage::ControllerInput` message to the server, which expects a `GamepadButton` and activation value(s) as an array of 2 32-bit floats. For non-analog buttons such as D-PadUp or South, a value of greater than 0.5 at index 0 will be pressed, and a value of less than 0.5 will be released. **You will need to send an update for both button presses and releases**. For Joysticks, index 0 is the "X" axis value, and index 1 is the "Y" axis value, in the range -1.0 to 1.0. 

You can find the full list of supported `GamepadButton`s [here](https://github.com/RylanYancey/virtual-gamepad/blob/3351515e22268ad6fc278f608a436d0f07fa4ae3/src/lib.rs#L34).

### Sending Button Inputs
Non-analog button inputs should be in the range [0.0,1.0]. Values greater than 0.5 will be set to 1.0 by the server, and values less than 0.5 will be set to 0.0. Index 1 of the `values` will be unused by the system, but must be present for `serde` to parse it correctly.
```json
{
  "controller_input": {
    "controller_id": null,
    "update": {
      "button": "South",
      "values": [1.0, 0.0]
    }
  }
}
```

### Sending Joystick Inputs
Joystick inputs should be in the range [-1.0,1.0]. Index 0 of `values` is the X axis value, and index 1 is the Y axis value.
```json
{
  "controller_input": {
    "controller_id": null,
    "update": {
      "button": "LeftStick",
      "values": [-0.1, 0.9]
    }
  }
}
```

### Sending Analog Trigger Inputs
Analog triggers should be in the range [0.0,1.0]. Index 1 of the `values` array will be ignored, but must be present for `serde` to parse it correctly.
```json
{
  "controller_input": {
    "controller_id": null,
    "value": {
      "button": "RightTrigger",
      "values": [0.3981, 0.0]
    }
  }
}
```
