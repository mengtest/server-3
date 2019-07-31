local skynet = require("skynet")
local socket = require("skynet.socketdriver")

local socketId
local clientNum = 0
local maxClientNum
local nodelay = false
local connection = {}

local CMD = {}

function CMD.openClient(fd)
    if connection[fd] then
        socket.start(fd)
    end
end

function CMD.closeClient(fd)
    if connection[fd] then
        connection[fd] = false
        socket.close(fd)
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
    local function close(id)
        local c = connection[id]
        if c ~= nil then
            connection[id] = nil
            clientNum = clientNum - 1
        end
    end

    local MSG = {}

    -- SKYNET_SOCKET_TYPE_DATA = 1
    MSG[1] = function (id, size, data)
        local str = skynet.tostring(data, size)
        if connection[id] then
            skynet.call(watchDog, "lua", "socket", "data", id, str)
        else
            skynet.error("Drop message", str)
        end
        socket.drop(data, size)
    end

    -- SKYNET_SOCKET_TYPE_CONNECT = 2
    MSG[2] = function (id, _, addr)
    end

    -- SKYNET_SOCKET_TYPE_CLOSE = 3
    MSG[3] = function (id)
        if id == socketId then
            socketId = nil
        else
            skynet.call(watchDog, "lua", "socket", "disconnect", id)
            close(id)
        end
    end

    -- SKYNET_SOCKET_TYPE_ACCEPT = 4
    MSG[4] = function (id, newId, addr)
        skynet.error("New connect", id, newId, addr)
        if clientNum >= maxClientNum then
            socket.close(newId)
            return
        end
        if nodelay then
            socket.nodelay(newId)
        end
        connection[newId] = true
        clientNum = clientNum + 1
        skynet.call(watchDog, "lua", "socket", "connect", newId, addr)
    end

    -- SKYNET_SOCKET_TYPE_ERROR = 5
    MSG[5] = function (id, _, error)
        if id == socketId then
            socket.close(socketId)
            skynet.error("socket close", error)
        else
            skynet.call(watchDog, "lua", "socket", "error", id, error)
            close(id)
        end
    end

    -- SKYNET_SOCKET_TYPE_UDP = 6
    MSG[6] = function (id, size, data, addrs)
    end

    -- SKYNET_SOCKET_TYPE_WARNING = 7
    MSG[7] = function (id, size)
        skynet.call(watchDog, "lua", "socket", "warning", id, size)
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
        if f then
            skynet.ret(skynet.pack(f(...)))
        end
    end)
end)