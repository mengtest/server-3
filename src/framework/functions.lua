local type = type
local setmetatable = setmetatable

function printf(fmt, ...)
    print(string.format(tostring(fmt), ...))
end

function checknumber(value, base)
    return tonumber(value, base) or 0
end

function checkint(value)
    return math.round(checknumber(value))
end

function checkbool(value)
    return (value ~= nil and value ~= false)
end

function checktable(value)
    if type(value) ~= "table" then value = {} end
    return value
end

function clone(object)
    local lookup_table = {}
    local function _copy(object)
        if type(object) ~= "table" then
            return object
        elseif lookup_table[object] then
            return lookup_table[object]
        end
        local new_table = {}
        lookup_table[object] = new_table
        for key, value in pairs(object) do
            new_table[_copy(key)] = _copy(value)
        end
        return setmetatable(new_table, getmetatable(object))
    end
    return _copy(object)
end

function class(classname, super)
    local cls
    if super then
        cls = {}
        setmetatable(cls, {__index = super})
        cls.super = super
    else
        cls = {ctor = function () end}
    end

    cls.__cname = classname
    cls.__index = cls
    function cls.new(...)
        local instance = setmetatable({}, cls)
        instance.clsss = cls
        instance:ctor(...)
        return instance
    end
    return cls
end

function handler(obj, method)
    return function(...)
        return method(obj, ...)
    end
end

function dump(value, desciption, nesting)
    if type(nesting) ~= "number" then nesting = 5 end

    local lookupTable = {}
    local result = {}

    local function _v(v)
        if type(v) == "string" then
            v = "\"" .. v .. "\""
        end
        return tostring(v)
    end

    local traceback = string.split(debug.traceback("", 2), "\n")
    print("dump from: " .. string.trim(traceback[3]))

    local function _dump(value, desciption, indent, nest, keylen)
        desciption = desciption or "<var>"
        local spc = ""
        if type(keylen) == "number" then
            spc = string.rep(" ", keylen - string.len(_v(desciption)))
        end
        if type(value) ~= "table" then
            result[#result +1 ] = string.format("%s%s%s = %s", indent, _v(desciption), spc, _v(value))
        elseif lookupTable[value] then
            result[#result +1 ] = string.format("%s%s%s = *REF*", indent, desciption, spc)
        else
            lookupTable[value] = true
            if nest > nesting then
                result[#result +1 ] = string.format("%s%s = *MAX NESTING*", indent, desciption)
            else
                result[#result +1 ] = string.format("%s%s = {", indent, _v(desciption))
                local indent2 = indent.."    "
                local keys = {}
                local keylen = 0
                local values = {}
                for k, v in pairs(value) do
                    keys[#keys + 1] = k
                    local vk = _v(k)
                    local vkl = string.len(vk)
                    if vkl > keylen then keylen = vkl end
                    values[k] = v
                end
                table.sort(keys, function(a, b)
                    if type(a) == "number" and type(b) == "number" then
                        return a < b
                    else
                        return tostring(a) < tostring(b)
                    end
                end)
                for i, k in ipairs(keys) do
                    _dump(values[k], k, indent2, nest + 1, keylen)
                end
                result[#result +1] = string.format("%s}", indent)
            end
        end
    end
    _dump(value, desciption, "- ", 1)

    for i, line in ipairs(result) do
        print(line)
    end
end

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
    local skynet = require("skynet")
    uuid.randomseed(skynet.now())
    if addr then
        local a,b,c,d = string.match(addr, "(%d+)%.(%d+)%.(%d+)%.(%d+)")
        return uuid(math.intToHex(a) .. math.intToHex(b) .. math.intToHex(c) .. math.intToHex(d) .. math.intToHex(a) .. math.intToHex(d))
    end
    return uuid()
end

function table.isEmpty(tb)
    if type(tb) == "table" then
        return next(tb) == nil
    end
    return true
end

function table.size(t)
    local count = 0
    for k, v in pairs(t) do
        count = count + 1
    end
    return count
end

function table.valuesOfKey(hashtable, key)
    local values = {}
    for k,v in pairs(hashtable) do
        if v[key] then
            values[k] = v[key]
        end
    end
    return values
end

function table.pairsByKey(tb)
    local temp = {}
    for key in pairs(tb) do
        temp[#temp + 1] = key
    end
    table.sort(temp)
    local i = 0
    return function ()
        i = i + 1
        return temp[i], tb[temp[i]]
    end
end

function table.max(tb)
    local max
    for k,v in pairs(tb) do
        local value = checknumber(v)
        if not max or max < value then
            max = value
        end
    end
    return max
end

function table.min(tb)
    local min
    for k,v in pairs(tb) do
        local value = checknumber(v)
        if not min or min > value then
            min = value
        end
    end
    return min
end

function table.maxMin(tb)
    local max, min
    for k,v in pairs(tb) do
        local value = checknumber(v)
        if not max or max < value then
            max = value
        end
        if not min or min > value then
            min = value
        end
    end
    return max, min
end

function table.fill(tbA, tbB)
    for k,v in pairs(tbB) do
        if tbA[k] == nil then
            tbA[k] = v
        end
    end
end

function table.merge(tbA, tbB)
    for k,v in pairs(tbB) do
        tbA[k] = v
    end
end

function table.equal(tbA, tbB)
    assert(type(tbA) == "table" and type(tbB) == "table")
    if table.size(tbA) ~= table.size(tbB) then return false end
    for k,v in pairs(tbA) do
        if type(tbB[k]) ~= type(v) then
            return false
        end
        if type(v) == "table" then
            if not table.equal(v, tbB[k]) then
                return false
            end
        else
            if not (v == tbB[k]) then
                return false
            end
        end
    end
    return true
end

function math.intToHex(num)
    num = tonumber(num)
    local HEXES = "0123456789abcdef"
    local s, base = "", 16
    local d
    while num > 0 do
        d = num % base + 1
        num = math.floor(num / base)
        s = string.sub(HEXES, d, d) .. s
    end
    while #s < 2 do
        s = "0" .. s
    end
    return s
end

function io.exists(path)
    local file = io.open(path, "r")
    if file then
        io.close(file)
        return true
    end
    return false
end

function io.readfile(path)
    local file = io.open(path, "r")
    if file then
        local content = file:read("*a")
        io.close(file)
        return content
    end
    return nil
end

function io.writefile(path, content, mode)
    mode = mode or "w+b"
    local file = io.open(path, mode)
    if file then
        if file:write(content) == nil then return false end
        io.close(file)
        return true
    else
        return false
    end
end

function io.mkdir(path)
    if not io.exists(path) then
        return os.execute("mkdir -p " .. path)
    end
    return true
end