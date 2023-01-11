local record Native
    --- Version of the native api
    version: string

    --- Print some data
    print: function(...: string): nil
    --- Returns the amount of memory used by the lua runtime
    used_memory: function(): number

    --- Represents 
    record Game
        userdata
        state: State
        initialization_data: {string:any}
    end

    record State
        userdata
        type StateValue = string | number
        metamethod __newindex: function(State, string, StateValue): nil
        metamethod __index: function(State, string): StateValue

        commit: function(State, string): nil
        debug: function(State): nil
    end

    record GameEvent
        userdata
        properties: {string:string}
        game: Game
        user: string
    end
end

return Native
