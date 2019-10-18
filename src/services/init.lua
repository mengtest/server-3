local skynet = require("skynet")

skynet.start(function()
    skynet.newservice("debug_console", 8000)
    skynet.newservice("base/init")
    skynet.newservice("game/init")
    skynet.exit()
end)