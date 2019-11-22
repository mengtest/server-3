local skynet = require("skynet")
require("skynet.manager")

local offlineCode = require("services.base.gateway.config").offlineCode
local offlineErrorStr = require("services.base.gateway.config").offlineErrorStr
require("framework.utils.functions")
local log = require("framework.extend.log")

local SOCKET = {}
local CMD = {}

local gate
local auth

local info = {}
local secretToFd = {}
local uidToFd = {}
local agents = {}
local freeAgents = {}

local function closeAgent(fd)
    local data = info[fd]
    info[fd] = nil
    if data then
        local agent = agents[fd]
        if agent then
            skynet.call(agent, "lua", "sendData", "socket.offline", {code = offlineCode.TIMEOUT, msg = offlineErrorStr[offlineCode.TIMEOUT]})
            skynet.call(agent, "lua", "closeConnect")
            table.insert(freeAgents, agent)
            agents[fd] = nil
        end
        if data.secret then
            secretToFd[data.secret] = nil
        end
        if data.uid then
            uidToFd[data.uid] = nil
        end
    end
    skynet.call(gate, "lua", "closeClient", fd)
end

local function getFreeAgent()
    local agent = table.remove(freeAgents)
    if not agent then
        agent = skynet.newservice("base/gateway/agent")
    end
    return agent
end

local function closeUnUsedAgent()
    while true do
        for fd, agent in pairs(agents) do
            if not skynet.call(agent, "lua", "isAlive") then
                closeAgent(fd)
            end
        end
        skynet.sleep(120 * 100)
    end
end

function SOCKET.connect(fd, addr)
    local agent = getFreeAgent()
    skynet.call(agent, "lua", "init", {client = fd})
    agents[fd] = agent
    info[fd] = {
        fd = fd,
        addr = addr
    }
end

function SOCKET.data(fd, str)
    if info[fd] then
        skynet.send(auth, "lua", "receiveData", fd, str, info[fd].addr)
    end
end

function SOCKET.disConnect(fd)
    closeAgent(fd)
end

function SOCKET.error(fd, error)
    closeAgent(fd)
end

function SOCKET.warning(fd, size)
    log.warningf("%d : %dKb", fd, size)
end

function CMD.start()
    auth = skynet.newservice("base/gateway/auth")
    skynet.call(auth, "lua", "start", {gate = gate, watchdog = skynet.self()})
    skynet.call(gate, "lua", "start", skynet.self())
    skynet.call(gate, "lua", "open", {nodelay = true})

    skynet.fork(closeUnUsedAgent)
end

function CMD.bindClient(fd, secret)
    if secretToFd[secret] then
        closeAgent(secretToFd[secret])
    end
    secretToFd[secret] = fd
    info[fd].secret = secret
end

function CMD.bindAgent(fd, uid)
    if uidToFd[uid] then
        closeAgent(uidToFd[uid])
    end
    uidToFd[uid] = fd
    info[fd].uid = uid

    if agents[fd] then
        skynet.call(agents[fd], "lua", "init", {gate = gate, client = fd, watchdog = skynet.self(), uid = uid, secret = info[fd].secret})
        skynet.call(agents[fd], "lua", "start")
    end
end

function CMD.closeClient(fd)
    closeAgent(fd)
end

function CMD.push(uid, service, data, fd)
    local fd = uidToFd[uid] or fd
    if fd then
        local agent = agents[fd]
        if agent then
            skynet.send(agent, "lua", "sendData", service, data)
        end
    end
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

    skynet.register("watchdog")
    gate = skynet.newservice("base/gateway/gate")
end)