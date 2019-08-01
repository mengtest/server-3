local skynet = require("skynet")

skynet.start(function()
    skynet.uniqueservice(true, "game/login")
	skynet.exit()
end)