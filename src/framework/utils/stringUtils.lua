
function string.isEmpty(str)
    if type(str) ~= "string" or string.trim(str) == "" then
        return true
    end
    return false
end

function string.upperFirst(input)
    return string.upper(string.sub(input, 1, 1)) .. string.sub(input, 2)
end

function string.lowerFirst(input)
    return string.lower(string.sub(input, 1, 1)) .. string.sub(input, 2)
end

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

function string.asciiToNum(str)
    local num = 0
    for i = 1, #str do
        local s = string.sub(str, -i, -i)
        num = num + string.byte(s) * 256 ^ (i - 1)
    end
    return num
end

function string.trim(input)
    input = string.gsub(input, "^[ \t\n\r]+", "")
    return string.gsub(input, "[ \t\n\r]+$", "")
end

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

function string.formatnumberthousands(num)
    local formatted = tostring(checknumber(num))
    local k
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if k == 0 then break end
    end
    return formatted
end

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

function string.uuid(addr)
    local uuid = require("framework.uuid")
    if addr then
        local a,b,c,d = string.match(addr, "(%d+)%.(%d+)%.(%d+)%.(%d+)")
        return uuid(math.intToHex(a) .. math.intToHex(b) .. math.intToHex(c) .. math.intToHex(d) .. math.intToHex(a) .. math.intToHex(d))
    end
    return uuid()
end
