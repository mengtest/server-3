local skynet = require("skynet")

skynet.start(function()
    skynet.newservice("global/main")
	skynet.exit()
end)