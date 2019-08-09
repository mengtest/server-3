local skynet = require("skynet")
require("skynet.manager")

local services = {}
local serviceStatus = {}
local serviceMethods = {}

local code = {
    SUCCESS = 0,
    TIMEOUT = 1,
    ERROR_METHOD = 2,
    ERROR_SERVICE = 3
}

local function timeoutCall(func, service, ...)
    local co = coroutine.running()
    local result = false
    skynet.fork(function (service, ...)
        result = table.pack(pacll(func, service, ...))
        if co then
            skynet.wakeup(co)
        end
    end, service, ...)

    skynet.sleep(300, co)
    co = nil
    return result
end

local function checkServiceAlive(service, serviceName)
    local result = timeoutCall(function(...)
        skynet.queryservice(true, ...)
    end, service)
    if result and #result > 0 then
        serviceStatus[serviceName] = true
    else
        serviceStatus[serviceName] = false
    end
    return serviceStatus[serviceName]
end

local function closeService(serviceName)
    local service = services[serviceName]
    if service and checkServiceAlive(service, serviceName) then
        skynet.kill(service)
    end
end

local function ckechServiceMethod(serviceName, methodName)
    local methods = serviceMethods[serviceName]
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

function CMD.registerService(service, serviceName, methods)
    closeService(serviceName)
    services[serviceName] = service
    serviceMethods[serviceName] = methods
end

function CMD.unRegisterService(serviceName)
    closeService(serviceName)
    services[serviceName] = nil
    serviceMethods[serviceName] = {}
end

function CMD.callServiceSafeMethod(serviceName, methodName, ...)
    local bool, ret = ckechServiceMethod(serviceName, methodName)
    if bool then
        return callServiceMethod(serviceName, methodName, ...)
    else
        return ret
    end
end

function CMD.callServiceMethod(serviceName, methodName, ...)
    return callServiceMethod(serviceName, methodName, ...)
end

skynet.start(function()
    skynet.dispatch("lua", function(session, source, cmd, ...)
        local f = CMD[cmd]
        skynet.ret(skynet.pack(f(...)))
    end)
    skynet.register("status")
end)