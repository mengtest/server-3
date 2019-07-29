local skynet = require("skynet")
require("utils.stringUtils")
require("utils.tableUtils")

--包结构
--| P         K         G         | ver:1     | len:65535           | body:string |
--| 0101 0000 0100 1011 0100 0111 | 0000 0001 | 1111 1111 1111 1111 |...          |

local packHeadLen = 6           --包头长度
local packHeadPrefix = "PKG"    --包头前缀
local packVersion = 1           --包头版本

local cacheData = ""

local function checkDataPack(data)
    if #data < packHeadLen then                                                             --数据长度不够
        return false
    end
    local start = string.find(data, packHeadPrefix, 1)
    if start then                                                                           --找到包头
        data = string.sub(data, start)                                                      --去除包头之前可能存在的错误数据
        local ver = string.asciiToNum(string.sub(data, 4, 4))                               --包协议版本（可能之后存在不同包协议）
        local bodyLen = string.asciiToNum(string.sub(data, 5, packHeadLen))
        local body = string.sub(data, packHeadLen + 1, bodyLen)
        if bodyLen == #body + packHeadLen then
            return true, body, start
        end
    end
    return false
end

local M = {}

function M.parseData(data)
    local datas = {}
    data = cacheData .. data
    local bool, body, offset = checkDataPack(data)
    while bool do
        local socketData = skynet.call("pbc", "lua", "decode", "socket", body)    --解包socket
        if not table.isEmpty(socketData) then                                               --如果有数据
            local serviceData = skynet.call("pbc", "lua", "decode", socketData.service, socketData.body)
            socketData.body = serviceData
            table.insert(datas, socketData)
        end
        data = string.sub(data, packHeadLen + #body + offset)                               --获取下一段数据
        bool, body, offset = checkDataPack(data)                                            --检测数据包
    end
    cacheData = data
    return datas
end

function M.packData(code, service, data)
    assert(service, "Service name must exist")
    local serviceData = skynet.call("pbc", "lua", "encode", service, data)
    local socketData = skynet.call("pbc", "lua", "encode", "socket", {code = code, service = service, body = serviceData})
    local dataLen = packHeadLen + string.len(socketData)
    if dataLen > 65535 then
        print("data is too long, max len is 2^16 - 1")
        return
    end
    socketData = table.concat({packHeadPrefix, string.numToAscii(packVersion, 1), string.numToAscii(dataLen, 2), socketData})
    return socketData
end