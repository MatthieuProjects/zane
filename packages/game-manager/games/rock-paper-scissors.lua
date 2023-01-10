local utils = require("zane.utils")
local meta = require("zane.meta")

--- Rock Paper Scissors State machine overview
--- 
--- State Enum:
---     waiting-for-data { choises: [value?, value?] }
---     ended { winner: [user], choises: [value, value] }
---     
---     waiting-for-data
---           | (state transition event = input-data)
---     waiting-for-data
---           | (state transition event = input-data)
---         ended

