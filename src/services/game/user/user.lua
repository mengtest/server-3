local skynet = require("skynet")
require("framework.functions")

local CMD = {}

local code = {
    SUCCESS = 0,
	FAILED = 1,
}

local function errorback(msg)
    return {
        code = code.FAILED,
        msg = msg
    }
end

function CMD.register(agent, data)

end

function CMD.get(agent, data)

end

function CMD.modify(agent, data)
    
end

skynet.start(function ()
    skynet.dispatch("lua", function(_, _, command, ...)
		local f = CMD[command]
		skynet.ret(skynet.pack(f(...)))
    end)
end)