local log = {}
local skynet = require("skynet")
require("framework.utils.functions")

local logLevel = {
    ERROR = 1,
    WARNING = 2,
    INFO = 3,
    DEBUG = 4
}

local logDes = {
    [logLevel.ERROR] = "[ERROR]",
    [logLevel.WARNING] = "[WARNING]",
    [logLevel.INFO] = "[INFO]",
    [logLevel.DEBUG] = "[DEBUG]",
}

local function dump(value, depth)
    depth = depth or 10
    local cache = {}
    local temp = {}
    local function _v(v)
        if type(v) == "string" then
            v = "\"" .. v .. "\""
        end
        return tostring(v)
    end

    local traceback = string.split(debug.traceback("", 4), "\n")
    table.insert(temp, (string.trim(traceback[3])))

    local function _dump(t, space, name, d)
        if type(t) ~= "table" then
            table.insert(temp, string.format("%s%s = %s", space, _v(name), _v(t)))
        elseif cache[t] then
            table.insert(temp, string.format("%s%s = *REF*", space, _v(name)))
        else
            if d <= 0 then
                table.insert(temp, string.format("%s%s = *MAX*", space, _v(name)))
            else
                cache[t] = true
                table.insert(temp, string.format("%s%s = {", space, _v(name)))
                for k, v in pairs(t) do
                    _dump(v, space .. "    ", k, d - 1)
                end
                table.insert(temp, string.format("%s}", space))
            end
        end
    end
    _dump(value, "", "table", depth)
    return table.concat(temp, "\n")
end

local function syslog(level, ...)
    local n = select("#", ...)
    local out = {}
    local str = ""
    for i = 1, n do
        local value = select(i, ...)
        if type(value) == "table" then
            str = dump(value)
        else
            str = type(value) .. " = " .. tostring(value)
        end
        table.insert(out, str)
    end
    local str = table.concat(out, "\t\t")
    str = logDes[level] .. os.date("[%Y-%m-%d %H:%M:%S]\n", math.floor(skynet.time())) .. str
    skynet.error(str)
end

function log.debug(...)
    syslog(logLevel.DEBUG, ...)
end

function log.info(...)
    syslog(logLevel.INFO, ...)
end

function log.warning(...)
    syslog(logLevel.WARNING, ...)
end

function log.error(...)
    syslog(logLevel.ERROR, ...)
end


return log