local skynet = require("skynet")

skynet.start(function()
    skynet.newservice("base/status")
    skynet.newservice("base/gateway")
    skynet.newservice("base/database")
    skynet.newservice("base/http")
    skynet.exit()
end)