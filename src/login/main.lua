local skynet = require("skynet")

skynet.start(function()
    skynet.uniqueservice(true, "login/login")
	skynet.exit()
end)