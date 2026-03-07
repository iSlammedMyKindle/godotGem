use std::time::Duration;

use futures_util::SinkExt;
use tokio_tungstenite::tungstenite::{Bytes, Message, client::IntoClientRequest};
use virtual_gamepad::{GamepadButton, GamepadUpdate};

// Use this to test: https://hardwaretester.com/gamepad

const BUTTONS: &[GamepadButton] = &[
    GamepadButton::South,
    GamepadButton::North,
    GamepadButton::East,
    GamepadButton::West,
    GamepadButton::LeftTrigger,
    GamepadButton::RightTrigger,
    GamepadButton::LeftBumper,
    GamepadButton::RightBumper,
];

#[tokio::main]
async fn main() {
    let req = "ws://0.0.0.0:9090".into_client_request().unwrap();
    let (mut client, _response) = tokio_tungstenite::connect_async(req).await.unwrap();
    loop {
        tokio::time::sleep(Duration::from_millis(500)).await;

        let update = GamepadUpdate {
            button: BUTTONS[getrandom::u32().unwrap() as usize % BUTTONS.len()],
            values: [(getrandom::u32().unwrap() & 1 == 0) as u8 as f32, 0.0],
        };
        println!(
            "Simulating press of button '{:?}' with values '{:?}'",
            update.button, update.values
        );

        let mut data = Vec::new();
        data.extend_from_slice(&update.to_bytes());
        data.push(u8::MAX);

        let msg = Message::Binary(Bytes::from(data));
        client.send(msg).await.unwrap();
    }
}
