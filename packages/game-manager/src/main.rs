use std::collections::HashMap;
use std::str::FromStr;

use game_manager::lua;
use game_manager::lua::data::{GameEvent, IntializationData};
use lua::LuaRuntime;
use tracing_subscriber::filter::Directive;
use tracing_subscriber::prelude::__tracing_subscriber_SubscriberExt;
use tracing_subscriber::EnvFilter;
use tracing_subscriber::{fmt, util::SubscriberInitExt};

fn main() {
    tracing_subscriber::registry()
        .with(fmt::layer())
        .with(
            EnvFilter::builder()
                .with_default_directive(Directive::from_str("info").unwrap())
                .from_env()
                .unwrap(),
        )
        .init();

    let rt = LuaRuntime::new().unwrap();

    let game = rt
        .initialize_game(
            "guess-the-number".to_string(),
            IntializationData {
                users: vec!["user1".to_string(), "user2".to_string()],
            },
        )
        .unwrap();

    let mut data = HashMap::new();
    data.insert("number".to_string(), "1".to_string());

    rt.handle_event(
        "guess-the-number".to_string(),
        GameEvent {
            data: data,
            user: "user1".to_string(),
            game: game.clone(),
        },
    )
    .unwrap();

    let mut data = HashMap::new();
    data.insert("number".to_string(), "5".to_string());

    rt.handle_event(
        "guess-the-number".to_string(),
        GameEvent {
            data: data,
            user: "user2".to_string(),
            game: game.clone(),
        },
    )
    .unwrap();

    let mut data = HashMap::new();
    data.insert("number".to_string(), "0".to_string());

    rt.handle_event(
        "guess-the-number".to_string(),
        GameEvent {
            data: data,
            user: "user2".to_string(),
            game: game.clone(),
        },
    )
    .unwrap();

    let mut data = HashMap::new();
    data.insert("number".to_string(), "0".to_string());

    rt.handle_event(
        "guess-the-number".to_string(),
        GameEvent {
            data: data,
            user: "user1".to_string(),
            game: game.clone(),
        },
    )
    .unwrap();
}
