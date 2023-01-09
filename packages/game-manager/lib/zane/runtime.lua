--- Bootstrap by importing all games into the lua require cache
local utils = require("zane.utils")
local meta = require("zane.meta")

--- Use the native call to list all the available games
local games_modules = zane_native.list_games()

utils.print(string.format("Starting runner on Zane-API %s", meta.version))

--- Require all the game modules
for i, module in ipairs(games_modules) do
    utils.print(string.format("[%d] Loading %s", i, module))
    require(module)
end

--- Utils by the rust runtime to 
function execute_event(game, state)

end
