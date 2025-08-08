local Window = require ('katu.nvim.ui.float').Window
-- local inspect = require 'inspect'

local fs = require ('katu.utils.fs')
-- local Log = require'katu.lua.log'.Log


local utils = require('katu.utils')
local fzf = require('katu.nvim.fzf')

local fmt = string.format


local qfloat = {
    win_id = nil,
    last_file = '',
}

function qfloat.read_output(cmd)
    local fd = io.popen(cmd)
    if fd == nil then
        return nil
    end
    local s = fd:read('*a')
    fd:close()
    return s
end

function qfloat.init()
    if vim.g.proj and vim.g.proj.qfloat then
        for k, v in pairs(vim.g.proj.qfloat) do
            qfloat[k] = v
        end
    end
    vim.g.proj.register('qfloat', qfloat)
end

function qfloat.qcheck(fname)
    if not fs.file_exists(fname) then
        vim.notify('File does not exist')
        return
    end
    local cmd = 'luacheck --no-color ' .. fname
    qfloat.qrun(cmd)
end

-- local log_file = '/tmp/error_lua.log'
function qfloat.qrun(cmd)
    if cmd == nil or cmd == '' then
        qfloat.qrun_current()
        vim.notify('No command to run.')
        return
    end
    if type(cmd) == 'table' and cmd.args ~= nil then
        cmd = cmd.args
        if cmd == nil or cmd == '' then
            local file = vim.fn.expand('%')
            if file == nil or file == '' then
                vim.notify('No file to check.')
                return
            end
            local ft = vim.o.filetype
            if ft == 'lua' or ft == 'python' then
                cmd = vim.o.filetype .. ' ' .. file
            end
        end
    end
    local fname = '/tmp/error_lua.log'
    cmd = cmd .. ' > ' .. fname
    utils.get_command_output(cmd)
    vim.cmd.cfile(fname)
    --check if there is errors in the qfix
    local qf = vim.fn.getqflist()
    if #qf == 0 then
        vim.notify('No errors found.')
    end
    -- qfloat.qfile(fname)
end

function qfloat.qfile(filename)
    if not fs.file_exists(filename) then
        vim.notify('File does not exist: ' .. filename)
        return
    end
    vim.cmd.cfile(filename)
    -- qfloat.qopen()
end

function qfloat.qrun_fzf()
    local source = 'fd . --type f'
    local sink = function(selected)
        if selected and #selected > 0 then
            qfloat.qrun_file(selected)
        end
    end
    local options = '--prompt="Select a file> "'

    fzf.run({ source = source, sink = sink, options = options })
end

-- Store the window ID globally
-- Function to open the quickfix list in a floating window
function qfloat.qopen()
    vim.cmd('cclose')
    vim.cmd('copen')

    -- Check if the quickfix list is empty
    local n_lines = vim.fn.getqflist({ size = 1 }).size
    if n_lines == 0 then
        vim.notify("Quickfix list is empty.")
        vim.cmd('cclose')
        return
    end

    -- Calculate window size and position
    -- local opts = get_options({rel_width = 0.5, rel_height = 0.3, rel_row = 0.75, rel_col = 0.25})

    --
    -- Open the quickfix window
    local win = Window({
        width = 0.5,
        height = 0.3,
        row = 0.75,
        col = 0.25,
        current = true,
        option = {
            buffer = {
                modifiable = false,
            },
        }
    })
    win:add_map('n', '<CR>', ':QlinkClose<CR>', { noremap = true, silent = true })
    win:add_map('n', '<Space>', ':Qlink<CR>', { noremap = true, silent = true })
    -- qclose_qfix()
    win:open()
    qfloat.win_id = win.id
    -- win:
    vim.cmd('normal! zt') -- cursor at the top
end

-- Function to close the floating quickfix window
function qfloat.qclose()
    if Window.close(qfloat.winid) then
        qfloat.win_id = nil
    else
        vim.notify("No floating quickfix window to close.")
    end
end

-- Store the window ID of the floating quickfix window
function qfloat.qtoggle()
    if qfloat.win_id and vim.api.nvim_win_is_valid(qfloat.win_id) then
        qfloat.qclose()
    elseif vim.tbl_isempty(vim.fn.getqflist()) then
        vim.notify("Quickfix list is empty.")
    else
        qfloat.qopen()
    end
end

qfloat.qchoose = function(filename, is_nvim)
    is_nvim = is_nvim or true
    local cmd
    if vim.o.filetype == 'lua' then
        if is_nvim then
            cmd = 'dofile("' .. filename .. '")'
        else
            cmd = fmt('system("lua.fish %s")', filename)
        end
    else
        cmd = fmt('system("%s %s")', vim.o.filetype, filename)
    end
    return cmd
end

qfloat.qrun_file = function(filename, is_nvim)
    is_nvim = is_nvim or true
    local cmd = qfloat.qchoose(filename, is_nvim)
    if is_nvim then
        require(filename:sub(30, -5)) -- remove ~/git/scripts/lua/ and .lua
        qfloat.qmessage()
    else
        qfloat.qrun(cmd)
    end
end

qfloat.qrun_current = function(is_nvim)
    qfloat.qrun_file(fs.get_current_file(), is_nvim)
end

qfloat.qrun_last = function(is_nvim)
    qfloat.qrun_file(qfloat.last_file, is_nvim)
end

-- Function to move to the next item in quickfix list
function qfloat.qnext()
    local is_qf = qfloat.is_quickfix()
    if is_qf then
        if vim.fn.getqflist({ idx = 0 }).idx == vim.fn.getqflist({ size = 1 }).size then
            vim.cmd("cfirst")
        else
            vim.cmd("cnext")
        end
        vim.cmd("normal! zt") -- Center the cursor
    else
        vim.cmd.wincmd('p')
    end
end

function qfloat.is_quickfix()
    return vim.bo.filetype == 'qf'
end

-- Function to move to the previous item in quickfix list
function qfloat.qprev()
    local is_qf = qfloat.is_quickfix()

    if is_qf then
        if vim.fn.getqflist({ idx = 0 }).idx == 1 then
            vim.cmd("clast")
        else
            vim.cmd("cprevious")
        end
        vim.cmd("normal! zt") -- Center the cursor
    else
        vim.cmd.wincmd('p')
    end
end

-- Function to get the file and line number of the quickfix entry of the line '.'
function qfloat.qget_link()
    local line = vim.fn.getline('.')
    local list_item = utils.split(line, '|')

    if list_item == nil or #list_item < 2 then
        vim.notify("No quickfix entry found(qget_link).")
        return nil
    end
    local file = list_item[1]
    local n_line = list_item[2]
    return file, n_line
end

-- Function to open the file at the current line
function qfloat.qlink()
    local file, line = qfloat.qget_link()
    if file == nil or line == nil then
        vim.notify('qlink error: No quickfix entry found.')
        return
    end
    vim.cmd('wincmd k') -- Center the cursor
    vim.cmd('edit ' .. file)
    vim.fn.cursor(line, 0)
    vim.cmd('wincmd p') -- Center the cursor
end

function qfloat.qopen_close()
    qfloat.qopen()
end

-- Function to open the file at the current line and close the quickfix window
function qfloat.qclose_link()
    -- local qf_entry = vim.fn.getqflist({ idx = 0 }) -- Get the current quickfix entry
    local file, line = qfloat.qget_link()
    if file == nil or line == nil then
        vim.notify('qclose_link error: No quickfix entry found.')
        return
    end

    vim.cmd('cclose')        -- Close the quickfix window
    vim.cmd('edit ' .. file) -- Open the file
    vim.fn.cursor(line, 0)   -- Move to the correct line
end

function qfloat.update_time(buf)
    local time = os.date("%H:%M:%S")
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { time })
end

function qfloat.qmessage()
    local out = vim.api.nvim_exec2('messages', { output = true })
    local messages = out.output
    local filename = qfloat.qstring(messages)
    qfloat.qfile(filename)
    -- check quickfix list size
    local qf = vim.fn.getqflist()
    if #qf == 0 then
        vim.notify('No errors found.')
    end
end

-- function to set the quickfix list from a string represening all error lines.
function qfloat.qset(errors)
    vim.fn.setqflist(errors, 'r') -- 'r' replaces the current quickfix list
end

-- Function to set the quickfix list from a string represening all error lines.
-- lines must be separated by '\n' to be parsed, or use the optional sep parameter.
function qfloat.qstring(lines_str, sep)
    sep = sep or '\n'
    local filename = qfloat.qparse_all(utils.split(lines_str, sep))
    if filename ~= nil then
        return filename
    else
        vim.notify("No errors found to populate the quickfix.")
        return nil
    end
end

-- Function to parse the error lines and return a table with the errors
-- lines are a list of lines
function qfloat.qparse_all(lines_list)
    local filename = '/tmp/error_lua2.log'
    local fd = io.open(filename, 'w')
    if fd == nil then
        vim.notify("Failed to open file: " .. filename)
        return nil
    end
    for _, line in ipairs(lines_list) do
        fd:write(line .. '\n')
    end
    fd:close()

    local cmd = 'parse_lua_error.fish ' .. filename
    local handle = io.popen(cmd)
    if not handle then
        vim.notify("Failed to execute command: " .. cmd)
        return nil
    end
    handle:close()

    return filename
end

-- clean e list of errors for lua
function qfloat.qparse(line)
    local file, lnum, message = string.match(line, '^(.*[%w./]+):(%d+):(.*)')
    -- local filepath, lnum, message = line:match("([^:]+):(%d+):?(.*)")

    if file == nil then
        vim.notify("Error parsing line: " .. line)
        return nil
    end
    file = utils.split(file, ' ')[1]
    local filename = file[#file]
    return {
        filename = filename,
        lnum = tonumber(lnum),
        text = message, -- Using 0 to refer to the current buffer
    }
end

function qfloat.is_quickfix_open()
    for _, win in ipairs(vim.fn.getwininfo()) do
        if win.quickfix == 1 then
            return true
        end
    end
    return false
end

if vim.g.proj_enabled == nil or vim.g.proj_enabled == false then
    qfloat.init()


    vim.api.nvim_set_keymap('n', '<M-q>', ':Qtoggle<CR>', { noremap = true, silent = true })
    vim.api.nvim_set_keymap('n', '[q', ':Qprev<CR>', { noremap = true, silent = true })
    vim.api.nvim_set_keymap('n', ']q', ':Qnext<CR>', { noremap = true, silent = true })
    -- vim.api.nvim_set_keymap('n', '<F3>',      ':QrunCurrent<CR>', { noremap = true, silent = true })
    -- vim.api.nvim_set_keymap('n', '<F4>',      ':QrunFzf<CR>',     { noremap = true, silent = true })

    vim.api.nvim_create_user_command("Qlink", qfloat.qlink, {})
    vim.api.nvim_create_user_command("QlinkClose", qfloat.qclose_link, {})
    vim.api.nvim_create_user_command("Qtoggle", qfloat.qtoggle, {})
    vim.api.nvim_create_user_command("Qnext", qfloat.qnext, {})
    vim.api.nvim_create_user_command("Qprev", qfloat.qprev, {})
    vim.api.nvim_create_user_command("Qopen", qfloat.qopen, {})
    vim.api.nvim_create_user_command("Qfile", qfloat.qfile, {})
    vim.api.nvim_create_user_command("QrunFzf", qfloat.qrun_fzf, {})
    vim.api.nvim_create_user_command("QrunCurrent", qfloat.qrun_current, {})
    vim.api.nvim_create_user_command("QrunLast", qfloat.qrun_last, {})
    vim.api.nvim_create_user_command("Qclose", Window.close, {})
    vim.api.nvim_create_user_command("Qmessage", qfloat.qmessage, {})
    vim.api.nvim_create_user_command("Qrun",
        function(args)
            qfloat.qrun(args)
        end,
        { nargs = '*' }
    )

    vim.api.nvim_set_keymap('n', ',q', ':Qrun_current<CR>', { noremap = true, silent = true })
    vim.api.nvim_set_keymap('n', '<F6>', ':Qcheck<CR>', { noremap = true, silent = true })
    vim.api.nvim_create_user_command("Qcheck",
        function(args)
            local fname = args.fargs[1]
            if fname == nil then
                -- get current file
                fname = vim.fn.expand('%')
                if fname == nil or fname == '' then
                    vim.notify('No file to check.')
                    return
                end
            end
            qfloat.qcheck(fname)
        end,
        {}
    )
end
vim.g.proj_enabled = true


return qfloat
