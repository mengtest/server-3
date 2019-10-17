local skynet = require("skynet")
require("skynet.manager")
require("framework.functions")

local SOCKET = {}
local CMD = {}

local gate
local auth

local agents = {}
local secretToAgent = {}

local function closeAgent(fd)
    local agentInfo = agents[fd]
    if not table.isEmpty(agentInfo) then
        local agent = agentInfo.agent
        if agent then
            skynet.call(agent, "lua", "close")
        end
        local secret = agentInfo.secret
        if secret then
            secretToAgent[secret] = nil
        end
    end
    agents[fd] = nil
end

local function cleanUnUsedAgent()
    local function isInSocketIds(value)
        for k, v in pairs(socketIds) do
            if v == value then
                return true
            end
        end
        return false
    end

    local cleanTime = 60000 --10min

    while true do
        skynet.sleep(cleanTime)
        local time = skynet.now()
        for k, v in pairs(agentsInfo) do
            if not isInSocketIds(k) then
                if time - v.time > cleanTime then
                    skynet.send(agents[k], "lua", "exit")
                    agents[k] = nil
                    agentsInfo[k] = nil
                end
            end
        end
    end
end


function SOCKET.connect(fd, addr)
    agents[fd] = {
        fd = fd,
        addr = addr,
        time = skynet.now()
    }
end

function SOCKET.data(fd, str)
    skynet.send(auth, "lua", "receiveData", str, fd, agents[fd].addr)
end

function SOCKET.disConnect(id)
end

function SOCKET.error(id, error)
end

function SOCKET.warning(id, size)
    skynet.error("SOCKET.warning", id, size)
end

function CMD.start()
    auth = skynet.newservice("base/gateway/auth")
    skynet.call(auth, "lua", "start", {gate = gate, watchdog = skynet.self()})
    skynet.call(gate, "lua", "start", skynet.self())
    skynet.call(gate, "lua", "open", {nodelay = true})

    skynet.fork(cleanUnUsedAgent)
end

function CMD.bindClient(fd, secret, oldSecret)
    local oldFd = secretToAgent[oldSecret]
    if not string.isEmpty(oldSecret) and oldFd then
        agents[fd].agent = agents[oldFd].agent
        agents[oldFd].agent = nil
        closeAgent(oldFd)
    end
    if secretToAgent[secret] then
        closeAgent(secretToAgent[secret])
    end
    secretToAgent[secret] = fd
    agents[fd].secret = secret
end

function CMD.bindAgent(fd)
    local agent = agents[fd].agent
    if not agent then
        agent = skynet.newservice("base/gateway/agent")
        skynet.call(agent, "lua", "start", {gate = gate, client = fd, watchdog = skynet.self()})
        agents[fd].agent = agent
    else
        skynet.call(agent, "lua", "start", {gate = gate, client = fd, watchdog = skynet.self()})
    end
end

function CMD.closeClient(fd)
    closeAgent(fd)
    skynet.call(gate, "lua", "closeClient", fd)
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

    gate = skynet.newservice("base/gateway/gate")
end)