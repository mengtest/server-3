local skynet = require("skynet")

skynet.start(function()
    skynet.newservice("base/init")
    skynet.newservice("game/init")
    skynet.exit()
end)