local skynetEx = {}
local skynet = require("skynet")
local log = require("framework.extend.log")

function skynetEx.timeoutCall(func, ...)
    local co = coroutine.running()
    local result
    skynet.fork(function (...)
        result = table.pack(pcall(...))
        if co then
            skynet.wakeup(co)
        end
    end, func, ...)

    skynet.sleep(300, co)
    co = nil
    if result then
        if result[1] then
            return table.remove(result, 1), result
        else
            return false
        end
    else
        return false
    end
end

return skynetEx