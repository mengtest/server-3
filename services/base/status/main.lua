local skynet = require("skynet")

skynet.start(function()
    skynet.uniqueservice(true, "status")
    skynet.exit()
end)