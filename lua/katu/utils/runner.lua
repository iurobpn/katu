-- run commands on tmux/zellij panes
-- Usage: :Run <command> -- float
-- Usage: :Run tab <command> -- new tab
local function run(cmd)
    -- Execute the command and capture the output
    local handle = io.popen(cmd)
    if not handle then
        print("Failed to execute command: " .. cmd)
        return false
    end
    local result = handle:read("*a")
    handle:close()

    -- Return the output, trimming any trailing newlines
    return result --:gsub("%s+$", "")
end

local M = {}
local zellij_options = {
    'float',
    'close-on-exit',
    'right',
    'left',
    'up',
    'down',
    'in-place',
    'start-suspended'
}
local tmux_options = {
}

-- include directions for new panes
function M.tmux_run(opts)
    if type(opts) == 'string' then
        opts = {args = opts}
        opts.fargs = vim.split(opts.args, ' ')
    end
    local z_opts = {cmd = '', args = '', win_type = 'pane', dir = 'left'}
    -- z_opts.args = ' --floating'
    -- the arguments before a '--' are options for the command
    -- if no '--' is present, the command is assumed to be a pane command
    local cmd = 'tmux display-popup "'  .. opts.args .. '"'
    print('Running command: ' .. cmd)

    local status, msg = run(cmd)
    return status, msg
end
-- include directions for new panes
function M.zellij_run(opts)
    if type(opts) == 'string' then
        opts = {args = opts}
        opts.fargs = vim.split(opts.args, ' ')
    end
    local z_opts = {cmd = '', args = '', win_type = 'pane', dir = 'left'}
    -- z_opts.args = ' --floating'
    -- the arguments before a '--' are options for the command
    -- if no '--' is present, the command is assumed to be a pane command
    local res = opts.args:match(' %-%- ')
    if res ~= nil then
        print('res')
        for i, opt in ipairs(opts.fargs) do
            if opt == '--' then
                z_opts.cmd =  table.concat(opts.fargs, ' ', i+1)
                break
            end
            if opt == 'float' then
                z_opts.args = z_opts.args .. ' --floating'
            elseif opt == 'close-on-exit' then
                z_opts.args = z_opts.args .. ' --close-on-exit'
            elseif  opt == 'right' or opt == 'left' or opt == 'up' or opt == 'down' then
                z_opts.args = z_opts.args .. ' --direction ' .. opt
            elseif opt == 'in-place' then
                z_opts.args = z_opts.args .. ' --' .. opt
            elseif opt == 'start-suspended' then
                z_opts.args = z_opts.args .. ' --start-suspended'
            else
                print('Invalid option: ' .. opt)
            end
        end
    else
        z_opts.args = '--floating'
        z_opts.cmd = opts.args
    end
    local cmd = 'zellij run ' .. z_opts.args .. ' -- ' .. z_opts.cmd
    print('Running command: ' .. cmd)

    local status, msg = run(cmd)
    -- local st = vim.inspect(status)
    -- local msg = vim.inspect(err)

    -- if status then
    --     print('Command ran successfully with result: ' .. msg .. ' status: ' .. st)
    -- else
    --     print('Error running with err: ' .. st .. ' msg: ' .. msg)
    -- end

    return status, msg
end

function M.input_complete(arg_lead, _, _)
    -- These are the valid completions for the command
    -- Return all options that start with the current argument lead

    local opt = vim.tbl_filter(function(option)
        return vim.startswith(option, arg_lead)
    end, M.options)
    return table.concat(opt, ' ')
end

function M.zellij_complete(arg_lead, _, _)
    -- These are the valid completions for the command
    -- Return all options that start with the current argument lead
    return vim.tbl_filter(function(option)
        return vim.startswith(option, arg_lead)
    end, M.zellij_options)
end
function M.tmux_complete(arg_lead, _, _)
    -- These are the valid completions for the command
    -- Return all options that start with the current argument lead
    return vim.tbl_filter(function(option)
        return vim.startswith(option, arg_lead)
    end, M.tmux_options)
end

M.ask_run = function()
    vim.ui.input(
        {
            prompt = "Run command: ",
            completion = 'lua,runner.zellij_complete',
        },
        function(args)
            vim.cmd('Run ' .. args)
        end)
    -- vim.cmd('ZellijRun ' .. args)
end

-- create the command
vim.api.nvim_create_user_command("ZellijRun",
    function(opts)
        M.zellij_run(opts)
    end,
    {
        nargs = "+",
        complete = M.complete,
        bang = true,
        desc = 'run a command with zellij in the current pane or a new pane (float or aside)'
    })

vim.api.nvim_create_user_command("TmuxRun",
    function(opts)
        M.tmux_run(opts)
    end,
    {
        nargs = "+",
        complete = M.tmux_complete,
        bang = true,
        desc = 'run a command in a tmux popup'
    })
vim.api.nvim_set_keymap('n',
    '<F5>',
    ':TmuxRun ',
    {
        noremap = true,
        silent = true,
        desc = 'run a command using zellij run and options'
    })
-- vim.ui.select()
function M.run(opts)
    M.tmux_run(opts)
end


return M
