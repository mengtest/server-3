local skynet = require("skynet")

skynet.start(function()
    skynet.newservice("global")
    skynet.newservice("game")
    skynet.newservice("agent")
	skynet.exit()
end)