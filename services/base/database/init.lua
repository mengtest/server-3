local skynet = require("skynet")

skynet.start(function()
    skynet.call(skynet.uniqueservice("base/database/mongo"), "lua", "start")
	skynet.exit()
end)