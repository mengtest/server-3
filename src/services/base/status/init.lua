local skynet = require("skynet")

skynet.start(function()
    skynet.uniqueservice("base/status/serviceStatus")
    skynet.exit()
end)