local skynet = require("skynet")
local socket = require("skynet.socketdriver")
local parse = require("base.gateway.dataparser")
local serviceConfig = require("configs.serviceConfig")
local serviceErrorCode = require("configs.errorConfig").serviceErrorCode
require("utils.globalFunc")
require("utils.stringUtils")
require("utils.tableUtils")

local WATCHDOG
local GATE

local CMD = {}

local function sendData(client, code, service, data, secret)
	dump(data)
	data = parse.packData(code, service, data, secret)
	socket.send(client, data)
end

local function isPublicService(serviceName)
    for i, v in ipairs(serviceConfig.publicService) do
        if serviceName == v then
            return true
        end
    end
    return false
end

function CMD.start(conf)
	GATE = conf.gate
	WATCHDOG = conf.watchdog
end

function CMD.receiveData(data, client, address)
	local datas = parse.parseData(data)
	dump(datas)
	for i,v in ipairs(datas) do
        local serviceName, methodName = string.match(v.service, "^(.+)%.(.+)$")
		if serviceName == "socket" then
            if methodName == "reconnect" then
                local newsecret = string.uuid(skynet.now(), tonumber(string.gsub(string.match(address, "^(.+):%d+$"), "%.", ""), 10))
                local agent, isNew = skynet.call(WATCHDOG, "lua", "updateSocketBindAgent", client, v.body.secret)
                local ret = skynet.call(agent, "lua", "bindUser", v.body.uid, client)
                if ret then
                    skynet.call(WATCHDOG, "lua", "updateAgentBindSocket", client, newsecret)
                    sendData(client, serviceErrorCode.SUCCESS, v.service, {code = 0, secret = newsecret})
                else
                    sendData(client, serviceErrorCode.SUCCESS, v.service, {code = 1})
                    skynet.call(WATCHDOG, "lua", "closeConnect", client, isNew)
                end
            end
        elseif serviceName == "login" and methodName == "login" then
            local newsecret = string.uuid(skynet.now(), tonumber(string.gsub(string.match(address, "^(.+):%d+$"), "%.", ""), 10))
            local code, ret, secret = skynet.call("status", "lua", "callServiceSafeMethod", serviceName, methodName, skynet.self(), v.body, address, newsecret)
            local agent = skynet.call(WATCHDOG, "lua", "updateSocketBindAgent", client, secret)
            skynet.call(agent, "lua", "bindUser", ret.user.uid, client)
            skynet.call(WATCHDOG, "lua", "updateAgentBindSocket", client, newsecret)
            sendData(client, code, v.service, ret, secret)
        elseif isPublicService(serviceName) then
            local code, ret = skynet.call("status", "lua", "callServiceSafeMethod", serviceName, methodName, skynet.self(), v.body, address)
            sendData(client, code, v.service, ret)
		else
			sendData(client, serviceErrorCode.PRIVATE_SERVICE, v.service)
		end
	end
end

function CMD.getAddress()
	return ""
end

skynet.start(function()
	skynet.dispatch("lua", function(_,_, command, ...)
		local f = CMD[command]
		skynet.ret(skynet.pack(f(...)))
	end)
end)
