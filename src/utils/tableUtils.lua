--[[
    @desc: 判断表是否为空
    author:{author}
    time:2019-02-12 14:59:21
    --@tb: 
    @return:
]]
function table.isEmpty(tb)
    if type(tb) == "table" then
        return next(tb) == nil
    end
    return true
end

--[[
    @desc: 获取表里指定字段的所有值
    author:BogeyRuan
    time:2019-06-17 15:33:28
    --@hashtable:
	--@key: 
    @return:
]]
function table.valuesOfKey(hashtable, key)
    local values = {}
    for k,v in pairs(hashtable) do
        if v[key] then
            values[k] = v[key]
        end
    end
    return values
end

--[[
    @desc: 顺序遍历不连续hash表
    author:BogeyRuan
    time:2019-06-17 15:37:25
    --@tb: 
    @return: 迭代器
]]
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

--[[
    @desc: 返回表内最大的值
    author:BogeyRuan
    time:2019-06-21 12:18:22
    --@tb: 
    @return:
]]
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

--[[
    @desc: 返回表内最小的值
    author:BogeyRuan
    time:2019-06-21 12:18:40
    --@tb: 
    @return:
]]
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

--[[
    @desc: 返回表里的最大最小值
    author:BogeyRuan
    time:2019-06-25 16:16:22
    --@tb: 
    @return:
]]
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

--[[
    @desc: 用B表去填充A表
    author:BogeyRuan
    time:2019-07-09 10:26:28
    --@tbA:
	--@tbB: 
    @return:
]]
function table.fill(tbA, tbB)
    for k,v in pairs(tbB) do
        if tbA[k] == nil then
            tbA[k] = v
        end
    end
end