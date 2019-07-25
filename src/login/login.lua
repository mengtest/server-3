local login = require("snax.loginserver")
local crtpt = require("skynet.crypt")
local skynet = require("skynet")

local server = {
    host = skynet.getenv("LOGINHOST"),
    port = skynet.getenv("LOGINPORT"),
    multilogin = false
}

local serverList = {}
local onlineUser = {}

function server.auth_handler(token)
    
end

function server.login_handler(server, uid, secret)
    
end

local CMD = {}

function CMD.logout(uid, subid)
    
end

function server.command_handler(cmd, ...)
    local func = CMD[cmd]
    return func(...)
end

login(server)
