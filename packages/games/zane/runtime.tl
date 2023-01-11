--- Bootstrap by importing all games into the lua require cache
local utils = require("zane.utils")
local meta = require("zane.meta")
local native = require("zane.native")
local module = require("zane.module")

local type Runtime = record
    initialize_state: function(string, native.Game): nil
    consume_events_stream: function(string, native.GameEvent): nil
end
local runtime: Runtime = {}

utils.print(string.format("Starting runner on Zane-API %s", meta.version))

--- Handle creation events
function runtime.initialize_state(command: string, data: native.Game): nil
    local game = package.loaded[string.format("games.%s", command)] as module.Module
    if game ~= nil then
        utils.print("Initializing game", game.name)
        return game.initialize(data)
    end
    return nil
end

--- Handle an event
function runtime.consume_events_stream(command: string, data: native.GameEvent): nil
    --- Consume an event
    while true do
        local game = package.loaded[string.format("games.%s", command)] as module.Module
        if game ~= nil then
            game.handle(data)
        end
        command, data = coroutine.yield(nil) as (string, native.GameEvent)
    end
end

return runtime
