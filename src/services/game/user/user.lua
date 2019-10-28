local skynet = require("skynet")
local config = require("services.game.user.config")
require("framework.functions")

local CMD = {}

function CMD.register()
    local uid = skynet.call("mongo", "lua", "getInc", "UserId")
    local user = {
        uid = uid,
        nick = "Guest_" .. uid
    }
    local bool = skynet.call("mongo", "lua", "insert", "User", user)
    if bool then
        return user
    end
end

function CMD.get(uid)
    local user = skynet.call("mongo", "lua", "findOne", "User", {uid = uid})
    if user then
        return {
            uid = uid,
            nick = user.nick
        }
    end
end

function CMD.modify(uid, userData)
    local user = skynet.call("mongo", "lua", "findOne", "User", {uid = uid})
    if user then
        table.merge(user, userData)
    end
    local bool = skynet.call("mongo", "lua", "update", "User", user)
    return bool
end

skynet.start(function ()
    skynet.dispatch("lua", function(_, _, command, ...)
		local f = CMD[command]
		skynet.ret(skynet.pack(f(...)))
    end)
end)