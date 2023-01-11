use mlua::prelude::*;
use mlua::{MetaMethod, UserData};
use serde::Serialize;
use std::collections::HashMap;
use std::mem::take;
use tracing::debug;

#[derive(Debug, Clone, Default, Serialize)]
pub struct UpdateBlock {
    pub name: String,
    pub field_updates: HashMap<String, String>,
}

#[derive(Debug, Default, Clone, Serialize)]
pub struct GameState {
    pub current: HashMap<String, String>,
    current_updates: HashMap<String, String>,
    logs: Vec<UpdateBlock>,
}

impl UserData for GameState {
    fn add_methods<'lua, M: mlua::UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_meta_method(MetaMethod::Index, |lua, this, key: String| {
            debug!("reading {}", key);
            let value = this
                .current
                .get(&key)
                .map::<Result<LuaValue, LuaError>, _>(|b| Ok(b.clone().to_lua(lua)?))
                .or_else(|| Some(Ok(LuaValue::Nil)))
                .expect("failed")?;
            debug!("got {:?}", value);
            Ok(value)
        });
        methods.add_meta_method_mut(
            MetaMethod::NewIndex,
            |_, this, (key, value): (String, LuaString)| {
                let str = value.to_str()?.to_string();
                debug!("got update in {}:  newval {}", key, str);

                if let Some(val) = this.current.get_mut(&key) {
                    *val = str.clone();
                } else {
                    this.current.insert(key.clone(), str.clone());
                }

                this.current_updates.insert(key, str);

                Ok(())
            },
        );

        methods.add_method_mut("commit", |_, this, name: String| {
            let block = UpdateBlock {
                name,
                field_updates: take(&mut this.current_updates),
            };

            debug!(
                "submitting update \"{}\": {:?}",
                block.name, block.field_updates
            );

            this.logs.push(block);
            Ok(())
        });

        methods.add_method_mut("debug", |_, this, _: ()| {
            debug!("{:#?}", this);
            Ok(())
        });
    }
}
