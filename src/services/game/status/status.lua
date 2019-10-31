local skynet = require("skynet")
local config = require("services.game.status.config")
local code = config.code
require("framework.utils.functions")

local CMD = {}

local function errorback(code)
    return {
        code = code,
        msg = config.errorStr[code]
    }
end

local function getStatusInfo(uid)
    return (skynet.call("mongo", "lua", "findOne", "Status", {uid = uid}))
end

local function saveStatusInof(info)
    return skynet.call("mongo", "lua", "update", "Status", {uid = info.uid}, info, true)
end

function CMD.setOnline(uid, onlineStatus)
    local info = getStatusInfo(uid) or {uid = uid}
    info.onlineStatus = onlineStatus
    if saveStatusInof(info) then
        return true
    end
    return false
end

function CMD.checkOnline(uid)
    local info = getStatusInfo(uid)
    if info then
        return info.onlineStatus == config.onlineStatus.ONLINE
    end
end

function CMD.setAppInfo(uid, data)
    local info = getStatusInfo(uid) or {uid = uid}
    table.merge(info, data)
    if saveStatusInof(info) then
        return true
    end
    return false
end

function CMD.getAppInfo(uid)
    return getStatusInfo(uid)
end

skynet.start(function ()
    skynet.dispatch("lua", function(_, _, command, ...)
		local f = CMD[command]
		skynet.ret(skynet.pack(f(...)))
    end)
end)