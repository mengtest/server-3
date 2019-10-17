local skynet = require("skynet")
local socket = require("skynet.socketdriver")
local parse = require("base.gateway.dataparser").new()
local code = require("config.codeConfig")
require("framework.functions")

local WATCHDOG
local GATE

local CMD = {}

local function sendData(client, service, code, data)
	dump(data)
	data = parse.packData(code, service, data)
	socket.send(client, data)
end

function CMD.start(conf)
	GATE = conf.gate
	WATCHDOG = conf.watchdog
end

function CMD.receiveData(data, client, addr)
	local datas = parse.parseData(data)
    dump(datas)
	for i,v in ipairs(datas) do
        local serviceName, methodName = string.match(v.service, "^(.+)%.(.+)$")
        local params = checktable(v.body)
		if serviceName == "socket" then
            if methodName == "auth" then
                local secret = string.uuid()
                sendData(client, v.service, code.serviceErrorCode.SUCCESS, {code = 0, secret = secret})
                skynet.(WATCHDOG, "lua", "bindClient", client, secret, params.secret)
            end
        elseif serviceName == "login" and methodName == "login" then
            sendData(client, v.service, skynet.call("status", "lua", "callServiceSafeMethod", serviceName, methodName, params, client, addr))
        else
            sendData(client, v.service, code.serviceErrorCode.ERROR_PARAM)
        end
	end
end

skynet.start(function()
	skynet.dispatch("lua", function(_,_, command, ...)
		local f = CMD[command]
		skynet.ret(skynet.pack(f(...)))
	end)
end)
