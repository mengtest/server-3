local skynet = require("skynet")
require("skynet.manager")

local skynetEx = require("framework.extend.skynetEx")
local config = require("base.status.config")
local code = config.code
require("framework.utils.functions")

local services = {}

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
    local result = skynetEx.timeoutCall(function(...)
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