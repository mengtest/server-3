local skynet = require("skynet")
require("skynet.manager")
local pb = require("pb")
local pbList = require("proto.pbConfig")

local CMD = {}

local pbConfig = {}
local pbFile = {}
local msgType = {
    request = "requestMsg",
    response = "responseMsg"
}

local function _readFile(path)
    local file = assert(io.open(path, "r"))
    local string = file:read("*a")
    file:close()
    return string
end

local function _getProto(msgType, pbKey)
    local config = pbConfig[pbKey]
    if config then
        if not pbFile[config.pb] then
            local data = _readFile(config.pb)
            assert(data and data ~= "")
            pb.load(data)
            pbFile[config.pb] = true
        end
        return config.pkg .. "." .. config[msgType]
    end
end

function CMD.register(config)
    config = type(config) == "table" and config or {}
    for k,v in pairs(config) do
        if not pbConfig[k] then
            pbConfig[k] = v
        else
            skynet.error("The configured key value already exists : " .. k)
        end
    end
end

function CMD.encode(pbKey, data)
    local proto = _getProto(msgType.response, pbKey)
    if proto and data then
        return pb.encode(proto, data)
    end
    return ""
end

function CMD.decode(pbKey, data)
    local proto = _getProto(msgType.request, pbKey)
    if proto and data then
        return pb.decode(proto, data)
    end
    return ""
end

function CMD.start()
    for k, v in pairs(pbList) do
        CMD.register(v.protoConfig)
    end
end

skynet.start(function()
    skynet.dispatch("lua", function(session, address, cmd, ...)
        local func = CMD[cmd]
        assert(func, "pbc func is nil")
        if session == 0 then
            func(...)
        else
            skynet.ret(skynet.pack(func(...)))
        end
    end)

    skynet.register("pbc")
end)