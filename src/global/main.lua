local skynet = require("skynet")

skynet.start(function()
    skynet.call(skynet.uniqueservice(true, "global/mongo"), "lua", "start")
	skynet.exit()
end)