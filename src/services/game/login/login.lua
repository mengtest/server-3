local skynet = require("skynet")
local config = require("services.game.login.config")
local code = config.code
require("framework.functions")

local CMD = {}

local function errorback(code)
    return {
        code = code,
        msg = config.errorStr[code]
    }
end

function CMD.login(_, data, address)
    local account = data.account
    if string.isEmpty(account) then
        return errorback(code.ERROR_ACCOUNT)
    end

    local password = data.password
    local loginType = data.loginType

    local loginTime = skynet.time()
    local token = string.uuid(address)

    local accountInfo = skynet.call("mongo", "lua", "findOne", "Account", {account = account})
    if accountInfo then
        if loginType == config.loginType.GUEST then
            local _, user = skynet.call("status", "lua", "callServiceMethod", "user", "get", accountInfo.uid)
            if user then
                accountInfo.loginTime = loginTime
                accountInfo.token = token
                accountInfo.loginType = loginType
                local bool, msg = skynet.call("mongo", "lua", "update", "Account", {account = account}, accountInfo)
                if bool then
                    return {
                        code = code.SUCCESS,
                        msg = config.errorStr[code.SUCCESS],
                        user = user, 
                        account = {token = token}
                    }
                end
                return errorback(code.ERROR_SAVE)
            end
            return errorback(code.ERROR_USER)
        end
        return errorback(code.ERROR_LOGIN_TYPE)
    else
        if loginType == config.loginType.GUEST then
            local _, user = skynet.call("status", "lua", "callServiceMethod", "user", "register")
            if user then
                local accountInfo = {
                    account = account,
                    password = "",
                    token = token,
                    uid = user.uid,
                    registerTime = loginTime,
                }
                local bool, msg = skynet.call("mongo", "lua", "insert", "Account", accountInfo)
                if bool then
                    return {
                        code = code.SUCCESS,
                        msg = config.errorStr[code.SUCCESS],
                        user = user,
                        account = {token = token}
                    }
                end
                return errorback(code.ERROR_SAVE)
            end
            return errorback(code.ERROR_USER)
        end
        return errorback(code.ERROR_LOGIN_TYPE)
    end
    return errorback(code.FAILED)
end

skynet.start(function ()
    skynet.dispatch("lua", function(_, _, command, ...)
		local f = CMD[command]
		skynet.ret(skynet.pack(f(...)))
    end)
end)