local skynet = require("skynet")
local socket = require("skynet.socket")
local parse = require("agent.socketDataParse")

local WATCHDOG
local CLIENT

local CMD = {}
local REQUEST = {}

local function request(name, args, response)
	local f = assert(REQUEST[name])
	local r = f(args)
	if response then
		return response(r)
	end
end

skynet.register_protocol {
	name = "client",
	id = skynet.PTYPE_CLIENT,
	unpack = function (msg, sz)
		local str = skynet.tostring(msg, sz)
		print(#str)
		local datas = parse.parseData(str)
		return datas
	end,
	dispatch = function (fd, _, type, ...)
		assert(fd == CLIENT)	-- You can use fd to reply message
		skynet.ignoreret()	-- session is fd, don't call skynet.ret
		skynet.trace()
		skynet.error("client", type, ...)
	end
}

function CMD.start(conf)
	local gate = conf.gate
	WATCHDOG = conf.watchdog
	CLIENT = conf.client
	skynet.call(gate, "lua", "forward", CLIENT)
end

function CMD.disconnect()
	-- todo: do something before exit
	skynet.exit()
end

skynet.start(function()
	skynet.dispatch("lua", function(_,_, command, ...)
		skynet.trace()
		local f = CMD[command]
		skynet.ret(skynet.pack(f(...)))
	end)
end)
