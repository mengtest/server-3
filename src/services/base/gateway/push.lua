local skynet = require("skynet")
require("skynet.manager")

local socket = require("skynet.socketdriver")
local parse = require("base.gateway.dataparser").new()
local log = require("framework.extend.log")
require("framework.utils.functions")

local CMD = {}
local info = {}

local function sendData(fd, service, code, data)
    log.info(data)
    data = parse.packData(code, service, data)
    socket.send(fd, data)
end

function CMD.register(uid, fd)
    info[uid] = fd
end

function CMD.unRegister(uid, fd)
    info[uid] = nil
end

function CMD.push(uid, service, data)
    if info[uid] then
        sendData(info[uid], service, 1, data)
    end
end

function CMD.start()
end

skynet.start(function()
	skynet.dispatch("lua", function(_,_, command, ...)
		local f = CMD[command]
		skynet.ret(skynet.pack(f(...)))
    end)
    
    skynet.register("push")
end)
