local skynet = require("skynet")
require("skynet.manager")
local mongo = require("skynet.db.mongo")
local bson = require("bson")

local function openDB()
    local client = mongo.client({
        host = skynet.getenv("DBHOST"),
        port = skynet.getenv("DBPORT"),
        username = skynet.getenv("DBUSERNAME"),
        password = skynet.getenv("DBPASSWORD"),
        authdb = skynet.getenv("DBNAME"),
    })
    return client
end

local db

local CMD = {}
function CMD.start()
    local client = openDB()
    local dbName = skynet.getenv("DBNAME")
    db = client[dbName]
end

local options = {"insert", "delete", "update", "batch_insert"}
for _, v in ipairs(options) do
    CMD[v] = function (cname, ...)
        local col = db[cname]
        col[v](col, ...)
        local result = db:runCommand("getLastError")
        local ok = result and result.ok == 1 and result.err == bson.null
        if not ok then
            skynet.error(v .. "failed", result.err, cname, ...)
        end
        return ok, result.err
    end
end

function CMD.findOne(cname, selector, field_selector)
    return db[cname]:findOne(selector, field_selector)
end

function CMD.find(cname, selector, field_selector)
    return db[cname]:find(selector, field_selector)
end

function CMD.getInc(key)
    local increase
    local result = CMD.findOne("Increase", {key = key})
    if not result then
        increase = 1
        result = {key = key, value = increase}
    else
        result.value = result.value + 1
        increase = result.value
    end
    CMD.update("Increase", {key = key}, result, true)
    return increase
end

skynet.start(function()
    skynet.dispatch("lua", function(session, address, cmd, ...)
        local func = CMD[cmd]
        assert(func, "mongo func is nil")
        if session == 0 then
            func(...)
        else
            skynet.ret(skynet.pack(func(...)))
        end
    end)

    skynet.register("mongo")
end)