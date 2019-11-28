local skynet = require("skynet")
require("framework.utils.functions")

local DataParser = class("DataParser")

--包结构
--|包体长度的长度|包体长度    |包体|
--| 1111 1111 | 1111 1111 |...|

DataParser.cacheData = ""

local function checkDataPack(data)
    local headLen = string.sub(data, 1, 1)
    local index = #headLen
    if index > 0 then
        local bodyLen = string.sub(data, index + 1, string.asciiToNum(headLen) + index)
        if #bodyLen == string.asciiToNum(headLen) then
            index = index + #bodyLen
            local body = string.sub(data, index + 1, string.asciiToNum(bodyLen) + index)
            if #body == string.asciiToNum(bodyLen) then
                return true, index, body
            end
        end
    end
    return false
end

function DataParser.parseData(data)
    local datas = {}
    data = DataParser.cacheData .. data
    local bool, headLen, body = checkDataPack(data)
    while bool do
        local socketData = skynet.call("pbc", "lua", "decode", "socket.socket", body)
        if not table.isEmpty(socketData) then
            local serviceData = skynet.call("pbc", "lua", "decode", socketData.service, socketData.body)
            socketData.body = serviceData
            table.insert(datas, socketData)
        end
        data = string.sub(data, headLen + #body + 1)
        bool, headLen, body = checkDataPack(data)
    end
    DataParser.cacheData = data
    return datas
end

function DataParser.packData(code, service, data)
    assert(service, "Service name must exist")
    local serviceData = skynet.call("pbc", "lua", "encode", service, data or {})
    local socketData = skynet.call("pbc", "lua", "encode", "socket.socket", {code = code, service = service, body = serviceData})

    local bodyLen = string.numToAscii(string.len(socketData))
    local headLen = string.numToAscii(string.len(bodyLen))
    socketData = headLen .. bodyLen .. socketData
    return socketData
end

return DataParser