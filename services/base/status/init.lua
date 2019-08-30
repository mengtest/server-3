local skynet = require("skynet")

skynet.start(function()
    skynet.uniqueservice("base/status/status")
    skynet.exit()
end)