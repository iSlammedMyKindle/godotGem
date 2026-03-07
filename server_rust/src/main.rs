use std::{io, sync::Arc};

use clap::Parser;
use parking_lot::RwLock;
use tokio::net::TcpListener;

use crate::{controller::Controllers, peer::Peers};

mod controller;
mod peer;
mod types;

#[derive(clap::Parser)]
#[command(version, about, long_about = None)]
struct Cli {
    /// Defaults to 9090.
    #[arg(long)]
    port: Option<u16>,

    /// Defaults to 4.
    #[arg(long)]
    controller_limit: Option<usize>,
}

#[tokio::main]
async fn main() -> Result<(), io::Error> {
    let args = Cli::parse();

    let state = Arc::new(State {
        peers: RwLock::default(),
        controllers: RwLock::new(Controllers::new(args.controller_limit.unwrap_or(4))),
    });

    // Create the TCP Listener on which connections will be accepted.
    let addr = format!("0.0.0.0:{}", args.port.unwrap_or(9090));
    let try_socket = TcpListener::bind(&addr).await;
    let listener = try_socket.expect("Failed to bind");
    println!("Listening on: {}", addr);

    // Begin accepting clients.
    while let Ok((stream, _)) = listener.accept().await {
        tokio::spawn(peer::handle_peer(state.clone(), stream));
    }

    Ok(())
}

/// Global (Shared) state of the Server.
///
/// # DEADLOCK WARNING:
/// Attempting to acquire both the `peers` lock and `controllers` lock
/// at the same time may cause a deadlock. Avoid acquiring both simultaneously.
struct State {
    peers: RwLock<Peers>,
    controllers: RwLock<Controllers>,
}
