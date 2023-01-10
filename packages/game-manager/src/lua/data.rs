use mlua::prelude::*;
use std::{
    collections::HashMap,
    sync::{Arc, Mutex},
};

use super::storelog::GameState;

pub struct GameEvent {
    pub data: HashMap<String, String>,
    pub user: String,
    pub game: GameData,
}

impl LuaUserData for GameEvent {
    fn add_fields<'lua, F: LuaUserDataFields<'lua, Self>>(fields: &mut F) {
        fields.add_field_method_get("data", |_, this| Ok(this.data.clone()));
        fields.add_field_method_get("game", |_, this| Ok(this.game.clone()));
        fields.add_field_method_get("user", |_, this| Ok(this.user.clone()));
        fields.add_field_method_get("state", |_, this| Ok(this.game.state.clone()));
    }
}

#[derive(Clone)]
pub struct IntializationData {
    pub users: Vec<String>,
}
impl LuaUserData for IntializationData {
    fn add_fields<'lua, F: LuaUserDataFields<'lua, Self>>(fields: &mut F) {
        fields.add_field_method_get("users", |_, this| Ok(this.users.clone()));
    }
}

#[derive(Clone)]
pub struct GameData {
    pub state: Arc<Mutex<GameState>>,
    pub initialization_data: Arc<Mutex<IntializationData>>,
}
impl LuaUserData for GameData {
    fn add_fields<'lua, F: LuaUserDataFields<'lua, Self>>(fields: &mut F) {
        fields.add_field_method_get("state", |_, this| Ok(this.state.clone()));
        fields.add_field_method_get("initialization_data", |_, this| {
            Ok(this.initialization_data.clone())
        });
    }
}
