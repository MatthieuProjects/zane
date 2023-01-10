use std::env::current_dir;
use std::sync::Arc;
use std::sync::Mutex;

use anyhow::anyhow;
use mlua::chunk;
use mlua::prelude::*;
use mlua::StdLib;
use tracing::debug;

use self::api::build_api_table;
use self::data::GameData;
use self::data::GameEvent;
use self::data::IntializationData;
use self::storelog::GameState;

mod api;
pub mod data;
mod storelog;

pub struct LuaRuntime {
    rt: Lua,
}

impl LuaRuntime {
    pub fn new() -> anyhow::Result<Self> {
        let runtime = Lua::new_with(StdLib::ALL_SAFE, LuaOptions::default())?;

        // Register our native module
        runtime
            .globals()
            .get::<&str, LuaTable>("package")?
            .get::<&str, LuaTable>("loaded")?
            .set("zane.native", build_api_table(&runtime)?)?;

        let current_folder = current_dir()?
            .as_path()
            .to_owned()
            .to_str()
            .ok_or_else(|| anyhow!("current direcory is not a string"))?
            .to_string();

        let path = format!("{cwd}/games/?.lua;{cwd}/lib/?.lua", cwd = current_folder);

        debug!("using lua path {}", path);

        let data = Self { rt: runtime };

        data.rt
            .load(chunk!(
                package.path = $path
                require "zane.runtime"
            ))
            .exec()?;

        data.rt.globals().set(
            "__handle",
            Lua::create_thread(
                &data.rt,
                data.rt
                    .globals()
                    .get::<_, LuaTable>("package")?
                    .get::<_, LuaTable>("loaded")?
                    .get::<_, LuaTable>("zane.runtime")?
                    .get::<_, LuaFunction>("consume_events_stream")?,
            )?,
        )?;

        Ok(data)
    }

    pub fn initialize_game(
        &self,
        game: String,
        initialization_data: IntializationData,
    ) -> anyhow::Result<GameData> {
        let method = self
            .rt
            .globals()
            .get::<_, LuaTable>("package")?
            .get::<_, LuaTable>("loaded")?
            .get::<_, LuaTable>("zane.runtime")?
            .get::<_, LuaFunction>("initialize_state")?;

        let state = GameData {
            state: Arc::new(Mutex::new(GameState::default())),
            initialization_data: Arc::new(Mutex::new(initialization_data)),
        };

        let _: () = method.call((game, state.clone()))?;

        anyhow::Result::Ok(state)
    }

    pub fn handle_event(&self, game: String, event: GameEvent) -> anyhow::Result<()> {
        let thread: LuaThread = self.rt.globals().raw_get("__handle")?;
        thread.resume::<_, ()>((game, event))?;
        Ok(())
    }
}
