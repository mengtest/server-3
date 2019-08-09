local skynet = require("skynet")

local SOCKET = {}
local CMD = {}

local gate
local agents = {}

local function close(id)
    local agent = agents[id]
    agents[id] = nil
    if agent then
        skynet.call(gate, "lua", "closeClient", id)
        skynet.call(agent, "lua", "disConnect")
    end
end

function SOCKET.connect(id, addr)
    agents[id] = skynet.newservice("agent")
    skynet.call(agents[id], "lua", "start", {client = id, gate = gate})
end

function SOCKET.disConnect(id)
    close(id)
end

function SOCKET.error(id, error)
    close(id)
    skynet.error(error)
end

function SOCKET.warning(id, size)
    skynet.error("SOCKET.warning", id, size)
end

function SOCKET.data(id, str)
    local agent = agents[id]
    if agent then
        skynet.call(agent, "lua", "receiveData", str)
    end
end

function CMD.start()
    skynet.call(gate, "lua", "start", skynet.self())
    skynet.call(gate, "lua", "open", {nodelay = true}))
end

function CMD.close(id)
    close(id)
end

skynet.start(function()
    skynet.dispatch("lua", function(session, source, cmd, subcmd, ...)
        if cmd == "socket" then
            local f = SOCKET[subcmd]
            skynet.ret(skynet.pack(f(...)))
        else
            local f = CMD[cmd]
            skynet.ret(skynet.pack(f(subcmd, ...)))
        end
    end)
    
    gate = skynet.newservice("gate")
end)