local skynet = require("skynet")
local socket = require("skynet.socket")
local httpd = require("http.httpd")
local sockethelper = require("http.sockethelper")
local urllib = require("http.url")
require("framework.utils.functions")

local CMD = {}

local function response(fd, ...)
	local ok, err = httpd.write_response(sockethelper.writefunc(fd), ...)
	if not ok then
		skynet.error(string.format("fd = %d, %s", fd, err))
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
        if not parseData["type"] then
            return 416
        end
        local fileName, ext = string.match(parseData.fileName or "", "^([^%.]+)%.?(.*)$")
        if not string.isEmpty(ext) then
            ext = "." .. ext
        end
        fileName = table.concat({fileName, "_", string.uuid(), ext})
        local dir = table.concat({"files/upload/", parseData["type"], "/"})
        io.mkdir(dir)
        io.writefile(dir .. fileName, parseData.fileData)
        return 200, fileName
    end
end

skynet.start(function()
	skynet.dispatch("lua", function (_,_,fd)
		socket.start(fd)  -- ?????????????????? socket
		-- ???????????????????????????????????????????????????????????????????????????????????? 4K ????????????????????????????????????
		local code, url, method, header, body = httpd.read_request(sockethelper.readfunc(fd))
		if code then
			if code ~= 200 then  -- ?????????????????????????????????????????????????????? code ???
				response(fd, code)
            else
				local path, query = urllib.parse(url)
				if query then
					query = urllib.parse_query(query)
                end
                local funcName, newPath = string.match(path, "^/([^/]+)(.*)")
                if CMD[funcName] then
                    local newCode, data = CMD[funcName](newPath, query, header, body)
                    response(fd, newCode or code, data)
                else
                    response(fd, 405)
                end
			end
		else
			-- ???????????????????????? sockethelper.socket_error ????????????????????????????????????
			if url == sockethelper.socket_error then
				skynet.error("socket closed")
			else
				skynet.error(url)
			end
		end
		socket.close(fd)
	end)
end)