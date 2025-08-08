-- TODO create a private members table to be automatically detected by the __index metamethod

--- class generator
---@param t table
---@param opts any
---@return table
function _G.class(t, opts)
    t = t or {}
    local constructor = nil
    for k, v in pairs(t) do
        if k == 'new' then
            constructor = v
        end
    end

    opts = opts or {}
    for k, v in pairs(opts) do
        if k == 'constructor' or k == 'new' then
            constructor = v
        end
    end

    local mt = getmetatable(t) or {}
    mt.__call = function(self, ...) 
        local obj = {}
        if constructor ~= nil then
            obj = constructor(...)
        end
        for k, v in pairs(opts) do
            obj[k] = v
        end
        setmetatable(obj,t)
        return obj
    end
    setmetatable(t, mt)
    t.__index = t

    return t
end

return true

