use std::{collections::HashMap, sync::Arc};

use futures_channel::mpsc::{UnboundedSender, unbounded};
use futures_util::{StreamExt, future, stream::TryStreamExt};
use tokio::net::TcpStream;
use tokio_tungstenite::tungstenite::Message;
use tracing::warn;
use uuid::Uuid;

use crate::{
    State,
    controller::ControllerId,
    types::{ClientMessage, ServerMessage},
};

#[derive(Default)]
pub struct Peers {
    pub peers: HashMap<PeerId, Peer>,
}

impl Peers {
    pub fn insert(&mut self, peer_id: PeerId, peer: Peer) {
        self.peers.insert(peer_id, peer);
    }

    pub fn get_assigned_controller(&self, peer_id: PeerId) -> Option<ControllerId> {
        self.peers.get(&peer_id).map(|peer| peer.controller)
    }
}

#[derive(Eq, PartialEq, Copy, Clone, Hash)]
pub struct PeerId(Uuid);

pub struct Peer {
    pub tx: UnboundedSender<Message>,
    pub controller: ControllerId,
}

pub async fn handle_peer(state: Arc<State>, stream: TcpStream) {
    // Create websocket from TCP Stream
    let websocket = tokio_tungstenite::accept_async(stream)
        .await
        .expect("Websocket Handshake Error");

    // Construct peer data and assign controller
    let peer_id = PeerId(Uuid::new_v4());
    let controller = state.controllers.write().assign(peer_id);
    let (tx, rx) = unbounded::<Message>();
    let peer = Peer { tx, controller };

    // inform client of their controller assignment
    let _ = peer.tx.unbounded_send(Message::Text(
        serde_json::to_string(&ServerMessage::ControllerAssigned(controller.0 as u8))
            .unwrap()
            .into(),
    ));

    // insert peer state into peers map
    state.peers.write().insert(peer_id, peer);

    // The websocket is split into a read/write half, each will have its own async task.
    let (outgoing, incoming) = websocket.split();

    // Spawns a task that writes incoming events to the assigned controller.
    let handle_incoming = incoming.try_for_each(|msg| {
        match msg.into_text() {
            Err(err) => warn!("Error while processing incoming message: '{err}'"),
            Ok(text) => match serde_json::from_str::<ClientMessage>(&text) {
                Err(err) => warn!("Failed to deserialize client message: '{err}'"),
                Ok(msg) => match msg {
                    ClientMessage::ControllerInput { update, .. } => {
                        if let Some(controller) =
                            state.peers.read().get_assigned_controller(peer_id)
                        {
                            state.controllers.write().emit(controller, update);
                        }
                    }
                },
            },
        }
        future::ok(())
    });

    // Creates a future that will spawn an async task that will just
    // write whatever is sent on the channel to the websocket directly.
    let handle_outgoing = rx.map(Ok).forward(outgoing);

    // tells tokio to run both the send and receive futures
    future::select(handle_incoming, handle_outgoing).await;

    // client has disconnected; clean up
    if let Some(peer) = state.peers.write().peers.remove(&peer_id) {
        state.controllers.write().unassign(peer.controller, peer_id);
    }
}
