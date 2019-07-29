local skynet = require("skynet")

skynet.start(function()
    skynet.newservice("global")
    skynet.newservice("agent")
	skynet.exit()
end)