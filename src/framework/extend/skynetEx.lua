local skynetEx = {}
local skynet = require("skynet")

function skynetEx.timeoutCall(func, ...)
    local co = coroutine.running()
    local result = {}
    skynet.fork(function (...)
        result = table.pack(pcall(...))
        if co then
            skynet.wakeup(co)
        end
    end, func, ...)

    skynet.sleep(300, co)
    co = nil
    table.remove(result, 1)
    return result
end

return skynetEx