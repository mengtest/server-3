local skynet = require("skynet")
local socket = require("skynet.socketdriver")
local parse = require("base.gateway.dataparser").new()
local log = require("framework.extend.log")
require("framework.utils.functions")

local statusCode = require("base.status.config").code

local WATCHDOG
local GATE
local CLIENT
local UID

local ALIVETIME

local CMD = {}

local function sendData(service, code, data)
	if CLIENT then
		log.info(data)
		data = parse:packData(code, service, data)
		socket.send(CLIENT, data)
	end
end

function CMD.start(conf)
	ALIVETIME = skynet.now()
	CLIENT = conf.client
	GATE= conf.gate
    WATCHDOG = conf.watchdog
	skynet.call(GATE, "lua", "forward", CLIENT, skynet.self())
end

function CMD.close()
	skynet.exit()
end

function CMD.closeConnect()
	ALIVETIME = nil
	CLIENT = nil
	UID = nil
end

function CMD.receiveData(data)
	ALIVETIME = skynet.now()
	local datas = parse:parseData(data)
    log.debug(datas)
	for i,v in ipairs(datas) do
		local serviceName, methodName = string.match(v.service, "^(.+)%.(.+)$")
		local params = v.body
		if serviceName == "socket" and methodName == "heartbeat" then
			sendData(v.service, statusCode.SUCCESS, {})
		elseif serviceName == "login" and methodName == "login" then
            local cd, ret = skynet.call("status", "lua", "callServiceSafeMethod", serviceName, methodName, nil, params)
			if cd == statusCode.SUCCESS and ret.code == 1 then
				UID = ret.user.uid
                skynet.call(WATCHDOG, "lua", "bindAgentByUid", CLIENT, ret.user.uid)
            end
            sendData(v.service, cd, ret)
		else
			sendData(v.service, skynet.call("status", "lua", "callServiceSafeMethod", serviceName, methodName, UID, params))
		end
	end
end

function CMD.isAlive()
	if ALIVETIME then
		return (skynet.now() - ALIVETIME) < 120 * 100
	end
end

function CMD.sendData(service, data)
	sendData(service, statusCode.SUCCESS, data)
end

skynet.start(function()
	skynet.dispatch("lua", function(_, _, command, ...)
		local f = CMD[command]
		skynet.ret(skynet.pack(f(...)))
	end)
end)
