local function debug()
    local dbg = require("emmy_core")
    dbg.tcpConnect("localhost", 9966)
end

return debug