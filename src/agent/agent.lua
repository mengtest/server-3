local skynet = require "skynet"
local socket = require "skynet.socket"

local WATCHDOG
local GATE
local CLIENT

local CMD = {}

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
	print(data)
end

skynet.start(function()
	skynet.dispatch("lua", function(_,_, command, ...)
		-- skynet.trace()
		local f = CMD[command]
		skynet.ret(skynet.pack(f(...)))
	end)
end)
