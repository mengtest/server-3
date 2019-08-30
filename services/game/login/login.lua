local skynet = require("skynet")
require("globalFunc")

local CMD = {}

local code = {
    SUCCESS = 0,
	FAILED = 1,
}

local function genUUID(time, address)
    local chars = {"a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z","1","2","3","4","5","6","7","8","9","0"}
    local function getRandomChar()
        return chars[math.random(1, #chars)]
    end
    local uuid = ""
    for i, v in ipairs({time, address}) do
        math.randomseed(v)
        for i = 1, 16 do
            uuid = uuid .. getRandomChar()
        end
    end
    return uuid
end

function CMD.login(agent, data)
    local account = data.account
    if not account or account == "" then
        return false
    end
    local password = data.password or ""

    local user = skynet.call("mongo", "lua", "findOne", "users", {account = account})
    if user then
        if user.password == password or user.token == password then
            local loginTime = os.time()
            local secret = string.reverse(genUUID(skynet.now()))
            local address = skynet.call(agent, "lua", "getAddress")
            address = string.gsub(address, "%.", "")
            local token = secret .. genUUID(tonumber(address))
            user.token = token
            user.loginTime = loginTime
            user.address = address
            skynet.send("mongo", "lua", "update", "users", {account = account}, user)
            return secret, {
                code = code.SUCCESS,
                msg = "",
                account = {token = token},
                user = {uid = user.uid, nick = user.nick}
            }
        end
        return false
    else
        local userInc = skynet.call("mongo", "lua", "findOne", "increase", {key = "users"})
        local sid = 1
        if userInc then
            sid = userInc.value + 1
            skynet.send("mongo", "lua", "update", "increase", {key = "users"}, {key = "users", value = sid})
        else
            skynet.send("mongo", "lua", "insert", "increase", {key = "users", value = 1})
        end
        local loginTime = os.time()
        local secret = string.reverse(genUUID(skynet.now()))
        local address = skynet.call(agent, "lua", "getAddress")
        address = string.gsub(address, "%.", "")
        local token = secret .. genUUID(tonumber(address))
        user = {
            account = account,
            password = password,
            appversion = data.appversion,
            token = token,
            loginTime = loginTime,
            address = address,
            uid = sid,
            nick = "Guest" .. sid,
        }
        local secret = string.reverse(genUUID(loginTime))

        skynet.send("mongo", "lua", "insert", "users", user)
        return secret, {
            code = code.SUCCESS,
            msg = "",
            account = {token = token},
            user = {uid = user.uid, nick = user.nick}
        }
    end
end

skynet.start(function ()
    skynet.dispatch("lua", function(_,_, command, ...)
		local f = CMD[command]
		skynet.ret(skynet.pack(f(...)))
    end)
end)