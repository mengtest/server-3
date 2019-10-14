local skynet = require("skynet")
require("skynet.manager")
require("utils.stringUtils")
require("utils.globalFunc")

local SOCKET = {}
local CMD = {}

local gate
local commonAgent

local agents = {}
local agentsInfo = {}
local socketIds = {}
local socketAddrs = {}

local function getAgent(id)
    if socketIds[id] then
        return agents[socketIds[id]]
    end
end

local function closeConnect(id)
    if socketIds[id] then
        skynet.call(gate, "lua", "closeClient", id)
        socketIds[id] = nil
        socketAddrs[id] = nil
    end
end

local function closeAgent(id)
    local agent = getAgent(id)
    if agent then
        skynet.call(agent, "lua", "exit")
        agents[socketIds[id]] = nil
        agentsInfo[socketIds[id]] = nil
    end
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

local function updateAgentTime(id)
    if socketIds[id] and agentsInfo[socketIds[id]] then
        agentsInfo[socketIds[id]].time = skynet.now()
    end
end

local function newAgent(id)
    local agent = skynet.newservice("base/gateway/agent")
    skynet.call(agent, "lua", "start", {client = id, gate = gate, watchdog = skynet.self()})
    agents[socketIds[id]] = agent
    agentsInfo[socketIds[id]] = {time = skynet.now()}
    return agent
end

function SOCKET.connect(id, addr)
    socketIds[id] = addr
    socketAddrs[id] = addr
    skynet.call(gate, "lua", "openClient", id)
end

function SOCKET.data(id, str)
    local agent = getAgent(id)
    if agent then
        skynet.call(agent, "lua", "receiveData", str)
        updateAgentTime(id)
    else
        skynet.call(commonAgent, "lua", "receiveData", str, id, socketAddrs[id])
    end
end

function SOCKET.disConnect(id)
    closeConnect(id)
end

function SOCKET.error(id, error)
    closeConnect(id)
    skynet.error(error)
end

function SOCKET.warning(id, size)
    skynet.error("SOCKET.warning", id, size)
end

function CMD.start()
    commonAgent = skynet.newservice("base/gateway/commonAgent")
    skynet.call(commonAgent, "lua", "start", {gate = gate, watchdog = skynet.self()})
    skynet.call(gate, "lua", "start", skynet.self())
    skynet.call(gate, "lua", "open", {nodelay = true})

    skynet.fork(cleanUnUsedAgent)
end

function CMD.closeConnect(id, bool)
    if bool then
        closeAgent(id)
    end
    closeConnect(id)
end

function CMD.getAddressById(id)
    return socketAddrs[id]
end

function CMD.updateSocketBindAgent(id, secret)
    local oldSecret = socketIds[id]
    if oldSecret == secret then
        return
    end
    socketIds[id] = secret or oldSecret
    local isNew = false
    local agent = getAgent(id)
    if not agent then
        agent = newAgent(id)
        isNew = true
    end
    return agent, isNew
end

function CMD.updateAgentBindSocket(id, newSecret)
    local secret = socketIds[id]
    if (not secret) or (secret == newSecret) then
        return
    end
    local agent = agents[secret]
    if agent then
        socketIds[id] = newSecret
        agents[newSecret] = agent
        agentsInfo[newSecret] = agentsInfo[secret]
        agents[secret] = nil
        agentsInfo[secret] = nil
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

    gate = skynet.newservice("base/gateway/gate")
end)