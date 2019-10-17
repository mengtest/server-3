local path = "proto."

local config = {
    socket = require(path .. "socket.config"),
    login = require(path .. "login.config"),
}
return config