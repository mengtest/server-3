local skynet = require("skynet")
local socket = require("skynet.socket")

skynet.start(function()
    local agents = {}
	for i= 1, 5 do
		agents[i] = skynet.newservice("base/http/agent")
	end
	local balance = 1
	local id = socket.listen("0.0.0.0", 8001)
	socket.start(id , function(id, addr)
		skynet.error(string.format("%s connected, pass it to agent :%08x", addr, agents[balance]))
		skynet.send(agents[balance], "lua", id)
		balance = balance + 1
		if balance > #agents then
			balance = 1
		end
	end)
end)