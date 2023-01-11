local utils = require("zane.utils")
local module = require("zane.module")
local native = require("zane.native")
local meta = require("zane.meta")

local guessTheNumber: module.Module = {}
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

function guessTheNumber.initialize(game: native.Game): nil
    game.state['status'] = 'waiting_for_number'

    game.state:commit("initialisation")
end

function guessTheNumber.handle(event: native.GameEvent): nil
    if event.game.state["status"] == "waiting_for_number" then
        utils.print("selected number")
        -- The user submitted a number
        local user_id = table.indexOf(event.game.initialization_data.users as {string}, event.user)
        event.game.state[string.format("to_guess.%s", user_id)] = event.properties["number"]

        local done = true

        -- Check if all the numbers are submitted
        for i, _ in ipairs(event.game.initialization_data.users as {string}) do
            if event.game.state[string.format("to_guess.%s", i)] == nil then
                done = false
                break
            end
        end

        -- Go to the next step if all the numbers are submitted
        if done then
            event.game.state["status"] = "waiting_for_guesses"
        end

        -- Commit the data
        event.game.state:commit(string.format("<@%s> selected a number", event.user))
    elseif event.game.state["status"] == "waiting_for_guesses" then
        utils.print("guess process")
        -- Get our user index
        local user_id = table.indexOf(event.game.initialization_data.users as {string}, event.user)
        -- Get the next user index
        local opponent = (user_id + 1) % #event.game.initialization_data.users as {string} + 1
        -- Get the number selected by the other user
        local number = event.game.state[string.format("to_guess.%s", opponent)] as number

        -- Compute the difference between the two members
        local delta = math.abs(number - event.properties["number"] as number)
        event.game.state[string.format("deltas.%s", user_id)] = delta

        -- If all the deltas are present
        local done = true
        for i, _ in ipairs(event.game.initialization_data.users as {string}) do
            if event.game.state[string.format("deltas.%s", i)] == nil then
                done = false
                break
            end
        end

        if done then
            local lowk, lowv: string, string
            lowv = '999999'

            -- Find the winner
            for i, id in ipairs(event.game.initialization_data.users as {string}) do
                if tonumber(lowv) > tonumber(event.game.state[string.format("deltas.%s", i)]) then
                    lowk = id
                    lowv = string.format("%i", event.game.state[string.format("deltas.%s", i)])
                end
            end

            event.game.state['winner'] = lowk
            event.game.state["status"] = "finished"
        end

        -- Commit the data
        event.game.state:commit(string.format("<@%s> tried to guess the number", event.user))
    end

    return nil
end

return guessTheNumber
