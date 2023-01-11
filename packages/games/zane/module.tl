local native = require("zane.native")

local record Native
    type Module = record
        name: string
        initialize: function(native.Game): nil
        handle: function(native.GameEvent): nil
    end
end

return Native
