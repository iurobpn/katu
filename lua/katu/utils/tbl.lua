local M = {}

M.remove = function(tbl, key)
    for k, _ in pairs(tbl) do
        if k == key then
            tbl[k] = nil
            break
        end
    end
end

M.contains = function(tbl, key)
    for k, _ in pairs(tbl) do
        if k == key then
            return true
        end
    end
    return false
end
M.contains_val = function(tbl, val)
    for _, v in pairs(tbl) do
        if v == val then
            return true
        end
    end
    return false
end

M.extend = function(tbl1, tbl2)
    for k,v in pairs(tbl2) do
        tbl1[k] = v
    end
    return tbl1
end

M.flatten = function(tbl, d)
    if d == nil then
        d = 5
    end
    if d == 0 then
        return tbl
    end
    local res = {}
    for _, v in pairs(tbl) do
        if type(v) == 'table' then
            local inner = M.flatten(v, d-1)
            res = require'katu.utils.list'.extend(res, inner)
        else
            table.insert(res, v)
        end
    end

    return res
end

M.merge = function(t1, t2, depth)
    if depth == nil then
        depth = 1
    end
    for k, v in pairs(t2) do
        if type(v) == 'table' then
            if type(t1[k] or false) == 'table' then
                if depth > 0 then
                    M.merge(t1[k] or {}, t2[k] or {}, depth - 1)
                else
                    t1[k] = v
                end
            else
                t1[k] = v
            end
        else
            t1[k] = v
        end
    end
end


function M.to_json2(tbl)
    local function is_array(tbl)
        local max = 0
        local n = 0
        for k, v in pairs(tbl) do
            if type(k) ~= "number" or k <= 0 or k ~= math.floor(k) then
                return false
            end
            if k > max then
                max = k
            end
            n = n + 1
        end
        if max ~= n then
            return false
        end
        return max -- Return max index
    end

    local function serialize(obj, indent, visited)
        local t = type(obj)
        indent = indent or ""
        visited = visited or {}
        local newline = "\n"
        local indent_str = "  " -- Two spaces

        if t == "table" then
            if visited[obj] then
                error("Cannot encode a table with recursive references")
            end
            visited[obj] = true

            local items = {}
            local next_indent = indent .. indent_str
            local array_length = is_array(obj)
            if array_length then
                -- It's an array
                table.insert(items, "[")
                for i = 1, array_length do
                    local value = serialize(obj[i], next_indent, visited)
                    table.insert(items, next_indent .. value .. ",")
                end
                if array_length > 0 then
                    items[#items] = items[#items]:gsub(",$", "") -- Remove last comma
                end
                table.insert(items, indent .. "]")
            else
                -- It's an object
                table.insert(items, "{")
                local keys = {}
                for k in pairs(obj) do
                    if type(k) ~= "string" then
                        error("JSON object keys must be strings")
                    end
                    table.insert(keys, k)
                end
                table.sort(keys)
                for _, k in ipairs(keys) do
                    local v = obj[k]
                    local key = serialize(k)
                    local value = serialize(v, next_indent, visited)
                    table.insert(items, next_indent .. key .. ": " .. value .. ",")
                end
                if #keys > 0 then
                    items[#items] = items[#items]:gsub(",$", "") -- Remove last comma
                end
                table.insert(items, indent .. "}")
            end
            visited[obj] = nil
            return table.concat(items, newline)
        elseif t == "string" then
            -- Escape special characters in strings
            local s = obj:gsub("\\", "\\\\")
                :gsub('"', '\\"')
                :gsub("\b", "\\b")
                :gsub("\f", "\\f")
                :gsub("\n", "\\n")
                :gsub("\r", "\\r")
                :gsub("\t", "\\t")
            return '"' .. s .. '"'
        elseif t == "number" or t == "boolean" then
            return tostring(obj)
        elseif t == "nil" then
            return "null"
        else
            error("Unsupported data type: " .. t)
        end
    end
    return serialize(tbl)
end

M.deepcopy = function(tbl)
    local copy = {}
    for k, v in pairs(tbl) do
        if type(v) == 'table' then
            copy[k] = M.deepcopy(v)
        else
            copy[k] = v
        end
    end
    return copy
end

function M.to_json(tbl)
    local json = require('dkjson')
    return json.encode(tbl, { indent = true })
end

function M.to_json_main(tbl)
    local function is_array(tbl)
        local max = 0
        local n = 0
        for k, v in pairs(tbl) do
            if type(k) ~= "number" or k <= 0 or k ~= math.floor(k) then
                return false
            end
            if k > max then
                max = k
            end
            n = n + 1
        end
        if max ~= n then
            return false
        end
        return max -- Return max index
    end

    local function serialize(obj, indent, visited)
        local t = type(obj)
        indent = indent or ""
        visited = visited or {}
        local newline = "\n"
        local indent_str = "    " -- Four spaces

        if t == "table" then
            if visited[obj] then
                error("Cannot encode a table with recursive references")
            end
            visited[obj] = true

            local items = {}
            local next_indent = indent .. indent_str
            local array_length = is_array(obj)
            if array_length then
                -- It's an array
                table.insert(items, "[")
                for i = 1, array_length do
                    local value = serialize(obj[i], next_indent, visited)
                    table.insert(items, next_indent .. value .. ",")
                end
                if array_length > 0 then
                    items[#items] = items[#items]:gsub(",$", "") -- Remove last comma
                end
                table.insert(items, indent .. "]")
            else
                -- It's an object
                table.insert(items, "{")
                local keys = {}
                for k in pairs(obj) do
                    if type(k) ~= "string" then
                        error("JSON object keys must be strings")
                    end
                    table.insert(keys, k)
                end
                table.sort(keys)
                for _, k in ipairs(keys) do
                    local v = obj[k]
                    local key = serialize(k)
                    local value = serialize(v, next_indent, visited)
                    table.insert(items, next_indent .. key .. ": " .. value .. ",")
                end
                if #keys > 0 then
                    items[#items] = items[#items]:gsub(",$", "") -- Remove last comma
                end
                table.insert(items, indent .. "}")
            end
            visited[obj] = nil
            return table.concat(items, newline)
        elseif t == "string" then
            -- Escape special characters in strings
            local s = obj:gsub("\\", "\\\\")
                :gsub('"', '\\"')
                :gsub("\b", "\\b")
                :gsub("\f", "\\f")
                :gsub("\n", "\\n")
                :gsub("\r", "\\r")
                :gsub("\t", "\\t")
            return '"' .. s .. '"'
        elseif t == "number" or t == "boolean" then
            return tostring(obj)
        elseif t == "nil" then
            return "null"
        else
            error("Unsupported data type: " .. t)
        end
    end
    return serialize(tbl)
end

function M.from_json(json_str)
    local json = require('dkjson')
    local obj, pos, err = json.decode(json_str, 1, nil)
    if err then
        error("Error parsing JSON: " .. err)
    end
    return obj
end

return M

