local skynet = require("skynet")

skynet.start(function()
    skynet.call("status", "lua", "registerService", skynet.newservice("game/login/login"), "login")
    skynet.call("status", "lua", "registerService", skynet.newservice("game/user/user"), "user")
    skynet.call("status", "lua", "registerService", skynet.newservice("game/status/status"), "status")
    skynet.exit()
end)