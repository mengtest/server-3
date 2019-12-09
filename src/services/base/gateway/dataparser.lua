local skynet = require("skynet")
require("framework.utils.functions")
local string = string

local DataParser = class("DataParser")

--包结构
--|包体长度的长度|包体长度    |包体|
--| 1111 1111 | 1111 1111 |...|

DataParser.cacheData = ""

local function checkDataPack(data)
    local headLenStr = string.sub(data, 1, 1)
    local totalLen = #headLenStr
    if totalLen > 0 then
        local headLen = string.asciiToNum(headLenStr)
        local bodyLenStr = string.sub(data, totalLen + 1, headLen + totalLen)
        if #bodyLenStr == headLen then
            totalLen = totalLen + headLen
            local bodyLen = string.asciiToNum(bodyLenStr)
            local body = string.sub(data, totalLen + 1, bodyLen + totalLen)
            if #body == bodyLen then
                totalLen = totalLen + bodyLen
                return true, totalLen, body
            end
        end
    end
    return false
end

function DataParser:parseData(data)
    local datas = {}
    data = self.cacheData .. data
    local bool, totalLen, body = checkDataPack(data)
    while bool do
        local socketData = skynet.call("pbc", "lua", "decode", "socket.socket", body)
        if not table.isEmpty(socketData) then
            local serviceData = skynet.call("pbc", "lua", "decode", socketData.service, socketData.body)
            socketData.body = serviceData
            table.insert(datas, socketData)
        end
        data = string.sub(data, totalLen + 1)
        bool, totalLen, body = checkDataPack(data)
    end
    self.cacheData = data
    return datas
end

function DataParser:packData(code, service, data)
    assert(service, "Service name must exist")
    local serviceData = skynet.call("pbc", "lua", "encode", service, data or {})
    local socketData = skynet.call("pbc", "lua", "encode", "socket.socket", {code = code, service = service, body = serviceData})

    local bodyLen = string.numToAscii(string.len(socketData))
    local headLen = string.numToAscii(string.len(bodyLen))
    socketData = headLen .. bodyLen .. socketData
    return socketData
end

return DataParser