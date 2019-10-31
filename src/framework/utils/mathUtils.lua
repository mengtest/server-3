
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

function math.round(value)
    value = checknumber(value)
    return math.floor(value + 0.5)
end