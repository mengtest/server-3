local skynet = require("skynet")

skynet.start(function ()
    skynet.call(skynet.newservice("agent/watchdog"), "lua", "start", {port = 8888, maxclient = 64, nodelay = true})
    skynet.exit()
end)