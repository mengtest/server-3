local skynet = require("skynet")

skynet.start(function()
    skynet.call("status", "lua", "registerService", skynet.newservice("game/user/user"), "user")
	skynet.exit()
end)