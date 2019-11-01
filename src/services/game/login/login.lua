local skynet = require("skynet")
local config = require("services.game.login.config")
local code = config.code
require("framework.utils.functions")

local CMD = {}

local function errorback(code)
    return {
        code = code,
        msg = config.errorStr[code]
    }
end

local function newAccount(accountInfo)
    return skynet.call("mongo", "lua", "insert", "Account", accountInfo)
end

local function getAccount(param)
    return skynet.call("mongo", "lua", "findOne", "Account", param)
end

function CMD.register(acc, pwd, time)
    local _, user = skynet.call("status", "lua", "callServiceMethod", "user", "register")
    if user then
        local accountInfo = {
            account = acc,
            password = pwd,
            uid = user.uid,
            registerTime = time
        }
        return newAccount(accountInfo)
    end
end

function CMD.getAccount(uid)
    return getAccount({uid = uid})
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

    local accountInfo = getAccount({account = account})
    if not accountInfo then
        local bool = CMD.register(account, password, loginTime)
        if not bool then
            return errorback(code.FAILED)
        end
        accountInfo = getAccount({account = account})
    end
    if accountInfo then
        if loginType == config.loginType.GUEST then
            local _, user = skynet.call("status", "lua", "callServiceMethod", "user", "get", accountInfo.uid)
            if user then
                local _, status = skynet.call("status", "lua", "callServiceMethod", "status", "getAppInfo", accountInfo.uid)
                status = status or {uid = accountInfo.uid}
                status.loginTime = loginTime
                status.loginType = loginType
                status.appId = data.appId
                status.appVersion = data.appVersion
                status.appVersionNumber = data.appVersionNumber
                status.deviceType = data.deviceType
                local _, bool = skynet.call("status", "lua", "callServiceMethod", "status", "setAppInfo", accountInfo.uid, status)
                if bool then
                    return {
                        code = code.SUCCESS,
                        msg = config.errorStr[code.SUCCESS],
                        user = user
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