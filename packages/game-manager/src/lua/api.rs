use mlua::{prelude::*, Variadic};
use tracing::info;
use walkdir::WalkDir;

use super::storelog::GameState;

fn used_memory(lua: &Lua, _: ()) -> LuaResult<usize> {
    Ok(lua.used_memory())
}

fn print(_: &Lua, arg: Variadic<String>) -> LuaResult<LuaValue> {
    info!("{}", arg.into_iter().collect::<Vec<String>>().join(" "));

    Ok(LuaValue::Nil)
}

fn list_games(lua: &Lua, _: ()) -> LuaResult<LuaValue> {
    let table = lua.create_table()?;
    for file in WalkDir::new("./games")
        .into_iter()
        .filter_map(|file| file.ok())
    {
        if file.metadata().unwrap().is_file()
            && file.file_name().to_str().unwrap().ends_with(".lua")
        {
            let module = file
                .file_name()
                .to_str()
                .unwrap()
                .replace('/', ".")
                .replace(".lua", "");
            table.push(module)?;
        }
    }

    Ok(LuaValue::Table(table))
}

pub fn build_api_table(lua: &Lua) -> LuaResult<LuaTable> {
    let table = lua.create_table()?;

    table.set("print", lua.create_function(print)?)?;
    table.set("used_memory", lua.create_function(used_memory)?)?;
    table.set("list_games", lua.create_function(list_games)?)?;
    table.set("version", "0.0")?;
    table.set("Storage", GameState::default().to_lua(lua)?)?;

    Ok(table)
}
