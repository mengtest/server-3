local skynet = require("skynet")
require("framework.functions")

local CMD = {}

local code = {
    SUCCESS = 0,
	FAILED = 1,
}

local function errorback(msg)
    return {
        code = code.FAILED,
        msg = msg
    }
end

function CMD.login(agent, data, address)
    local account = data.account
    local msg = ""
    if string.isEmpty(account) then
        return errorback("account is nil")
    end

    local password = checkstring(data.password)
    local user = skynet.call("mongo", "lua", "findOne", "users", {account = account})
    if user then
        if password == "" or user.password == password then
            local loginTime = os.time()
            local token = string.uuid(address)
            user.token = token
            user.loginTime = loginTime
            user.address = address
            if skynet.call("mongo", "lua", "update", "users", {account = account}, user) then
                return {
                    code = code.SUCCESS,
                    msg = "",
                    account = {token = token},
                    user = {uid = user.uid, nick = user.nick}
                }
            end
        end
        msg = "password is error"
    else
        local userInc = skynet.call("mongo", "lua", "findOne", "increase", {key = "users"})
        local sid = 1
        local bool = true
        if userInc then
            sid = userInc.value + 1
        end
        bool = skynet.call("mongo", "lua", "update", "increase", {key = "users"}, {key = "users", value = sid}, true)

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