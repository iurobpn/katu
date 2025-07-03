local sqlite3 = require("lsqlite3")

require('class')

local Sql = {filename = ''}



function Sql:connect(filename)
    self.filename = filename or self.filename

    self.db = sqlite3.open(self.filename)
    if self.db == nil then
        error('Could not connect to the database ' .. self.filename)
    end
    self.connected = true

    return true
end

function Sql:close()
    -- collectgarbage()
    -- self.conn:close()
    -- self.env:close()
    -- self.conn = nil
    -- self.env = nil
    self.db:close()
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
    self.db:exec(cmd)
end
function Sql:query_n(cmd)
    if cmd == '' or cmd == nil then
        error('No command to run')
        return
    end
    if type(cmd) ~= 'string' then
        error('Command must be a string')
    end
    if not self.connected then
        error('Not connected to the database')
    end

    local rows = {}
    for row in self.db:nrows(cmd) do
        table.insert(rows, row)
    end

    return rows
end

function Sql:query(query)
    -- Get the last inserted task_id
    local result = self.db:nrows(query)
    return result
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
