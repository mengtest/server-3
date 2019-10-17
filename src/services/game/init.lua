local skynet = require("skynet")

skynet.start(function()
    skynet.newservice("game/login")
    skynet.exit()
end)