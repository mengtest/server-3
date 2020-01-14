
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

function table.copy(tbA, tbB)
    for i,v in ipairs(tbB) do
        table.insert(tbA, v)
    end
end

function table.sync(tbA, tbB)
    for k,v in pairs(tbA) do
        if tbB[k] then
            tbA[k] = tbB[k]
        end
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
