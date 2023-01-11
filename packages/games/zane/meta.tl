local native = require("zane.native")

local record Meta 
    version: string
    memoryUsage: function(): number
end
local meta: Meta = {}

meta.version = native.version

function meta.memoryUsage(): number
    return native.used_memory()
end

return meta
