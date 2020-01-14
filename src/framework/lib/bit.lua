local Bit = {}

local cpu = 64

local function bitToNum(bit)
    local offset = 0
    local num = 0
    if bit[1] == 1 then
        offset = 1
    end
    for i = 1, cpu do
        num = num + (2 ^ (cpu - i)) * ((bit[i] + offset) % 2)
    end
    if offset == 1 then
        num = -1 - num
    end
    return num
end

local function numToBit(num)
    local offset = 0
    if num < 0 then
        offset = 1
        num = -1 - num
    end
    local bit = {}
    for i = 1, cpu do
        bit[cpu - i + 1] = (num + offset) % 2
        num = math.modf(num / 2)
    end
    return bit
end

--[[
    @desc: 转换为bit表
    author:Bogey
    time:2019-12-04 11:45:26
    --@num: 
    @return:
]]
function Bit.toBit(num)
    return numToBit(num)
end

function Bit.toNum(bit)
    return bitToNum(bit)
end

--[[
    @desc: 转换为16进制，不带0x
    author:Bogey
    time:2019-12-04 11:45:43
    --@num: 
    @return:
]]
function Bit.toHex(num)
    local hexStr = "0123456789ABCDEF"
    local bit = numToBit(num)
    local strs = {}
    for i = 1, cpu, 4 do
        local index = bit[i] * 8 + bit[i + 1] * 4 + bit[i + 2] * 2 + bit[i + 3] * 1 + 1
        strs[#strs + 1] = string.sub(hexStr, index, index)
    end
    return string.match(table.concat(strs), "^0*(.+)")
end

--[[
    @desc: 非
    author:Bogey
    time:2019-12-04 11:46:12
    --@num: 
    @return:
]]
function Bit.bnot(num)
    local bit = numToBit(num)
    for i = 1, cpu do
        bit[i] = (bit[i] + 1) % 2
    end
    return bitToNum(bit)
end

--[[
    @desc: 与
    author:Bogey
    time:2019-12-04 11:46:21
    --@args: 
    @return:
]]
function Bit.band(...)
    local function band(aBit, bBit)
        local result = {}
        for i = 1, cpu do
            result[i] = (aBit[i] == 1 and bBit[i] == 1) and 1 or 0
        end
        return result
    end

    local count = select("#", ...)
    if count > 0 then
        local r = numToBit(select(1, ...))
        for i = 2, count do
            r = band(r, numToBit(select(i, ...)))
        end
        return bitToNum(r)
    end
end

--[[
    @desc: 或
    author:Bogey
    time:2019-12-04 11:46:29
    --@args: 
    @return:
]]
function Bit.bor(...)
    local function bor(aBit, bBit)
        local result = {}
        for i = 1, cpu do
            result[i] = (aBit[i] == 1 or bBit[i] == 1) and 1 or 0
        end
        return result
    end

    local count = select("#", ...)
    if count > 0 then
        local r = numToBit(select(1, ...))
        for i = 2, count do
            r = bor(r, numToBit(select(i, ...)))
        end
        return bitToNum(r)
    end
end

--[[
    @desc: 异或
    author:Bogey
    time:2019-12-04 11:46:36
    --@args: 
    @return:
]]
function Bit.bxor(...)
    local function bxor(aBit, bBit)
        local result = {}
        for i = 1, cpu do
            result[i] = (aBit[i] == bBit[i]) and 0 or 1
        end
        return result
    end

    local count = select("#", ...)
    if count > 0 then
        local r = numToBit(select(1, ...))
        for i = 2, count do
            r = bxor(r, numToBit(select(i, ...)))
        end
        return bitToNum(r)
    end
end

--[[
    @desc: 左移
    author:Bogey
    time:2019-12-04 11:46:47
    --@num:
	--@offset: 
    @return:
]]
function Bit.lshift(num, offset)
    offset = offset % cpu
    local bit = numToBit(num)
    for i = 1, cpu do
        bit[i] = bit[i + offset] or 0
    end
    return bitToNum(bit)
end

--[[
    @desc: 右移
    author:Bogey
    time:2019-12-04 11:46:55
    --@num:
	--@offset: 
    @return:
]]
function Bit.rshift(num, offset)
    offset = offset % cpu
    local bit = numToBit(num)
    for i = cpu, 1, -1 do
        bit[i] = bit[i - offset] or 0
    end
    return bitToNum(bit)
end

return Bit
