local skynet = require("skynet")
local socket = require("skynet.socketdriver")
local parse = require("base.gateway.dataparser")
local code = require("base.status.config").code
local log = require("framework.extend.log")
require("framework.utils.functions")

local WATCHDOG
local GATE
local CLIENT
local UID

local CMD = {}

local function sendData(service, code, data)
	log.debug(data)
	data = parse.packData(code, service, data)
	socket.send(CLIENT, data)
end

function CMD.start(conf)
	CLIENT = conf.client
	GATE= conf.gate
    WATCHDOG = conf.watchdog
    UID = conf.uid
	skynet.call(GATE, "lua", "forward", CLIENT, skynet.self())
end

function CMD.exit()
	skynet.exit()
end

function CMD.receiveData(data)
	local datas = parse.parseData(data)
    log.debug(datas)
	for i,v in ipairs(datas) do
		local serviceName, methodName = string.match(v.service, "^(.+)%.(.+)$")
		local params = v.body
		if serviceName == "socket" and methodName == "heartbeat" then
			sendData(v.service, code.SUCCESS, {code = 1, index = params.index})
		else
			sendData(v.service, skynet.call("status", "lua", "callServiceSafeMethod", serviceName, methodName, UID, params))
		end
	end
end

skynet.start(function()
	skynet.dispatch("lua", function(_,_, command, ...)
		local f = CMD[command]
		skynet.ret(skynet.pack(f(...)))
	end)
end)
