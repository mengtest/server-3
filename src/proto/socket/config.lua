local socketPb = "./proto/socket/socket.pb"
local socketPkg = "socket"

local config = {}

config.method = {
    SOCKET = "socket.socket",
    HEARTBEAT = "socket.heartbeat",
    RECONNECT = "socket.reconnect"
}

config.protoConfig = {
    [config.method.SOCKET] = {pb = socketPb, pkg = socketPkg, requestMsg = "socketReq", responseMsg = "socketResp"},
    [config.method.HEARTBEAT] = {pb = socketPb, pkg = socketPkg, requestMsg = "heartbeatReq", responseMsg = "heartbeatResp"},
    [config.method.RECONNECT] = {pb = socketPb, pkg = socketPkg, requestMsg = "reconnectReq", responseMsg = "reconnectResp"}
}

return config