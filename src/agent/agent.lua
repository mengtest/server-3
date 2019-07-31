local skynet = require("skynet")
local socket = require("skynet.socketdriver")
local parse = require("agent.socketDataParse")
require("utils.globalFunc")

local WATCHDOG
local GATE
local CLIENT

local heartBeatIndex = 1

local CMD = {}

local function heartBeat(service, data)
	heartBeatIndex = data.index
	CMD.sendData(0, service, {code = 0, index = heartBeatIndex})
end

function CMD.start(conf)
	CLIENT = conf.client
	GATE= conf.gate
	WATCHDOG = conf.watchdog
	skynet.call(GATE, "lua", "openClient", CLIENT)
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
			local service, method = string.match(v.service, "^(.+)%.(.+)$")
			skynet.send(v.service, "lua", skynet.self(), method, v.body)
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
		-- skynet.trace()
		local f = CMD[command]
		skynet.ret(skynet.pack(f(...)))
	end)
end)
