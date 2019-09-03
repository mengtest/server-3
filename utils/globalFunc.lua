require("utils.stringUtils")

--[[
    @desc: 校验为数字
    author:Bogey
    time:2019-08-12 15:59:29
    --@value:
	--@base: 
    @return:
]]
function checknumber(value, base)
    return tonumber(value, base) or 0
end

--[[
    @desc: 校验为整数
    author:Bogey
    time:2019-08-12 15:59:44
    --@value: 
    @return:
]]
function checkint(value)
    return math.round(checknumber(value))
end

--[[
    @desc: 校验为布尔值
    author:Bogey
    time:2019-08-12 15:59:56
    --@value: 
    @return:
]]
function checkbool(value)
    return (value ~= nil and value ~= false)
end

--[[
    @desc: 校验为表
    author:Bogey
    time:2019-08-12 16:00:17
    --@value: 
    @return:
]]
function checktable(value)
    if type(value) ~= "table" then value = {} end
    return value
end

function dump(value, desciption, nesting)
    if type(nesting) ~= "number" then nesting = 6 end

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