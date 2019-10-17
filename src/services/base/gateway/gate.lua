local skynet = require("skynet")
local socket = require("skynet.socketdriver")

local socketId
local clientNum = 0
local maxClientNum
local nodelay = false
local connection = {}

local CMD = {}

function CMD.closeClient(fd)
    if connection[fd] then
        connection[fd] = nil
        clientNum = clientNum - 1
        socket.close(fd)
    end
end

function CMD.forward(fd, agent)
    if connection[fd] then
        connection[fd].agent = agent
    end
end

function CMD.close()
    assert(socketId)
    socket.close(socketId)
end

function CMD.open(conf)
    assert(not socketId)
    local address = conf.address or "0.0.0.0"
    local port = conf.port or 8888
    maxClientNum = conf.maxClientNum or 1024
    nodelay = conf.nodelay
    socketId = socket.listen(address, port)
    socket.start(socketId)
end

function CMD.start(watchDog)
    local function close(fd)
        CMD.closeClient(fd)
    end

    local MSG = {}

    -- SKYNET_SOCKET_TYPE_DATA = 1
    MSG[1] = function (fd, size, data)
        local str = skynet.tostring(data, size)
        if connection[fd] then
            if connection[fd].agent then
                skynet.send(connection[fd].agent, "lua", "receiveData", str)
            else
                skynet.send(watchDog, "lua", "socket", "data", fd, str)
            end
        else
            skynet.error("Drop message", str)
        end
        socket.drop(data, size)
    end

    -- SKYNET_SOCKET_TYPE_CONNECT = 2
    MSG[2] = function (fd, _, addr)
    end

    -- SKYNET_SOCKET_TYPE_CLOSE = 3
    MSG[3] = function (fd)
        if fd == socketId then
            socketId = nil
        else
            skynet.send(watchDog, "lua", "socket", "disConnect", fd)
            close(fd)
        end
    end

    -- SKYNET_SOCKET_TYPE_ACCEPT = 4
    MSG[4] = function (fd, newFd, addr)
        skynet.error("New connect", fd, newFd, addr)
        if clientNum >= maxClientNum then
            socket.close(newFd)
            return
        end
        if nodelay then
            socket.nodelay(newFd)
        end
        connection[newFd] = {
            fd = newFd,
            addr = addr
        }
        clientNum = clientNum + 1
        socket.start(newFd)
        skynet.send(watchDog, "lua", "socket", "connect", newId, addr)
    end

    -- SKYNET_SOCKET_TYPE_ERROR = 5
    MSG[5] = function (fd, _, error)
        if fd == socketId then
            socket.close(socketId)
            skynet.error("socket close", error)
        else
            skynet.send(watchDog, "lua", "socket", "error", fd, error)
            close(fd)
        end
    end

    -- SKYNET_SOCKET_TYPE_UDP = 6
    MSG[6] = function (fd, size, data, addrs)
    end

    -- SKYNET_SOCKET_TYPE_WARNING = 7
    MSG[7] = function (fd, size)
        skynet.send(watchDog, "lua", "socket", "warning", fd, size)
    end

    skynet.register_protocol {
        name = "socket",
        id = skynet.PTYPE_SOCKET,	-- PTYPE_SOCKET = 6
        unpack = socket.unpack,
        dispatch = function (_, _, t, ...)
            MSG[t](...)
        end
    }
end

skynet.start(function()
    skynet.dispatch("lua", function(_, _, cmd, ...)
        local f = CMD[cmd]
        skynet.ret(skynet.pack(f(...)))
    end)
end)