local skynet = require("skynet")

skynet.start(function()
    skynet.uniqueservice("base/http/http")
    skynet.exit()
end)