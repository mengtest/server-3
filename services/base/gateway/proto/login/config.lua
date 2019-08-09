local loginPb = "./src/proto/login/login.pb"
local loginPkg = "login"

local config = {}

config.method = {
    LOGIN = "api-login.login"
}

config.protoConfig = {
    [config.method.LOGIN] = {pb = loginPb, pkg = loginPkg, requestMsg = "loginReq", responseMsg = "loginResp"},
}

return config