local skynet = require("skynet")
require("skynet.manager")
local config = require("base.status.config")
local code = config.code
require("framework.functions")

local services = {}


local function timeoutCall(func, ...)
    local co = coroutine.running()
    local result = {}
    skynet.fork(function (...)
        result = table.pack(pcall(...))
        if co then
            skynet.wakeup(co)
        end
    end, func, ...)

    skynet.sleep(300, co)
    co = nil
    table.remove(result, 1)
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
    -- local methods = config.servicePublicMethod[serviceName]
    -- if type(methods) == "table" then
    --     for i, v in ipairs(methods) do
    --         if methodName == v then
    --             return true
    --         end
    --     end
    -- else
    --     return false, code.ERROR_SERVICE
    -- end
    -- return false, code.ERROR_METHOD
    return true
end

local function callServiceMethod(serviceName, methodName, ...)
    local result = timeoutCall(function(...)
        return skynet.call(...)
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

skynet.start(function()
    skynet.dispatch("lua", function(session, source, cmd, ...)
        local f = CMD[cmd]
        skynet.ret(skynet.pack(f(...)))
    end)

    skynet.register("status")
end)