local skynet = require("skynet")

skynet.start(function ()
    skynet.call(skynet.uniqueservice(true, "agent/watchdog"), "lua", "start", {nodelay = true})
    skynet.exit()
end)