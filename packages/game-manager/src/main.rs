use std::env::current_dir;

use mlua::chunk;
use mlua::prelude::*;
use mlua::{Lua, LuaOptions, StdLib};
use walkdir::WalkDir;

fn used_memory(lua: &Lua, _: ()) -> LuaResult<usize> {
    Ok(lua.used_memory())
}

fn print(_: &Lua, arg: String) -> LuaResult<LuaValue> {
    println!("lua: {}", arg);

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
                .replace("/", ".")
                .replace(".lua", "");
            table.push(module)?;
        }
    }

    Ok(LuaValue::Table(table))
}

fn build_api_table(lua: &Lua) -> LuaResult<LuaTable> {
    let table = lua.create_table()?;

    table.set("print", lua.create_function(print)?)?;
    table.set("used_memory", lua.create_function(used_memory)?)?;
    table.set("list_games", lua.create_function(list_games)?)?;
    table.set("version", "0.0")?;

    Ok(table)
}

fn main() {
    let runtime = Lua::new_with(StdLib::ALL_SAFE, LuaOptions::default()).unwrap();

    runtime
        .globals()
        .set("zane_native", build_api_table(&runtime).unwrap())
        .unwrap();

    let current_folder = current_dir()
        .unwrap()
        .as_path()
        .to_owned()
        .to_str()
        .unwrap()
        .to_string();

    let path = format!("{cwd}/games/?.lua;{cwd}/lib/?.lua", cwd = current_folder);

    runtime
        .load(chunk!(
            package.path = $path
            require "zane.runtime"
        ))
        .exec()
        .unwrap();
}
