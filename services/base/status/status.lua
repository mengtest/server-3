local skynet = require("skynet")
require("skynet.manager")
local serviceConfig = require("base.status.serviceConfig")

local services = {}
local users = {}

local code = {
    SUCCESS = 0,
    TIMEOUT = 1,
    ERROR_METHOD = 2,
    ERROR_SERVICE = 3
}

local function timeoutCall(func, ...)
    local co = coroutine.running()
    local result = false
    skynet.fork(function (...)
        result = table.pack(pacll(...))
        if co then
            skynet.wakeup(co)
        end
    end, func, ...)

    skynet.sleep(300, co)
    co = nil
    return result
end

local function closeService(serviceName)
    local service = services[serviceName]
    if service then
        skynet.kill(service)
    end
    services[serviceName] = nil
end

local function checkServiceMethod(serviceName, methodName)
    local methods = serviceConfig.serviceMethod[serviceName]
    if type(methods) == "table" then
        for i, v in ipairs(methods) do
            if methodName == v then
                return true
            end
        end
    else
        return false, code.ERROR_SERVICE
    end
    return false, code.ERROR_METHOD
end

local function callServiceMethod(serviceName, methodName, ...)
    local result = timeoutCall(function(...)
        skynet.call(...)
    end, services[serviceName], "lua", methodName, ...)
    if result then
        return code.SUCCESS, table.unpack(result)
    else
        return code.TIMEOUT
    end
end

local CMD = {}

function CMD.registerService(service, serviceName)
    closeService(serviceName)
    services[serviceName] = service
end

function CMD.callServiceSafeMethod(serviceName, methodName, ...)
    local bool, ret = checkServiceMethod(serviceName, methodName)
    if bool then
        return callServiceMethod(serviceName, methodName, ...)
    else
        return ret
    end
end

function CMD.callServiceMethod(serviceName, methodName, ...)
    return callServiceMethod(serviceName, methodName, ...)
end

function CMD.changeUserStatus(id, status)
    users[id] = onlineStatus[status]
end

function CMD.getUserStatusById(id)
    return users[id] or onlineStatus.offline
end

function CMD.getUserStatusByIds(ids)
    local result = {}
    for _, v in pairs(ids) do
        result[v] = CMD.getUserStatusById(v)
    end
end

skynet.start(function()
    skynet.dispatch("lua", function(session, source, cmd, ...)
        local f = CMD[cmd]
        skynet.ret(skynet.pack(f(...)))
    end)

    skynet.register("status")
end)