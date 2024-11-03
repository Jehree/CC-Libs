function GetTable(path)
    local file = fs.open(path, "r")
    local data = file.readAll()
    file.close()
    return textutils.unserialize(data)
end

function SaveTable(table, path)
    local file = fs.open(path, "w")
    file.write(textutils.serialize(table))
    file.close()
end

function ArrayHasValue(array, value, snippet)
    for k, v in ipairs(array) do
        if v == value then return true end
    end

    return false
end

function GetArrayLength(array)
    local length = 0

    for k, v in pairs(array) do
        length = length + 1
    end

    return length
end

function StringIncludesString(fullString, snippetString)
    fullString = tostring(fullString)
    snippetString = tostring(snippetString)

    if string.find(string.lower(fullString), string.lower(snippetString)) then return true end
    return false
end

function StringSplit(theString, delimiter, convertToNumber)
    local strings = {}
    for v in string.gmatch(theString, '([^'..delimiter..']+)') do
        local word = v
        local number
        if convertToNumber then
            number = tonumber(v)
        end

        if convertToNumber then
            table.insert(strings, number)
        else
            table.insert(strings, word)
        end
    end
    return strings
end
