use serde::{Deserialize, Serialize};

/// Sent from Client to Server
#[derive(Serialize, Deserialize)]
pub enum ClientMessage {}

/// Sent from Server to Client.
#[derive(Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum ServerMessage {
    /// The server assigned a controller to the client.
    ControllerAssigned(u8),
}
