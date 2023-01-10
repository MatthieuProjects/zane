local utils = {}
local native = require("zane.native")

--- Simple function for logging using the rust logger
--- warn: May change in the future because of logging levels
function utils.print(...)
    native.print(...)
end

function table.indexOf(t, object)
    if type(t) ~= "table" then error("table expected, got " .. type(t), 2) end

    for i, v in pairs(t) do
        if object == v then
            return i
        end
    end
end

return utils
