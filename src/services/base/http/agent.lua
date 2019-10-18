local skynet = require("skynet")
local socket = require("skynet.socket")
local httpd = require("http.httpd")
local sockethelper = require("http.sockethelper")
local urllib = require("http.url")
require("framework.functions")

local CMD = {}

local function response(id, ...)
	local ok, err = httpd.write_response(sockethelper.writefunc(id), ...)
	if not ok then
		skynet.error(string.format("fd = %d, %s", id, err))
	end
end

function CMD.update(url, query, header, body)
    print(url)
    if string.isEmpty(url) then
        return 200, "http://192.168.220.130:8001/update"
    else
        local path = "files/update" .. url
        local content = io.readfile(path)
        if content then
            return 200, content
        else
            return 404
        end
    end
end

function CMD.upload(url, query, header, body)
    if header and header["content-type"] then
        local contentType = header["content-type"]
        local arr = string.split(contentType, ";")
        if arr[1] ~= "multipart/form-data" then
            return 416
        end
        local split = "--" .. string.match(arr[2], "=(.+)")
        local contentArr = string.split(body, split)

        local parseData = {}
        for i, v in ipairs(contentArr) do
            local head, body = string.match(v, "^\r\n(.-\r\n)\r\n(.+)")
            if head then
                local disposition = string.match(head, "Content%-Disposition.-;(.-)\r\n")
                local isContentType = string.find(head, "Content%-Type")
                if isContentType then
                    parseData.fileName = string.match(disposition, 'filename="(.-)"')
                    parseData.fileData = string.match(body, "^(.-)\r\n$")
                elseif disposition then
                    local fieldName = string.match(disposition, 'name="(.-)"')
                    parseData[fieldName] = string.match(body, "^(.-)\r\n$")
                end
            end
        end
        if not parseData.type then
            return 416
        end
        local fileName, ext = string.match(parseData.fileName or "", "^([^%.]+)%.?(.*)$")
        if not string.isEmpty(ext) then
            ext = "." .. ext
        end
        fileName = table.concat({fileName, "_", string.uuid(os.time()), ext})
        local dir = table.concat({"files/upload/", parseData.type, "/"})
        if not io.exists(dir) then
            io.mkdir(dir)
        end
        io.writefile(dir .. fileName, parseData.fileData)
        return 200, fileName
    end
end

skynet.start(function()
	skynet.dispatch("lua", function (_,_,id)
		socket.start(id)  -- 开始接收一个 socket
		-- 一般的业务不需要处理大量上行数据，为了防止攻击，做了一个 4K 限制。这个限制可以去掉。
		local code, url, method, header, body = httpd.read_request(sockethelper.readfunc(id))
		if code then
			if code ~= 200 then  -- 如果协议解析有问题，就回应一个错误码 code 。
				response(id, code)
            else
				local path, query = urllib.parse(url)
				if query then
					query = urllib.parse_query(query)
                end
                local funcName, newPath = string.match(path, "^/([^/]+)(.*)")
                if CMD[funcName] then
                    local newCode, data = CMD[funcName](newPath, query, header, body)
                    response(id, newCode or code, data)
                else
                    response(id, 405)
                end
			end
		else
			-- 如果抛出的异常是 sockethelper.socket_error 表示是客户端网络断开了。
			if url == sockethelper.socket_error then
				skynet.error("socket closed")
			else
				skynet.error(url)
			end
		end
		socket.close(id)
	end)
end)