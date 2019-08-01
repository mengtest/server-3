local skynet = require("skynet")
require("skynet.manager")
require("utils.globalFunc")

local CMD = {}

function CMD.login(agent, data)
    local result = {code = 1, msg = ""}
    local account = data.account
    local password = data.password or ""
    local user = skynet.call("mongo", "lua", "findOne", "users", {account = account})
    if user then
        if user.password == password then
            result = {code = 0, msg = "", sid = user.sid}
        else
            result = {code = 1, msg = "error"}
        end
    else
        local userInc = skynet.call("mongo", "lua", "findOne", "increase", {key = "users"})
        local sid = 1
        if userInc then
            sid = userInc.value + 1
            skynet.call("mongo", "lua", "update", "increase", {key = "users"}, {key = "users", value = sid})
        else
            skynet.call("mongo", "lua", "insert", "increase", {key = "users", value = 1})
        end
        dump(userInc)
        skynet.call("mongo", "lua", "insert", "users", {account = account, password = password, sid = sid})
        result = {code = 0, msg = "", sid = sid}
    end
    skynet.send(agent, "lua", "sendData", 0, "api-login.login", result)
end

skynet.start(function ()
    skynet.dispatch("lua", function(_,_, command, ...)
		local f = CMD[command]
		skynet.ret(skynet.pack(f(...)))
    end)
    
    skynet.register("api-login")
end)