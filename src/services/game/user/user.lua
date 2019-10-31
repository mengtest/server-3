local skynet = require("skynet")
local config = require("services.game.user.config")
require("framework.utils.functions")

local CMD = {}

local function newUser(user)
    return skynet.call("mongo", "lua", "insert", "User", user)
end

local function setUser(user)
    return skynet.call("mongo", "lua", "update", "User", {uid = user.uid}, user)
end

local function getUser(uid)
    return skynet.call("mongo", "lua", "findOne", "User", {uid = uid})
end

function CMD.register()
    local uid = skynet.call("mongo", "lua", "getInc", "UserId")
    local user = {
        uid = uid,
        nick = "Guest_" .. uid
    }
    local bool = newUser(user)
    if bool then
        return user
    end
end

function CMD.get(uid)
    local user = getUser(uid)
    return {
        uid = uid,
        nick = user.nick
    }
end

function CMD.modify(uid, userData)
    local user = getUser(uid)
    if user then
        table.merge(user, userData)
        return setUser(user)
    end
    return false
end

skynet.start(function ()
    skynet.dispatch("lua", function(_, _, command, ...)
		local f = CMD[command]
		skynet.ret(skynet.pack(f(...)))
    end)
end)