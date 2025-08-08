require'katu.utils.time'
local gruvbox = require'katu.gruvbox-colors'
require'debug'
require'katu.utils.class'

local Level = {
    trace = 1,
    debug = 10,
    info = 20,
    warn = 30,
    error = 40,
    fatal = 50,
}

local Log = {
    log_level = "info",
    level = "info", -- module level
    module = nil,
    color = gruvbox.light0_hard,
    time_color = gruvbox.bright_purple,
    module_color = gruvbox.bright_yellow,
    -- dbg = require('debug'),
    fd = io.stdout,
    colors = {
        trace = gruvbox.bright_aqua,
        debug = gruvbox.bright_purple,
        info = gruvbox.bright_green,
        warn = gruvbox.bright_yellow,
        error = gruvbox.bright_red,
        fatal = gruvbox.bright_red,
    },
}
log_level = "info"

function Log:write(msg, level)
    -- if self.filename and self.filename ~= '' then
        msg = msg .. '\n'
    -- end
    self:print(self:format(msg, level, self.colors[level]), level)
end

function Log:fatal(msg)
    self:write(msg, 'fatal')
end

function Log:error(msg)
    self:write( msg, 'error')
end

function Log:warn(msg)
    self:write(msg, 'warn')
end

function Log:info(msg)
    self:write(msg, 'info')
end

function Log:debug(msg)
    self:write(msg, 'debug')
end

function Log:trace(msg)
    self:write(msg, 'trace')
end

-- format: [time] [level] [file:line] [message]
function Log:format(message, level, color)
    local fmt = string.format
    local reset = gruvbox.light0
    if not color then
        color = ''
        reset = ''
    end
    if not level then
        level = self.level
    end

    local log_date = fmt('[%s]', os.date('%Y/%m/%d %X'))
    local log_llevel = fmt('[%s]', level)
    local log_preffix = fmt("%s%s%s %s%-7s%s", self.time_color, log_date, gruvbox.reset, color, log_llevel, gruvbox.reset)
    local log_module = ''
    if self.module then
        log_module = fmt('[%s]', self.module)
    end
    local log_mod = fmt(" %s%-10s%s%s", self.module_color, log_module, gruvbox.reset, self.color)
    local log_suffix = fmt(" %s%s", message, gruvbox.reset)
    local info = debug.getinfo(3)
    local utils = require'katu.utils'
    local filename = utils.split(info.short_src, '/')
    filename = filename[#filename]
    local log_debug = fmt(' %s[%s:%d] %s', self.colors["debug"], filename , info.currentline, gruvbox.reset)

    if self.module then
        local logout = log_preffix .. log_mod
        logout = logout .. log_debug .. log_suffix
        return logout
        -- return string.format(log_preffix .. log_mod .. log_suffix
    else
        return log_preffix .. log_suffix
    end
    -- return string.format("[%s] [%s] [%s:%d] %s", self.time.now(), level, self.dbg.getinfo(2).short_src, self.dbg.getinfo(2).currentline, message)
end
local insp = require'inspect'
function Log:print(msg,level)
    level = level or self.level
    if Level[level] >= Level[log_level] then
        self.fd:write(msg)
    end
end

function Log:set_file(filename)
    self.filename = filename
    self.fd = io.open(filename, "w")
end
Log.Level = Level

Log = _G.class(Log,
    {
        constructor = function(module, filename)
            local obj = {}
            if module then
                obj.module = module
            end
            if filename then
                obj.filename = filename
                obj.fd = io.open(filename, "w")
            end
            return obj
        end, adv = 1
    })
-- setmetatable(Log, mt)
local M = {
    Log = Log
}

return M
