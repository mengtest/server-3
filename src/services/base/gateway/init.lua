local skynet = require("skynet")

skynet.start(function()
    skynet.call(skynet.uniqueservice("base/gateway/pbc"), "lua", "start")
    skynet.call(skynet.uniqueservice("base/gateway/watchdog"), "lua", "start")
    skynet.exit()
end)