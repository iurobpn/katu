-- timer_plugin.lua
local timer_plugin = {
    filename = "tasks_pl.json",
}
-- local module = 'tasks'
local res, err = pcall(require, module)
if not res then
    print("Error loading module: " .. module)
    print("Error: " .. err)
    return
end
-- local tasks_plugin = require(module)
-- require'tasks.timelog'
-- Global variables to manage the timer and window
local countdown = {
    win = nil,
    buf = nil,
    timer = nil,
    time_left = nil,
    start_time = nil,
    duration = nil,
    description = nil,
}


-- Dependencies
local json = vim.fn.json_encode and vim.fn.json_decode and true or false
if not json then
    error("This plugin requires Neovim with JSON support (version 0.5 or higher).")
end

-- Assume the 'tasks' plugin is available and has been required as 'tasks_plugin'


-- Data structures
local tasks = {}
local projects = {}
local active_tasks = {}
local done_tasks = {}
local logs = {}

local task_id_counter = 0
local project_id_counter = 0

local current_task = nil
local timer = nil
local timer_start_time = nil
local timer_active = false
local popup_win = nil

-- File paths for data persistence
--
local data_dir = "/home/gagarin/git/pkm/.tasks"
local tasks_file = data_dir .. '/' .. timer_plugin.filename
local logs_file = data_dir .. '/logs.json'

-- Utility functions
local function get_next_task_id()
    task_id_counter = task_id_counter + 1
    return task_id_counter
end

local function get_next_project_id()
    project_id_counter = project_id_counter + 1
    return project_id_counter
end

local function format_time(seconds)
    local hours = math.floor(seconds / 3600)
    local mins = math.floor((seconds % 3600) / 60)
    local secs = seconds % 60
    return string.format("%02d:%02d:%02d", hours, mins, secs)
end


--- format task to a string
---@param task table
---@return string
local format_task = function(task)
    return string.format(
        "%d | %-10s | t_start: %s | t_elapsed: %s | t_est: %s",
        task.id,
        task.name,
        -- task.description or "",
        task.start_time and os.date("%c", task.start_time) or "N/A",
        format_time(task.time_worked),
        task.estimated_time and format_time(task.estimated_time) or "N/A"
    )
end

local function save_data()
    if not vim.fn.isdirectory(data_dir) then
        vim.fn.mkdir(data_dir, "p")
    end

    local tasks_data = {
        tasks = tasks,
        active_tasks = active_tasks,
        done_tasks = done_tasks,
        task_id_counter = task_id_counter,
    }
    local tasks_json = vim.fn.json_encode(tasks_data)
    local tasks_file_handle = io.open(tasks_file, "w")
    tasks_file_handle:write(tasks_json)
    tasks_file_handle:close()

    local logs_data = {
        logs = logs,
    }
    local logs_json = vim.fn.json_encode(logs_data)
    local logs_file_handle = io.open(logs_file, "w")
    logs_file_handle:write(logs_json)
    logs_file_handle:close()
end

local function load_data()
    if vim.fn.filereadable(tasks_file) == 1 then
        local tasks_file_handle = io.open(tasks_file, "r")
        local tasks_json = tasks_file_handle:read("*a")
        tasks_file_handle:close()
        local tasks_data = vim.fn.json_decode(tasks_json)
        tasks = tasks_data.tasks or {}
        active_tasks = tasks_data.active_tasks or {}
        done_tasks = tasks_data.done_tasks or {}
        task_id_counter = tasks_data.task_id_counter or 0
    end

    if vim.fn.filereadable(logs_file) == 1 then
        local logs_file_handle = io.open(logs_file, "r")
        local logs_json = logs_file_handle:read("*a")
        logs_file_handle:close()
        local logs_data = vim.fn.json_decode(logs_json)
        logs = logs_data.logs or {}
    end
end

-- Load data on startup
load_data()

--- Timer command function to handle :Timer ...
--- @param args any 
function timer_plugin.TimerCommand(args)
    local subcommand = args.fargs[1]
    if not subcommand then
        print("Usage: :Timer <start|pause|stop|toggle> [task_id]")
        return
    end

    if subcommand == 'start' then
        local task_id_str = args.fargs[2]
        local task_id
        if task_id_str ~= nil then
            task_id = tonumber(task_id_str)
        end
        timer_plugin.TimerStart(task_id)
    elseif subcommand == 'countdown' then
        local time
        if args.fargs[2] then
            time = args.fargs[2]
        end
        if args.fargs[3] ~= nil then
            local unit = args.fargs[3]
            if unit == 'min' then
                time = tonumber(time)*60
            end
            table.remove(args.fargs, 3)
        end
        if not time then
            print("Usage: :Timer countdown <time>")
            return
        end
        table.remove(args.fargs, 1)
        vim.cmd('Countdown ' .. table.concat(args.fargs, ' '))
        -- countdown.start(tonumber(time), args.fargs[3], args.fargs[4])
    elseif subcommand == 'pause' then
        timer_plugin.TimerPause()
    elseif subcommand == 'stop' then
        timer_plugin.TimerStop()
    elseif subcommand == 'toggle' then
        timer_plugin.TimerToggle()
    else
        print("Invalid Timer command. Usage: :Timer <start|pause|stop|toggle|countdown> [task_id]")
    end
end

function countdown.start(duration, description, callback)
    countdown.description = description
    countdown.duration = duration
    countdown.time_left = duration
    local buf = vim.api.nvim_create_buf(false, true) -- Create a new empty buffer
    local width = 5
    local height = 1
    local row = math.floor(1) -- vim.o.lines
    local col = math.floor((vim.o.columns - width) / 2)

    vim.api.nvim_set_hl(0, "MyFloatBorder", { fg = katu.color.bright_blue, bg = "None" }) -- bright_red for the border
    vim.api.nvim_set_hl(0, "FloatContent", { fg = katu.color.bright_blue, bg = "None" }) -- bright_red for the border

    -- Create a floating window
    countdown.win = vim.api.nvim_open_win(buf, true, {
        relative = 'editor',
        width = width,
        height = height,
        row = row,
        col = col,
        style = 'minimal',
        border = 'rounded',
        focusable = false,
    })
    vim.api.nvim_set_option_value('winblend', 90, { scope = "local", win = countdown.win }) -- Set transparency (0-100, 0 is opaque, 100 is fully transparent)
    vim.api.nvim_set_option_value('winhl', 'NormalFloat:FloatContent,FloatBorder:MyFloatBorder', { scope = "local", win = countdown.win })
    -- Follow main colorscheme
    -- Define a custom highlight group for the border
    vim.cmd("wincmd p")


    countdown.timer = vim.loop.new_timer()
    countdown.timer:start(0, 1000, vim.schedule_wrap(function()
        countdown.update_popup(callback)
    end))
end

-- Timer functions
function timer_plugin.TimerStart(task_id)
    if timer_active then
        print("A timer is already running.")
        return
    end

    timer_start_time = os.time()
    timer_active = true

    -- Start the timer
    timer = vim.loop.new_timer()
    timer:start(0, 1000, vim.schedule_wrap(function()
        timer_plugin.update_popup()
    end))


    print("Timer started for task ID: ", task_id)
    if task_id == nil then
        vim.notify("No task ID provided. Starting timer without a task.")
        current_task = timer_plugin.TaskNew("Unnamed task")
        task_id = current_task.id
    else
        vim.notify("task ID provided: " .. task_id)
        current_task = tasks[task_id]
    end
    require'katu.utils'.pprint(current_task, 'current_task: ')
    -- Log start time
    table.insert(logs, {
        task_id = task_id,
        task_name = current_task.name,
        time_start = timer_start_time,
        time_end = nil,
    })
    -- Create popup window
    timer_plugin.create_popup()

    save_data()
    if task_id == 0 then
        print("Timer started")
    else
        print("Timer started for task ID:", task_id)
    end
end

function timer_plugin.TimerPause()
    if not timer_active then
        print("No active timer to pause.")
        return
    end

    local elapsed = os.time() - timer_start_time
    current_task.time_worked = (current_task.time_worked or 0) + elapsed
    timer:stop()
    timer:close()
    timer_active = false

    -- Update log
    for i = #logs, 1, -1 do
        if not logs[i].time_end then
            logs[i].time_end = os.time()
            break
        end
    end

    -- Close popup window
    timer_plugin.close_popup()

    save_data()
    print("Timer paused. Time worked:", format_time(current_task.time_worked))
end

function timer_plugin.TimerStop()
    if not timer_active then
        print("No active timer to stop.")
        return
    end
    timer_plugin.TimerPause()
    current_task = nil
    print("Timer stopped.")
end

function timer_plugin.TimerToggle()
    if popup_win and vim.api.nvim_win_is_valid(popup_win) then
        timer_plugin.close_popup()
    else
        timer_plugin.create_popup()
    end
end

-- Popup window functions
function timer_plugin.create_popup()
    if popup_win and vim.api.nvim_win_is_valid(popup_win) then
        return
    end

    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_option_value('bufhidden', 'wipe', {buf = buf})

    local elapsed = os.time() - timer_start_time + (current_task.time_worked or 0)
    local time_str = format_time(elapsed)
    local content = { "Task: " .. current_task.name, "Time: " .. time_str }
    local width = 0
    for _, line in ipairs(content) do
        if #line > width then
            width = #line
        end
    end
    local height = #content
    local row = 0
    local col = vim.o.columns - width - 2

    popup_win = vim.api.nvim_open_win(buf, false, {
        relative = 'editor',
        width = width + 2,
        height = height,
        row = row,
        col = col,
        style = 'minimal',
        border = 'single',
        focusable = false,
    })

    timer_plugin.update_popup()
end
local blink_state = false

function countdown.update_popup(callback)
    require'katu.utils'.pprint(countdown, 'countdown: ')
    if not countdown.win or not vim.api.nvim_win_is_valid(countdown.win) then
        return
    end

    -- local hours = math.floor(time_left / (60*60))
    local minutes = math.floor(countdown.time_left / 60)
    local seconds = countdown.time_left % 60
    local time_str = string.format("%02d:%02d", minutes, seconds)

    local buf = vim.api.nvim_win_get_buf(countdown.win)
    -- Update buffer with the remaining time
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { time_str })

    -- Change only the foreground color in the last 30 seconds (blink every half second)
    if countdown.time_left <= 30 then
        if blink_state then
            vim.api.nvim_set_hl(0, "MyFloatText", { fg = katu.color.bright_red, bg = "None" }) -- bright_red for text
            vim.api.nvim_set_hl(0, "MyFloatBorder", { fg = katu.color.bright_red, bg = "None" }) -- bright_red for text
        else
            vim.api.nvim_set_hl(0, "MyFloatText", { fg = "None", bg = "None" }) -- invisible text
            vim.api.nvim_set_hl(0, "MyFloatBorder", { fg = "None", bg = "None" }) -- bright_red for text
        end
        blink_state = not blink_state
        vim.api.nvim_set_option_value('winhl', 'NormalFloat:MyFloatText,FloatBorder:MyFloatBorder', { scope = "local", win = countdown.win })
    end

    -- Stop the timer when time reaches 0
    if countdown.time_left <= 0 then
        countdown.time_left = 0
        countdown.timer:stop()
        countdown.timer:close()
        countdown.timer = nil

        vim.api.nvim_set_hl(0, "MyFloatText", { fg = katu.color.bright_red, bg = "None" }) -- bright_red for text
        vim.api.nvim_set_hl(0, "MyFloatBorder", { fg = katu.color.bright_red, bg = "None" }) -- bright_red for text
        vim.api.nvim_set_option_value('winhl', 'NormalFloat:MyFloatText,FloatBorder:MyFloatBorder', { scope = "local", win = countdown.win })
        -- vim.api.nvim_win_close(countdown.win, true)
        if callback then
            callback()
        end
        -- Log the timer details if a description is provided
        if countdown.description and countdown.description ~= "" then
            vim.notify("Countdown timer completed: " .. countdown.description)
            local log_entry = {
                start_time = os.date("%Y-%m-%d %H:%M:%S", countdown.start_time),
                duration = countdown.duration,
                description = countdown.description,
            }


            -- Define log file path
            local log_file = vim.fn.stdpath('data') .. '/.tasks.countdown.json'
            local logs = {}

            -- Read existing log entries if the file exists
            if vim.fn.filereadable(log_file) == 1 then
                local log_content = vim.fn.readfile(log_file)
                local log_str = table.concat(log_content, '\n')
                logs = vim.fn.json_decode(log_str) or {}
            end

            -- Append new log entry
            table.insert(logs, log_entry)

            -- Write updated logs back to the file
            local log_json = vim.fn.json_encode(logs)
            vim.fn.writefile({ log_json }, log_file)
        end
    else
        countdown.time_left = countdown.time_left - 1
    end
end

function timer_plugin.update_popup()
    if not popup_win or not vim.api.nvim_win_is_valid(popup_win) then
        return
    end

    local buf = vim.api.nvim_win_get_buf(popup_win)
    local elapsed = os.time() - timer_start_time + (current_task.time_worked or 0)
    local time_str = format_time(elapsed)
    local content = { "Task: " .. current_task.name, "Time: " .. time_str }
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)
end

function timer_plugin.close_popup()
    if popup_win and vim.api.nvim_win_is_valid(popup_win) then
        vim.api.nvim_win_close(popup_win, true)
        popup_win = nil
    end
end

-- Stats functions
function timer_plugin.ShowStats(args)
    local period = args.fargs[1]
    if not period then
        print("Usage: :Stats <daily|weekly|monthly>")
        return
    end

    local now = os.time()
    local start_time

    if period == 'daily' then
        start_time = os.time({ year = os.date("%Y"), month = os.date("%m"), day = os.date("%d"), hour = 0 })
    elseif period == 'weekly' then
        local day_of_week = os.date("*t").wday
        start_time = now - (day_of_week - 1) * 24 * 3600
    elseif period == 'monthly' then
        start_time = os.time({ year = os.date("%Y"), month = os.date("%m"), day = 1, hour = 0 })
    else
        print("Invalid period. Usage: :Stats <daily|weekly|monthly>")
        return
    end

    local total_time = 0
    local task_times = {}

    for _, log in ipairs(logs) do
        if log.time_end and log.time_start >= start_time then
            local duration = log.time_end - log.time_start
            total_time = total_time + duration
            task_times[log.task_id] = (task_times[log.task_id] or 0) + duration
        end
    end

    print(string.format("Total time worked (%s): %s", period, format_time(total_time)))

    print("Time spent per task:")
    for task_id, time_spent in pairs(task_times) do
        local task = tasks[task_id]
        if task then
            print(string.format("%d - %s: %s", task_id, task.name, format_time(time_spent)))
        end
    end
end

function timer_plugin.complete_timer_command(arg_lead, cmd_line, cursor_pos)
    -- These are the valid completions for the command
    local options = { "new", "list", "del", "done", "import", "export", "countdown", "toggle" }
    -- Return all options that start with the current argument lead
    return vim.tbl_filter(function(option)
        return vim.startswith(option, arg_lead)
    end, options)
end

function countdown.complete(arg_lead, cmd_line, cursor_pos)
    -- These are the valid completions for the command
    local options = { "start", "close" }
    -- Return all options that start with the current argument lead
    return vim.tbl_filter(function(option)
        return vim.startswith(option, arg_lead)
    end, options)
end

-- Command registrations
vim.api.nvim_create_user_command('Timer', function(args)
    timer_plugin.TimerCommand(args)
end, { nargs = '*' , complete = timer_plugin.complete_timer_command })

-- Command to start or control the countdown timer
vim.api.nvim_create_user_command("Countdown", function(opts)
    vim.notify('countdown timer command: ' .. opts.args)
    local args = vim.split(opts.args, " ", { plain = true, trimempty = true })
    if #args >= 1 then
        local first_arg = args[1]
        vim.notify('countdown timer command: ' .. first_arg)
        if first_arg == "close" then
            local vid = countdown.win
            countdown.win = nil
            vim.notify('Closing countdown timer')
            -- Close the timer window and clean up
            if countdown.timer then
                countdown.timer:stop()
                countdown.timer:close()
                countdown.timer = nil
            end
            if vid and vim.api.nvim_win_is_valid(vid) then
                vim.api.nvim_win_close(vid, true)
                countdown.win = nil
            end
            if countdown.buf and vim.api.nvim_buf_is_valid(countdown.buf) then
                vim.api.nvim_buf_delete(countdown.buf, { force = true })
                countdown.buf = nil
            end
            print("Countdown timer closed.")
        else
            -- Start a new countdown
            local duration = tonumber(first_arg)
            if args[2] then
                local unit = args[2]
                if unit == 'min' then
                    duration = duration*60
                end
                table.remove(args, 2)
            end
            if duration then
                -- Allow spaces in the description
                local description = table.concat(vim.list_slice(args, 2), " ")
                countdown.start(duration, description)
            else
                print("Invalid duration. Usage: :Countdown time [description]")
            end
        end
    else
        print("Usage: :Countdown time [description]")
    end
end, { nargs = "*" , complete = countdown.complete })


vim.api.nvim_create_user_command('ShowLogs', function()
    timer_plugin.ShowLogs()
end, {})

vim.api.nvim_create_user_command('Stats', function(args)
    timer_plugin.ShowStats(args)
end, { nargs = 1 })

-- Function to display logs
function timer_plugin.ShowLogs()
    print("Timer Logs:")
    for _, log in ipairs(logs) do
        if log.time_end then
            local duration = log.time_end - log.time_start
            print(string.format(
                "%s - %s (%s) -- Task %d: %s",
                os.date("%c", log.time_start),
                os.date("%c", log.time_end),
                format_time(duration),
                log.task_id,
                log.task_name
            ))
        else
            print(string.format(
                "%s - (ongoing) -- Task %d: %s",
                os.date("%c", log.time_start),
                log.task_id,
                log.task_name
            ))
        end
    end
end

-- Ensure data is saved when Neovim exits
vim.api.nvim_create_autocmd("VimLeavePre", {
    pattern = "*",
    callback = function()
        save_data()
    end,

})

return timer_plugin

