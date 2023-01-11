use mlua::prelude::*;
use serde::Deserialize;
use std::{
    collections::HashMap,
    sync::{Arc, Mutex},
};

use super::storelog::GameState;

#[derive(Debug, Deserialize)]
pub struct GameEventSerialized {
    pub properties: HashMap<String, String>,
    pub user: String,
}

#[derive(Debug)]
pub struct GameEvent {
    pub data: GameEventSerialized,
    pub game: Game,
}

impl LuaUserData for GameEvent {
    fn add_fields<'lua, F: LuaUserDataFields<'lua, Self>>(fields: &mut F) {
        fields.add_field_method_get("properties", |_, this| Ok(this.data.properties.clone()));
        fields.add_field_method_get("game", |_, this| Ok(this.game.clone()));
        fields.add_field_method_get("user", |_, this| Ok(this.data.user.clone()));
    }
}

#[derive(Debug, Clone, Deserialize)]
pub struct IntializationData {
    pub game_id: String,
    pub game_type: String,
    pub users: Vec<String>,
}
impl LuaUserData for IntializationData {
    fn add_fields<'lua, F: LuaUserDataFields<'lua, Self>>(fields: &mut F) {
        fields.add_field_method_get("users", |_, this| Ok(this.users.clone()));
        fields.add_field_method_get("game_id", |_, this| Ok(this.game_id.clone()));
        fields.add_field_method_get("game_type", |_, this| Ok(this.game_type.clone()));
    }
}

#[derive(Debug, Clone)]
pub struct Game {
    pub state: Arc<Mutex<GameState>>,
    pub initialization_data: Arc<Mutex<IntializationData>>,
}
impl LuaUserData for Game {
    fn add_fields<'lua, F: LuaUserDataFields<'lua, Self>>(fields: &mut F) {
        fields.add_field_method_get("state", |_, this| Ok(this.state.clone()));
        fields.add_field_method_get("initialization_data", |_, this| {
            Ok(this.initialization_data.clone())
        });
    }
}
