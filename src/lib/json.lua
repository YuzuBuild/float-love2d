-- Minimal JSON encoder/decoder for save data
-- Based on https://github.com/rxi/json.lua (MIT licensed)

local json = {}

-------------------------------------------------------------------------------
-- Encode
-------------------------------------------------------------------------------

local function encodeValue(val)
    local t = type(val)
    if t == "string" then
        return string.format("%q", val:gsub("\\", "\\\\"):gsub("\n", "\\n"))
    elseif t == "number" then
        if val ~= val or val == math.huge or val == -math.huge then
            return "null"
        end
        return string.format("%.14g", val)
    elseif t == "boolean" then
        return val and "true" or "false"
    elseif t == "table" then
        -- Detect array vs object
        local isArr = true
        local count = 0
        for k, _ in pairs(val) do
            if type(k) == "number" then
                count = count + 1
            else
                isArr = false
                break
            end
        end
        if isArr and count == #val then
            local items = {}
            for i, v in ipairs(val) do
                items[i] = encodeValue(v)
            end
            return "[" .. table.concat(items, ",") .. "]"
        else
            local items = {}
            for k, v in pairs(val) do
                table.insert(items, string.format("%q", tostring(k)) .. ":" .. encodeValue(v))
            end
            return "{" .. table.concat(items, ",") .. "}"
        end
    end
    return "null"
end

function json.encode(val)
    return encodeValue(val)
end

-------------------------------------------------------------------------------
-- Decode
-------------------------------------------------------------------------------

local pos

local function err(msg)
    return error(string.format("json decode error at pos %d: %s", pos, msg))
end

local function skipWhitespace(str)
    while pos <= #str do
        local c = str:byte(pos)
        if c == 32 or c == 9 or c == 10 or c == 13 then
            pos = pos + 1
        else
            break
        end
    end
end

local function decodeString(str)
    if str:byte(pos) ~= 34 then err("expected '\"'") end
    pos = pos + 1
    local result = {}
    while pos <= #str do
        local c = str:sub(pos, pos)
        if c == '"' then
            pos = pos + 1
            return table.concat(result)
        elseif c == "\\" then
            pos = pos + 1
            local esc = str:sub(pos, pos)
            if esc == "n" then table.insert(result, "\n")
            elseif esc == "t" then table.insert(result, "\t")
            elseif esc == "r" then table.insert(result, "\r")
            elseif esc == "\\" then table.insert(result, "\\")
            elseif esc == '"' then table.insert(result, '"')
            else table.insert(result, esc) end
            pos = pos + 1
        else
            table.insert(result, c)
            pos = pos + 1
        end
    end
    err("unterminated string")
end

local function decodeNumber(str)
    local start = pos
    while pos <= #str do
        local c = str:sub(pos, pos)
        if c:match("[%d.eE+-]") then
            pos = pos + 1
        else
            break
        end
    end
    return tonumber(str:sub(start, pos - 1)) or err("invalid number")
end

local decodeValue

local function decodeArray(str)
    local arr = {}
    pos = pos + 1  -- skip [
    skipWhitespace(str)
    if str:sub(pos, pos) == "]" then pos = pos + 1; return arr end
    while true do
        skipWhitespace(str)
        table.insert(arr, decodeValue(str))
        skipWhitespace(str)
        local c = str:sub(pos, pos)
        if c == "," then pos = pos + 1
        elseif c == "]" then pos = pos + 1; return arr
        else err("expected ',' or ']' in array") end
    end
end

local function decodeObject(str)
    local obj = {}
    pos = pos + 1  -- skip {
    skipWhitespace(str)
    if str:sub(pos, pos) == "}" then pos = pos + 1; return obj end
    while true do
        skipWhitespace(str)
        local key = decodeString(str)
        skipWhitespace(str)
        if str:sub(pos, pos) ~= ":" then err("expected ':' after key") end
        pos = pos + 1
        skipWhitespace(str)
        obj[key] = decodeValue(str)
        skipWhitespace(str)
        local c = str:sub(pos, pos)
        if c == "," then pos = pos + 1
        elseif c == "}" then pos = pos + 1; return obj
        else err("expected ',' or '}' in object") end
    end
end

decodeValue = function(str)
    skipWhitespace(str)
    local c = str:sub(pos, pos)
    if c == '"' then return decodeString(str)
    elseif c == "{" then return decodeObject(str)
    elseif c == "[" then return decodeArray(str)
    elseif c == "t" then
        if str:sub(pos, pos + 3) == "true" then pos = pos + 4; return true end
        err("invalid literal")
    elseif c == "f" then
        if str:sub(pos, pos + 4) == "false" then pos = pos + 5; return false end
        err("invalid literal")
    elseif c == "n" then
        if str:sub(pos, pos + 3) == "null" then pos = pos + 4; return nil end
        err("invalid literal")
    elseif c:match("[%d%-]") then
        return decodeNumber(str)
    end
    err("unexpected character: " .. c)
end

function json.decode(str)
    pos = 1
    local result = decodeValue(str)
    return result
end

return json