local json = require('cjson')
local insp = require'inspect'

local fmt = string.format

local M = {}
function M.file_exist(name)
    local f=io.open(name,"r")
    if f~=nil then io.close(f) return true else return false end
end


function M.is_callable(f)
    local fm = getmetatable(f)
    return type(f) == 'function' or (fm ~= nil and fm.__call ~= nil)
end

function M.print_table(...)
    for k,v in pairs({...}) do
        print('key: ' .. k .. ': ' .. insp.inspect(v))
    end
    -- print(inspect(t,{depth=3}))
end

function M.pprint(obj,s,...)
    local opt = {...}
    opt = opt[1] or {}

    print(fmt('%s%s', s or '', insp.inspect(obj, {depth = opt.depth or 3})))
end

function M.map(t, f)
    local res = {}
    for k,v in pairs(t) do
        res[k] = f(v)
    end
    return res
end

function M.numel(t)
    local n = 0
    for _,_ in pairs(t) do
        n = n + 1
    end
    return n
end

function M.argparse(arg)
    if arg == 'help' then
        print('Usage: lua launch_tserver.lua [host] [port]')
        os.exit()
    end
    local Log = require'log'.Log

    if arg == 'debug' then
        Log.log_level = Log.Level.debug
        Log:info('log level set to DEBUG')
    end
    if arg == 'info' then
        Log.log_level = Log.Level.info
        Log:info('log level set to INFO')
    end
    if arg == 'warn' then
        Log.log_level = Log.Level.warn
        Log:info('log level set to WARN')
    end
    if arg == 'error' then
        Log.log_level = Log.Level.error
        Log:info('log level set to ERROR')
    end
    if arg[1] == 'fatal' then
        Log.log_level = Log.Level.fatal
        Log:info('log level set to FATAL')
    end
end

function M.print_mt(t)
    local mt = getmetatable(t)
    M.print_table(mt)
end

-- Function to split text into lines without losing empty lines
function M.split2(text)
    local lines = {}
    for line in string.gmatch(text, "([^\n]*)\n?") do
        table.insert(lines, line)
    end
    return lines
end

function M.split(inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t = {}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        table.insert(t, str)
    end

    return t
end

function M.is_before(date_str)
    -- Extract year, month, and day from the input string
    local year, month, day = date_str:match("(%d+)-(%d+)-(%d+)")

    -- Convert extracted values to numbers
    year, month, day = tonumber(year), tonumber(month), tonumber(day)

    -- Create a table representing the input date
    local input_date = os.time({year = year, month = month, day = day, hour = 0, min = 0, sec = 0})

    -- Get the current date as a table and set the time to 00:00:00 for comparison
    local today = os.time({year = os.date("*t").year, month = os.date("*t").month, day = os.date("*t").day, hour = 0, min = 0, sec = 0})

    -- Compare the two dates
    return input_date < today
end

function M.get_command_output(cmd)
    -- Execute the Fish shell command and capture the output
    local handle = io.popen(cmd)
    if not handle then
        print("Failed to execute command: " .. cmd)
        return nil
    end
    local result = handle:read("*a")
    handle:close()
    -- print('cmd: ' .. cmd)
    -- print('result size: ' .. #result)
    -- print('result: ' ..  result)

    -- Return the output, trimming any trailing newlines
    return result --:gsub("%s+$", "")
end
M.run = M.get_command_output

M.trim = function(s)
    return (s:gsub("^%s*(.-)%s*$", "%1"))
end

function M.traceback()
    local level = 1
    while true do
        local info = debug.getinfo(level, "Sl")
        if not info then break end
        if info.what == "C" then   -- is a C function?
            print(level, "C function")
        else   -- a Lua function
            print(string.format("%s:%d",
                info.short_src, info.currentline))
        end
        level = level + 1
    end
end

-- convert backtrace to quickfix list
function M.qbacktrace ()
    require'debug'
    local bt = debug.traceback()
    local f = '/tmp/bt.log'
    local file = io.open(f, 'w')
    file:write(bt)
    file:close()
    vim.cmd.cfile(f)
end


function M.get_file_line(entry)
    local parts = M.split(entry, ':')
    return parts[1], tonumber(parts[2])
end

return M

