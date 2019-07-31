local skynet = require("skynet")
require("skynet.manager")

local CMD = {}
local SOCKET = {}
local gate
local agent = {}

function SOCKET.connect(fd, addr)
	skynet.error("New client from : " .. addr)
	agent[fd] = skynet.newservice("agent/agent")
	skynet.call(agent[fd], "lua", "start", { gate = gate, client = fd, watchdog = skynet.self() })
end

local function close_agent(fd)
	local a = agent[fd]
	agent[fd] = nil
	if a then
		skynet.call(gate, "lua", "kick", fd)
		-- disconnect never return
		skynet.send(a, "lua", "disconnect")
	end
end

function SOCKET.disconnect(fd)
	print("socket close",fd)
	close_agent(fd)
end

function SOCKET.error(fd, msg)
	print("socket error",fd, msg)
	close_agent(fd)
end

function SOCKET.warning(fd, size)
	print("socket warning", fd, size)
end

function SOCKET.data(fd, data)
	local a = agent[fd]
	if a then
		skynet.call(a, "lua", "receiveData", data)
	end
end

function CMD.start(conf)
	skynet.call(gate, "lua", "start", skynet.self())
	skynet.call(gate, "lua", "open", conf)
end

function CMD.close(fd)
	close_agent(fd)
end

skynet.start(function()
	skynet.dispatch("lua", function(session, source, cmd, subcmd, ...)
		if cmd == "socket" then
			local f = SOCKET[subcmd]
			skynet.ret(skynet.pack(f(...)))
		else
			local f = assert(CMD[cmd])
			skynet.ret(skynet.pack(f(subcmd, ...)))
		end
	end)

    skynet.register("watchdog")
	gate = skynet.newservice("agent/gate")
end)
