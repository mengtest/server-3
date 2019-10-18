local skynet = require("skynet")
local socket = require("skynet.socketdriver")
local parse = require("base.gateway.dataparser")
local code = require("config.codeConfig").serviceErrorCode
require("framework.functions")

local WATCHDOG
local GATE
local CLIENT

local CMD = {}

local function sendData(service, code, data)
	dump(data)
	data = parse.packData(code, service, data)
	socket.send(CLIENT, data)
end

function CMD.start(conf)
	CLIENT = conf.client
	GATE= conf.gate
	WATCHDOG = conf.watchdog
	skynet.call(GATE, "lua", "forward", CLIENT, skynet.self())
end

function CMD.exit()
	skynet.exit()
end

function CMD.receiveData(data)
	local datas = parse.parseData(data)
	for i,v in ipairs(datas) do
		local serviceName, methodName = string.match(v.service, "^(.+)%.(.+)$")
		local params = v.body
		if serviceName == "socket" then
			sendData(v.service, code.ERROR_SERVICE)
		else
			sendData(v.service, skynet.call("status", "lua", "callServiceSafeMethod", serviceName, methodName, skynet.self(), params))
		end
	end
end

skynet.start(function()
	skynet.dispatch("lua", function(_,_, command, ...)
		local f = CMD[command]
		skynet.ret(skynet.pack(f(...)))
	end)
end)
