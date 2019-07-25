local skynet = require("skynet")

skynet.start(function()
    skynet.newservice("mongodb")
    skynet.call("db", "lua", "start")
	skynet.exit()
end)