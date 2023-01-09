local utils = {}

--- Simple function for logging using the rust logger
--- warn: May change in the future because of logging levels
function utils.print(message)
    zane_native.print(message)
end

return utils
