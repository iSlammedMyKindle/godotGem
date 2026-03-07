use serde::{Deserialize, Serialize};
use virtual_gamepad::GamepadUpdate;

/// Sent from Client to Server
#[derive(Serialize, Deserialize)]
pub enum ClientMessage {
    /// The client pressed a button.
    ControllerInput {
        #[serde(default)]
        controller_id: Option<u8>,
        update: GamepadUpdate,
    },
}

/// Sent from Server to Client.
#[derive(Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum ServerMessage {
    /// The server assigned a controller to the client.
    ControllerAssigned(u8),
}
