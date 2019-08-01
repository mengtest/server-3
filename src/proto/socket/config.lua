local socketPb = "./src/proto/socket/socket.pb"
local socketPkg = "socket"

local config = {}

config.method = {
    SOCKET = "socket",
    HEARTBEAT = "heartbeat",
    LOGIN = "api-login.login"
}

config.protoConfig = {
    [config.method.SOCKET] = {pb = socketPb, pkg = socketPkg, requestMsg = "socketReq", responseMsg = "socketResp"},
    [config.method.HEARTBEAT] = {pb = socketPb, pkg = socketPkg, requestMsg = "heartbeatReq", responseMsg = "heartbeatResp"},
    [config.method.LOGIN] = {pb = socketPb, pkg = socketPkg, requestMsg = "loginReq", responseMsg = "loginResp"},
}

return config