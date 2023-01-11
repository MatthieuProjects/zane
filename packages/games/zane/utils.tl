local utils = {}
local native = require("zane.native")

--- Simple function for logging using the rust logger
--- warn: May change in the future because of logging levels
function utils.print(...: string)
    native.print(...)
end

function table.indexOf<V>(t: {V}, object: V): number
    for i, v in ipairs(t) do
        if object == v then
            return i
        end
    end
end

return utils
