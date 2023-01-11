use mlua::{prelude::*, Variadic};
use tracing::info;

use super::storelog::GameState;

fn used_memory(lua: &Lua, _: ()) -> LuaResult<usize> {
    Ok(lua.used_memory())
}

fn print(_: &Lua, arg: Variadic<String>) -> LuaResult<LuaValue> {
    info!("{}", arg.into_iter().collect::<Vec<String>>().join(" "));

    Ok(LuaValue::Nil)
}

pub fn build_api_table(lua: &Lua) -> LuaResult<LuaTable> {
    let table = lua.create_table()?;

    table.set("print", lua.create_function(print)?)?;
    table.set("used_memory", lua.create_function(used_memory)?)?;
    table.set("version", "0.0")?;
    table.set("Storage", GameState::default().to_lua(lua)?)?;

    Ok(table)
}
