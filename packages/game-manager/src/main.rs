use std::str::FromStr;
use std::sync::Arc;

use bytes::Bytes;
use game_manager::lua;
use game_manager::lua::data::{GameEvent, GameEventSerialized, IntializationData};
use lua::LuaRuntime;
use tokio::task::{spawn_local, LocalSet};
use tokio_stream::StreamExt;
use tracing::info;
use tracing_subscriber::filter::Directive;
use tracing_subscriber::prelude::__tracing_subscriber_SubscriberExt;
use tracing_subscriber::EnvFilter;
use tracing_subscriber::{fmt, util::SubscriberInitExt};

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    tracing_subscriber::registry()
        .with(fmt::layer())
        .with(
            EnvFilter::builder()
                .with_default_directive(Directive::from_str("info").unwrap())
                .from_env()
                .unwrap(),
        )
        .init();

    let rt = Arc::new(LuaRuntime::new().unwrap());
    let nats = async_nats::connect("localhost").await?;

    let mut sub = nats
        .subscribe("zane.matchmake.initialize".to_string())
        .await
        .unwrap();

    let local = LocalSet::new();
    local
        .run_until(async move {
            while let Some(message) = sub.next().await {
                println!("data: {:?}", message.payload);
                let a: IntializationData = serde_json::from_slice(&message.payload).unwrap();
                info!("scheduling game {:?}", a);
                let game_id = a.game_id.clone();
                let game_type = a.game_type.clone();
                let game_data = rt.initialize_game(a.game_type.clone(), a).unwrap();
                let rta = rt.clone();
                let nats = nats.clone();
                let mut subscription = nats
                    .subscribe(format!("zane.game.{}", game_id))
                    .await
                    .unwrap();
                if let Some(reply) = message.reply {
                    let resp =
                        serde_json::to_string(&game_data.state.lock().unwrap().current).unwrap();
                    nats.publish(reply, Bytes::from(resp)).await.unwrap();
                }

                spawn_local(async move {
                    while let Some(message) = subscription.next().await {
                        // handle event
                        let data: GameEventSerialized =
                            serde_json::from_slice(&message.payload).unwrap();

                        let ev = GameEvent {
                            data,
                            game: game_data.clone(),
                        };

                        rta.handle_event(game_type.clone(), ev).unwrap();
                        if let Some(reply) = message.reply {
                            let resp =
                                serde_json::to_string(&game_data.state.lock().unwrap().current)
                                    .unwrap();
                            nats.publish(reply, Bytes::from(resp)).await.unwrap();
                        }

                        if game_data
                            .state
                            .lock()
                            .unwrap()
                            .current
                            .get("status")
                            .unwrap()
                            == "finished"
                        {
                            break;
                        }
                    }

                    subscription.unsubscribe().await.unwrap();
                    info!("finished game {}", game_id);
                });
            }
        })
        .await;

    Ok(())
}
