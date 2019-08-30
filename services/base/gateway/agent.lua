local skynet = require("skynet")
local socket = require("skynet.socketdriver")
local parse = require("base.gateway.dataparser")
require("globalFunc")

local WATCHDOG
local GATE
local CLIENT

local code = {
	SUCCESS = 0,
	ERROR_SECRET = 1
}

local CMD = {}
local lastTime

local function sendData(code, msg, service, data, secret)
	local sendData = parser.packData({code = code, msg = msg, })
end

local function heartBeat(service, data)
	if skynet.now() - lastTime > 60000 then	--10分钟只有心跳
		CMD.close()
		return
	end
	CMD.sendData(service, {code = 0, index = data.index})
end

local function sendData(code, msg, service, data, secret)
	dump(data)
	data = parse.packData(code, msg, service, data, secret)
	socket.send(CLIENT, data)
end

function CMD.start(conf)
	CLIENT = conf.client
	GATE= conf.gate
	WATCHDOG = conf.watchdog
	skynet.call(GATE, "lua", "openClient", CLIENT)
	lastTime = skynet.now()
end

function CMD.close()
	-- CMD.sendData(0, service, {code = 0, index = 0})
	skynet.call(GATE, "lua", "closeClient", CLIENT)
end

function CMD.disconnect()
	skynet.exit()
end

function CMD.receiveData(data)
	local datas = parse.parseData(data)
	dump(datas)
	for i,v in ipairs(datas) do
		if v.service == "heartbeat" then
			heartBeat(v.service, v.body)
		else
			lastTime = skynet.now()
			if v.service == "api-login.login" then
				local secret, loginData = skynet.call("api-login", "lua", "login", skynet.self(), v.body)
				if secret then
					sendData(code.SUCCESS, "", v.service, loginData, secret)
				else
					sendData(code.ERROR_SECRET, "", v.service)
				end
			elseif not v.secret or v.secret == "" then
				local service, method = string.match(v.service, "^(.+)%.(.+)$")
				sendData(code.ERROR_SECRET, "Secret is empty", service, {})
			else

			end
		end
	end
end

function CMD.sendData(service, data)
	sendData(code.SUCCESS, "", service, data)
end

skynet.start(function()
	skynet.dispatch("lua", function(_,_, command, ...)
		local f = CMD[command]
		skynet.ret(skynet.pack(f(...)))
	end)
end)
