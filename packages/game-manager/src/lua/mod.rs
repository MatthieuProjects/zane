use std::env::current_dir;
use std::sync::Arc;
use std::sync::Mutex;

use anyhow::anyhow;
use mlua::chunk;
use mlua::prelude::*;
use mlua::StdLib;
use tracing::debug;
use tracing::info;
use walkdir::WalkDir;

use self::api::build_api_table;
use self::data::Game;
use self::data::GameEvent;
use self::data::IntializationData;
use self::storelog::GameState;

mod api;
pub mod data;
mod storelog;

pub struct LuaRuntime {
    rt: Lua,
    thread: LuaRegistryKey,
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

        let path = format!("{cwd}/?.lua", cwd = current_folder);
        debug!("using lua path {}", path);

        runtime
            .load(chunk!(
                package.path = $path
                require "zane.runtime"
            ))
            .exec()?;

        for file in WalkDir::new("./games")
            .into_iter()
            .filter_map(|file| file.ok())
        {
            if file.metadata().unwrap().is_file()
                && file.file_name().to_str().unwrap().ends_with(".lua")
            {
                let module = file
                    .path()
                    .to_str()
                    .unwrap()
                    .replace("./", "")
                    .replace('/', ".")
                    .replace(".lua", "");
                info!("loading module {}", module);
                runtime
                    .load(chunk!(
                        require($module)
                    ))
                    .exec()?;
            }
        }
        let thread = Lua::create_thread(
            &runtime,
            runtime
                .globals()
                .get::<_, LuaTable>("package")?
                .get::<_, LuaTable>("loaded")?
                .get::<_, LuaTable>("zane.runtime")?
                .get::<_, LuaFunction>("consume_events_stream")?,
        )?;
        let registry_key = runtime.create_registry_value(thread)?;

        Ok(Self {
            rt: runtime,
            thread: registry_key,
        })
    }

    pub fn initialize_game(
        &self,
        game: String,
        initialization_data: IntializationData,
    ) -> anyhow::Result<Game> {
        let method = self
            .rt
            .globals()
            .get::<_, LuaTable>("package")?
            .get::<_, LuaTable>("loaded")?
            .get::<_, LuaTable>("zane.runtime")?
            .get::<_, LuaFunction>("initialize_state")?;

        let state = Game {
            state: Arc::new(Mutex::new(GameState::default())),
            initialization_data: Arc::new(Mutex::new(initialization_data)),
        };

        let _: () = method.call((game, state.clone()))?;

        anyhow::Result::Ok(state)
    }

    pub fn handle_event(&self, game: String, event: GameEvent) -> anyhow::Result<()> {
        let thread: LuaThread = self.rt.registry_value(&self.thread)?;
        thread.resume::<_, ()>((game, event))?;
        Ok(())
    }
}
