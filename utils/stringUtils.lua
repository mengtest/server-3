--[[
    @desc: 判断字段是否为空
    author:Bogey
    time:2019-02-12 14:55:00
    --@str: 要判断的字段
    @return: 布尔值
]]
function string.isEmpty(str)
    if type(str) ~= "string" or str == "" then
        return true
    end
    return false
end

--[[
    @desc: 将字符串的第一个字符转为大写，返回结果
    author:Bogey
    time:2019-03-27 17:43:03
    --@input: 
    @return:
]]
function string.upperFirst(input)
    return string.upper(string.sub(input, 1, 1)) .. string.sub(input, 2)
end

--[[
    @desc: 将字符串的第一个字符转为小写，返回结果
    author:Bogey
    time:2019-04-11 10:35:48
    --@input: 
    @return:
]]
function string.lowerFirst(input)
    return string.lower(string.sub(input, 1, 1)) .. string.sub(input, 2)
end

--[[
    @desc: 拆分文字
    author:Bogey
    time:2019-08-12 15:51:19
    --@input:
	--@delimiter: 
    @return:
]]
function string.split(input, delimiter)
    input = tostring(input)
    delimiter = tostring(delimiter)
    if (delimiter=='') then return false end
    local pos,arr = 0, {}
    -- for each divider found
    for st,sp in function() return string.find(input, delimiter, pos, true) end do
        table.insert(arr, string.sub(input, pos, st - 1))
        pos = sp + 1
    end
    table.insert(arr, string.sub(input, pos))
    return arr
end

--[[
    @desc: 根据传入的成对的字符串拆分文字
    author:Bogey
    time:2019-06-17 11:04:07
    --@str: 要拆分的文字
	--@config: 成对的字符串集合，如{"#*", "()"}
    @return: 返回拆出来的文字，并附加文字被包含的索引,普通文字索引为配置数加1
    @example: string.splitByConfig("ab#cde*fg", {"#*"})
    @result: {{text = "ab", index = 2}, {text = "cde", index = 1}, {text = "fg", index = 2}}
]]
function string.splitByConfig(str, config)
    local configNum = #config
    local splitIndex = {}
    for i, v in ipairs(config) do
        local split_1 = {value = string.sub(v, 1, 1), tag = i, type = 1}
        local split_2 = {value = string.sub(v, -1, -1), tag = i, type = 2}

        local index_1, index_2 = string.find(str, string.format("%%b%s", v), 1)
        while index_1 do
            table.insert(splitIndex, {index = index_1, value = split_1})
            table.insert(splitIndex, {index = index_2, value = split_2})
            index_1, index_2 = string.find(str, string.format("%%b%s", v), index_1 + 1)
        end
    end
    table.sort(splitIndex, function(a, b)
        return a.index < b.index
    end)

    local strTemp = {}
    local splitStack = {{tag = configNum + 1}}
    local tempStr = ""
    local index = 1
    for i = 1, #str do
        local split = splitIndex[index]
        if split and i == split.index then
            if tempStr ~= "" then
                table.insert(strTemp, {str = tempStr, index = splitStack[#splitStack].tag})
            end
            if split.value.type == 1 then
                table.insert(splitStack, split.value)
            end
            if split.value.type == 2 then
                if splitStack[#splitStack].tag ~= split.value.tag then
                    error("The string format is incorrect: " .. str .. ", string: " .. split.value.value)
                end
                table.remove(splitStack, #splitStack)
            end
            index = index + 1
            tempStr = ""
        else
            tempStr = tempStr .. string.sub(str, i, i)
        end
    end
    if tempStr ~= "" then
        table.insert(strTemp, {str = tempStr, index = configNum + 1})
    end
    return strTemp
end

--[[
    @desc: 数字转为ASCII码对应的字符串
    author:Bogey
    time:2019-07-11 14:56:19
    --@num: 
    --@long: 转为多少个字节的字符，默认为动态长度
    @return:
]]
function string.numToAscii(num, long)
    local str = ""
    local asciiNum = num % 256
    while asciiNum >= 0 and num > 0 do
        str = string.char(asciiNum) .. str
        num = math.floor(num / 256)
        asciiNum = num % 256
    end
    if long then
        if #str > long then
            str = string.sub(str, -long, -1)
        else
            local dis = long - #str
            for i = 1, dis do
                str = string.char(0) .. str
            end
        end
    end

    return str
end

--[[
    @desc: ASCII码对应的字符串转为数字
    author:Bogey
    time:2019-07-11 15:49:03
    --@str: 
    @return:
]]
function string.asciiToNum(str)
    local num = 0
    for i = 1, #str do
        local s = string.sub(str, -i, -i)
        num = num + string.byte(s) * 256 ^ (i - 1)
    end
    return num
end

--[[ 去除头尾空格
    @desc: 
    author:Bogey
    time:2019-08-12 15:51:56
    --@input: 
    @return:
]]
function string.trim(input)
    input = string.gsub(input, "^[ \t\n\r]+", "")
    return string.gsub(input, "[ \t\n\r]+$", "")
end

--[[
    @desc: 计算字符串utf8文本长度
    author:Bogey
    time:2019-08-12 15:52:31
    --@input: 
    @return:
]]
function string.utf8len(input)
    local left = string.len(input)
    local cnt  = 0
    local arr  = {0, 0xc0, 0xe0, 0xf0, 0xf8, 0xfc}
    while left > 0 do
        local tmp = string.byte(input, -left)
        local i   = #arr
        while arr[i] do
            if tmp >= arr[i] then
                left = left - i
                break
            end
            i = i - 1
        end
        cnt = cnt + 1
    end
    return cnt
end

--[[
    @desc: 添加千分符
    author:Bogey
    time:2019-08-12 15:53:04
    --@num: 
    @return:
]]
function string.formatnumberthousands(num)
    local formatted = tostring(checknumber(num))
    local k
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if k == 0 then break end
    end
    return formatted
end

--[[
    @desc: 数字转中文数字
    author:Bogey
    time:2019-06-17 14:41:49
    --@num: 
    @return:
]]
function string.toChineseNumber(num)
    assert(type(num) == "number", "Must be a number")
    local hzNum = {"零", "一", "二", "三", "四", "五", "六", "七", "八", "九"}
    local hzUnit = {"", "十", "百", "千"}
    local hzBigUnit = {"", "万", "亿"}

    num = string.reverse(tostring(num))

    local function getString(index, data)
        local len = #data
        local str = ""
        for i = len, 1, -1 do
            -- 两个连续的零或者末尾零，跳过
            if data[i] == "0" and (data[i - 1] == "0" or i == 1) then
            else
                --类似一十七，省略一，读十七
                if len == 2 and i == 2 and data[i] == "1" and index == 1 then
                else
                    str = str .. hzNum[tonumber(data[i]) + 1]
                end

                --单位，零没有单位
                if data[i] ~= "0" then
                    str = str .. hzUnit[i]
                end
            end
        end
        -- 大单位
        str = str .. hzBigUnit[index]
        return str
    end

    -- 拆分成4位一段
    local numTable = {}
    local len = string.len(num)
    for i = 1, len do
        local index = math.ceil(i / 4)
        if not numTable[index] then
            numTable[index] = {}
        end
        table.insert(numTable[index], string.sub(num, i, i))
    end

    -- 组合文字
    local str = ""
    for i,v in ipairs(numTable) do
        local rt = getString(i, v)
        str = rt .. str
    end
    return str
end

--[[
    @desc: 拆分文本
    author:Bogey
    time:2019-06-17 14:41:49
    --@input: 
    --@delimiter: 
    @return:
]]
function string.split(input, delimiter)
    input = tostring(input)
    delimiter = tostring(delimiter)
    if (delimiter=='') then return false end
    local pos,arr = 0, {}
    -- for each divider found
    for st,sp in function() return string.find(input, delimiter, pos, true) end do
        table.insert(arr, string.sub(input, pos, st - 1))
        pos = sp + 1
    end
    table.insert(arr, string.sub(input, pos))
    return arr
end

