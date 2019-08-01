local skynet = require("skynet")
local socket = require("skynet.socketdriver")
local parse = require("agent.socketDataParse")
require("utils.globalFunc")

local WATCHDOG
local GATE
local CLIENT

local CMD = {}
local lastTime

local function heartBeat(service, data)
	if skynet.now() - lastTime > 18000 then	--只有心跳
		CMD.close()
		return
	end
	CMD.sendData(0, service, {code = 0, index = data.index})
end

function CMD.start(conf)
	CLIENT = conf.client
	GATE= conf.gate
	WATCHDOG = conf.watchdog
	skynet.call(GATE, "lua", "openClient", CLIENT)
	lastTime = skynet.now()
end

function CMD.close()
	CMD.sendData(0, service, {code = 0, index = 0})
	skynet.call(GATE, "lua", "closeClient", CLIENT)
end

function CMD.disconnect()
	skynet.exit()
end

function CMD.receiveData(data)
	local datas = parse.parseData(data)
	for i,v in ipairs(datas) do
		if v.service == "heartbeat" then
			heartBeat(v.service, v.body)
		else
			lastTime = skynet.now()
			local service, method = string.match(v.service, "^(.+)%.(.+)$")
			local data = skynet.send(service, "lua", method, skynet.self(), v.body)
		end
	end
end

function CMD.sendData(code, service, data)
	dump(data)
	data = parse.packData(code, service, data)
	socket.send(CLIENT, data)
end

skynet.start(function()
	skynet.dispatch("lua", function(_,_, command, ...)
		local f = CMD[command]
		skynet.ret(skynet.pack(f(...)))
	end)
end)
