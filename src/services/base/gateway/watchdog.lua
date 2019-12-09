local skynet = require("skynet")
require("skynet.manager")
require("framework.utils.functions")
local log = require("framework.extend.log")

local offlineCode = require("services.base.gateway.config").offlineCode
local offlineErrorStr = require("services.base.gateway.config").offlineErrorStr

local SOCKET = {}
local CMD = {}

local gate

local info = {}

local agents = {}
local freeAgents = {}

local uidToFd = {}

local function closeAgent(fd, closeCode)
    closeCode = closeCode or offlineCode.CLOSE
    local data = info[fd]
    info[fd] = nil
    if data then
        local agent = agents[fd]
        if agent then
            skynet.call(agent, "lua", "sendData", "socket.offline", {code = closeCode, msg = offlineErrorStr[closeCode]})
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
                closeAgent(fd, offlineCode.TIMEOUT)
            end
        end
        skynet.sleep(120 * 100)
    end
end

function SOCKET.connect(fd, addr)
    local agent = getFreeAgent()
    agents[fd] = agent
    info[fd] = {
        fd = fd,
        addr = addr
    }
    skynet.call(agent, "lua", "start", {client = fd, gate = gate, watchdog = skynet.self()})
end

function SOCKET.data(fd, str)
    log.errorf("Error fd:%d, data:%s, ip:%s", fd, str, info[fd].addr)
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
    skynet.call(gate, "lua", "start", skynet.self())
    skynet.call(gate, "lua", "open", {nodelay = true})
    skynet.fork(closeUnUsedAgent)
end

function CMD.bindAgentByUid(fd, uid)
    if uidToFd[uid] then
        closeAgent(uidToFd[uid], offlineCode.MULTIPLE)
    end
    uidToFd[uid] = fd
    info[fd].uid = uid
end

function CMD.closeClient(fd, closeCode)
    closeAgent(fd, closeCode)
end

function CMD.push(uid, service, data, fd)
    local fd = uidToFd[uid] or fd
    if fd then
        local agent = agents[fd]
        if agent then
            skynet.send(agent, "lua", "sendData", service, data)
            return true
        end
    end
    return false
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