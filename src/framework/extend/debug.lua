local debug = {}
local skynet = require("skynet")

local function start()
    local breakSocketHandle, debugXpCall = require("framework.lib.LuaDebug")("localhost", 7002)
    while true do
        debugXpCall()
        skynet.sleep(30)
    end
end

setmetatable(debug, {__call = function(self)
    start()
end})

return debug