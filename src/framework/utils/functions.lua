require("framework.utils.stringUtils")
require("framework.utils.tableUtils")
require("framework.utils.mathUtils")
require("framework.utils.fileUtils")

local type = type
local setmetatable = setmetatable
local skynet = require("skynet")
math.randomseed(skynet.now())

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
