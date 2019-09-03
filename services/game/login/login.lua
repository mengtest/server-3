local skynet = require("skynet")
require("utils.stringUtils")

local CMD = {}

local code = {
    SUCCESS = 0,
	FAILED = 1,
}

local function errorback()
    return {
        code = code.FAILED,
        msg = ""
    }
end

function CMD.login(agent, data, address, newsecret)
    address = address or skynet.call(agent, "lua", "getAddress")
    address = string.match(address, "^(.+):%d+$")
    local account = data.account
    if string.isEmpty(account) then
        return errorback()
    end
    local password = data.password or ""

    local user = skynet.call("mongo", "lua", "findOne", "users", {account = account})
    if user then
        if user.password == password or user.token == password then
            local loginTime = os.time()
            local addNum = string.gsub(address, "%.", "")
            local token = string.uuid(loginTime, tonumber(addNum))
            local oldsecret = user.secret
            user.token = token
            user.loginTime = loginTime
            user.address = address
            user.secret = newsecret or oldsecret
            if skynet.call("mongo", "lua", "update", "users", {account = account}, user) then
                return {
                    code = code.SUCCESS,
                    msg = "",
                    account = {token = token},
                    user = {uid = user.uid, nick = user.nick}
                }, oldsecret
            end
        end
    else
        local userInc = skynet.call("mongo", "lua", "findOne", "increase", {key = "users"})
        local sid = 1
        local bool = true
        if userInc then
            sid = userInc.value + 1
            bool = skynet.call("mongo", "lua", "update", "increase", {key = "users"}, {key = "users", value = sid})
        else
            bool = skynet.call("mongo", "lua", "insert", "increase", {key = "users", value = 1})
        end

        local loginTime = os.time()
        local addNum = string.gsub(address, "%.", "")
        local token = string.uuid(loginTime, tonumber(addNum))
        user = {
            account = account,
            password = password,
            appversion = data.appversion,
            token = token,
            loginTime = loginTime,
            address = address,
            secret = newsecret,
            uid = sid,
            nick = "Guest" .. sid,
        }

        if skynet.call("mongo", "lua", "insert", "users", user) then
            return {
                code = code.SUCCESS,
                msg = "",
                account = {token = token},
                user = {uid = user.uid, nick = user.nick}
            }
        end
    end
    return errorback()
end

skynet.start(function ()
    skynet.dispatch("lua", function(_, _, command, ...)
		local f = CMD[command]
		skynet.ret(skynet.pack(f(...)))
    end)
end)