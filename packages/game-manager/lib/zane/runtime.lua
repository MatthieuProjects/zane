--- Bootstrap by importing all games into the lua require cache
local utils = require("zane.utils")
local meta = require("zane.meta")
local native = require("zane.native")

local runtime = {}
runtime.games = {}

--- Use the native call to list all the available games
local games_modules = native.list_games()

utils.print(string.format("Starting runner on Zane-API %s", meta.version))

--- Require all the game modules
for i, module in ipairs(games_modules) do
    utils.print(string.format("[%d] Loading %s", i, module))
    require(module)
end

--- Handle creation events
function runtime.initialize_state(command, data)
    local game = package.loaded[command]
    if game ~= nil then
        utils.print("Initializing game", game.name)
        return game.initialize(data)
    end
    return nil
end

--- Handle an event
function runtime.consume_events_stream(command, data)
    --- Consume an event
    while true do
        local game = package.loaded[command]
        local ret
        if game ~= nil then
            ret = game.handle(data)
        end
        command, data = coroutine.yield(ret)
        
    end
end

return runtime
