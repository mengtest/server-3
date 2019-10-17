local skynet = require("skynet")

skynet.start(function()
    skynet.call("status", "lua", "registerService", skynet.newservice("game/login/login"), "login")
	skynet.exit()
end)