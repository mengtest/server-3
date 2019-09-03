local skynet = require("skynet")
require("utils.stringUtils")
require("utils.tableUtils")

--包结构
--| len:65535           | body:string |
--| 1111 1111 1111 1111 |...          |

local packHeadLen = 2           --包头长度

local cacheData = ""

local function checkDataPack(data)
    if #data < packHeadLen then
        return false
    end
    local bodyLen = string.asciiToNum(string.sub(data, 1, packHeadLen))
    local body = string.sub(data, packHeadLen + 1, bodyLen)
    if bodyLen == #body + packHeadLen then
        return true, body
    end
    return false
end

local M = {}

function M.parseData(data)
    local datas = {}
    data = cacheData .. data
    local bool, body = checkDataPack(data)
    while bool do
        local socketData = skynet.call("pbc", "lua", "decode", "socket.socket", body)
        if not table.isEmpty(socketData) then
            local serviceData = skynet.call("pbc", "lua", "decode", socketData.service, socketData.body)
            socketData.body = serviceData
            table.insert(datas, socketData)
        end
        data = string.sub(data, packHeadLen + #body + 1)
        bool, body = checkDataPack(data)
    end
    cacheData = data
    return datas
end

function M.packData(code, service, data, secret)
    assert(service, "Service name must exist")
    local serviceData = skynet.call("pbc", "lua", "encode", service, data)
    local socketData = skynet.call("pbc", "lua", "encode", "socket.socket", {code = code, service = service, body = serviceData, secret = secret})
    local dataLen = packHeadLen + string.len(socketData)
    if dataLen > 65535 then
        print("data is too long, max len is 2^16 - 1")
        return
    end
    socketData = string.numToAscii(dataLen, 2) .. socketData
    return socketData
end

return M