local skynet = require("skynet")
local socket = require("skynet.socketdriver")
local parse = require("base.gateway.dataparser")
require("utils.globalFunc")
require("utils.stringUtils")
require("utils.tableUtils")

local WATCHDOG
local GATE
local CLIENT
local UID

local CMD = {}

local function sendData(code, service, data)
	data = parse.packData(code, service, data)
	socket.send(CLIENT, data)
end

function CMD.start(conf)
	CLIENT = conf.client
	GATE= conf.gate
	WATCHDOG = conf.watchdog
end

function CMD.bindUser(uid, client)
	UID = uid
	CLIENT = client
	return true
end

function CMD.exit()
	skynet.exit()
end

function CMD.receiveData(data)
	skynet.error("----------------------------------------agent", CLIENT)
	local datas = parse.parseData(data)
	for i,v in ipairs(datas) do
		local serviceName, methodName = string.match(v.service, "^(.+)%.(.+)$")
		if serviceName == "socket" then
		
		else
			local code, ret = skynet.call("status", "lua", "callServiceSafeMethod", serviceName, methodName, skynet.self(), v.body)
			sendData(code, v.service, ret)
		end
	end
end

function CMD.getAddress()
	return skynet.call(WATCHDOG, "lua", "getAddressById", CLIENT)
end

skynet.start(function()
	skynet.dispatch("lua", function(_,_, command, ...)
		local f = CMD[command]
		skynet.ret(skynet.pack(f(...)))
	end)
end)
