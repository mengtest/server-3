local skynet = require("skynet")
require("skynet.manager")
require("framework.utils.functions")
local log = require("framework.extend.log")

local SOCKET = {}
local CMD = {}

local gate
local auth

local info = {}
local agents = {}
local secretToFd = {}

local function closeAgent(fd)
    skynet.call(gate, "lua", "unForward", fd)
    local agentInfo = info[fd]
    if not table.isEmpty(agentInfo) then
        local agent = agents[fd]
        if agent then
            agents[fd] = nil
            skynet.send(agent, "lua", "close")
        end
        local secret = agentInfo.secret
        if secret then
            secretToFd[secret] = nil
        end
    end
    info[fd] = nil
    skynet.call(gate, "lua", "closeClient", fd)
end

local function cleanUnUsedAgent()
    while true do
        for key, value in pairs(info) do
            local agent = agents[key]
            if agent then
                if skynet.call(agent, "lua", "isAlive") == false then
                    closeAgent(key)
                end
            else
                if skynet.now() - value.time > 120 * 100 then
                    closeAgent(key)
                end
            end
        end
        skynet.sleep(120 * 100)
    end
end

function SOCKET.connect(fd, addr)
    info[fd] = {
        fd = fd,
        addr = addr,
        time = skynet.now()
    }
end

function SOCKET.data(fd, str)
    if info[fd] then
        skynet.send(auth, "lua", "receiveData", str, fd, info[fd].addr)
    end
end

function SOCKET.disConnect(fd)
    if agents[fd] then
        skynet.call(agents[fd], "lua", "closeConnect")
    end
end

function SOCKET.error(fd, error)
end

function SOCKET.warning(fd, size)
    log.fwarning("%d : %dKb", fd, size)
end

function CMD.start()
    auth = skynet.newservice("base/gateway/auth")
    skynet.call(auth, "lua", "start", {gate = gate, watchdog = skynet.self()})
    skynet.call(gate, "lua", "start", skynet.self())
    skynet.call(gate, "lua", "open", {nodelay = true})

    skynet.fork(cleanUnUsedAgent)
end

function CMD.bindClient(fd, secret, oldSecret)
    local oldFd = secretToFd[oldSecret]
    if oldFd then
        agents[fd] = agents[oldFd]
        agents[oldFd] = nil
        closeAgent(oldFd)
    end
    if secretToFd[secret] then
        closeAgent(secretToFd[secret])
    end
    secretToFd[secret] = fd
    info[fd].secret = secret
end

function CMD.bindAgent(fd, uid)
    local agent = agents[fd]
    if not agent then
        agent = skynet.newservice("base/gateway/agent")
        skynet.call(agent, "lua", "start", {gate = gate, client = fd, watchdog = skynet.self(), uid = uid})
        agents[fd] = agent
    else
        skynet.call(agent, "lua", "start", {gate = gate, client = fd, watchdog = skynet.self(), uid = uid})
    end
end

function CMD.closeClient(fd)
    closeAgent(fd)
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