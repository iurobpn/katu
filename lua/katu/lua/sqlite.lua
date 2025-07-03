local luasql = require("luasql.sqlite3")
require('class')

local Sql = {filename = ''}


function Sql:connect(filename)
    self.filename = filename or self.filename
    self.env = luasql.sqlite3()
    self.conn = self.env:connect(self.filename)
    if self.conn == nil then
        error('Could not connect to the database ' .. self.filename)
        return false
    end
    self.connected =true
    return true
end

function Sql:close()
    collectgarbage()
    self.conn:close()
    self.env:close()
    self.conn = nil
    self.env = nil
    self.connected = false
end

-- Function to run a SQL command
function Sql:run(cmd)
    if cmd == '' or cmd == nil then
        error('No command to run')
        return
    end
    if type(cmd) ~= 'string' then
        error('Command must be a string')
        return
    end
    if not self.connected then
        error('Not connected to the database')
        return
    end
    self.conn:execute(cmd)
end
function Sql:query_n(cmd)
    if cmd == '' or cmd == nil then
        error('No command to run')
        return
    end
    if type(cmd) ~= 'string' then
        error('Command must be a string')
        return
    end
    if not self.connected then
        error('Not connected to the database')
        return
    end

    local tables = {}
    local cur = self.conn:execute(cmd)
    if cur == nil then
        error('query did not returned anything')
        return
    end
    local row = cur:fetch({}, "a")
    while row do
        table.insert(tables, row)
        row = cur:fetch(row, "a")
    end

    return tables

end

function Sql:query(query)
    -- Get the last inserted task_id
    local cursor = self.conn:execute(query)
    local out = cursor:fetch()
    return out
end

local M = {
    Sql = Sql
}

Sql = _G.class(Sql, {constructor = function(filename)
    local self = {}
    self.filename = filename
    return self
end})


return M
