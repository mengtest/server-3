local skynet = require("skynet")

local CMD = {}

local configs = {
    GATEWAY_DISMETHOD = {}
}

local serviceAddr = {
    GATEWAY_DISMETHOD = {}
}

function CMD.getConfig(source, key)
    if not serviceAddr[key] then
        serviceAddr[key] = {}
    end
    if not serviceAddr[key][source] then
        serviceAddr[key][source] = true
    end
    return configs[key]
end

function CMD.saveConfig(key, value)
    configs[key] = value
    for k, v in pairs(serviceAddr[key] or {}) do
        skynet.call(k, "lua", "updateConfig")
    end
    return true
end

skynet.start(function()
    skynet.dispatch("lua", function(session, source, cmd, ...)
        local f = CMD[cmd]
        skynet.ret(skynet.pack(f(source, ...)))
	end)
end)