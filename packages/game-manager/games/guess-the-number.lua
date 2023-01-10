local utils = require("zane.utils")
local meta = require("zane.meta")
local inspect = require("inspect")

local guessTheNumber = {}
guessTheNumber.name = "Guess The Number"

--- Guess the number machine overview
--- 
--- State Enum:
---     
---     waiting_for_number
---           | state transition event = input-data
---           | emit action = 
---     waiting_for_guesses
---           | (state transition event = input-data)
---         ended

function guessTheNumber.initialize(game)
    game.state['range.upper'] = 15
    game.state['range.lower'] = 0

    game.state['status'] = 'waiting_for_number'

    game.state:commit("initialisation")
end

function guessTheNumber.handle(event)
    if event.game.state["status"] == "waiting_for_number" then
        utils.print("selected number")
        -- The user submitted a number
        local user_id = table.indexOf(event.game.initialization_data.users, event.user)
        event.state[string.format("to_guess.%s", user_id)] = event.data["number"]

        local done = true

        -- Check if all the numbers are submitted
        for i, _ in ipairs(event.game.initialization_data.users) do
            if event.state[string.format("to_guess.%s", i)] == nil then
                done = false
                break
            end
        end

        -- Go to the next step if all the numbers are submitted
        if done then
            event.state["status"] = "waiting_for_guesses"
        end

        -- Commit the data
        event.state:commit(string.format("<@%s> selected a number", event.user))
    elseif event.game.state["status"] == "waiting_for_guesses" then
        utils.print("guess process")
        -- Get our user index
        local user_id = table.indexOf(event.game.initialization_data.users, event.user)
        -- Get the next user index
        local opponent = (user_id + 1) % table.getn(event.game.initialization_data.users) + 1
        -- Get the number selected by the other user
        local number = event.state[string.format("to_guess.%s", opponent)]

        -- Compute the difference between the two members
        local delta = math.abs(tonumber(number) - tonumber(event.data['number']))
        event.state[string.format("deltas.%s", user_id)] = delta

        -- If all the deltas are present
        local done = true
        for i, _ in ipairs(event.game.initialization_data.users) do
            if event.state[string.format("deltas.%s", i)] == nil then
                done = false
                break
            end
        end

        if done then
            event.state["status"] = "finished"
        end

        event.state:commit(string.format("<@%s> tried to guess the number", event.user))
    end

    event.state:debug()

    return 1
end

return guessTheNumber
