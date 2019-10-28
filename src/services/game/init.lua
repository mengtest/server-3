local skynet = require("skynet")

skynet.start(function()
    skynet.newservice("game/login")
    skynet.newservice("game/user")
    skynet.exit()
end)