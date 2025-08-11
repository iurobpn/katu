local views = {}

function views.new()
    local Window = require('katu.nvim.ui.float').Window
    local win = Window()
    return win
end

function views.messages()
    local win = views.minimal()
    -- get the messages from nvim

    local out = vim.api.nvim_exec2('messages', {output = true})
    local messages = out.output
    if type(messages) == 'string' then
        messages = vim.split(messages, '\n')
    end
    win:config(
        {
            content = messages,
            buffer = {
                scratch = true,
                listed = false,
            },
            options = {
                buffer = {
                    modifiable = false,
                }
            }
        })
    win:open()
    return win
end

views.fixed_id = nil
function views.close_fixed_right()
    -- Close the rightmost window with 'winfixwidth' set
    if vim.api.nvim_win_get_option(views.fixed_id, 'winfixwidth') then
        vim.api.nvim_win_close(views.fixed_id, true)
    else
        vim.notify("No fixed right window found.")
    end
    views.fixed_id = nil
end

function views.toggle_fixed_left()
    if views.fixed_id ~= nil then
        views.close_fixed_left()
    else
        views.open_fixed_left()
    end
end
function views.toggle_fixed_right()
    if views.fixed_id ~= nil then
        views.close_fixed_right()
    else
        views.open_fixed_right()
    end
end

function views.close_fixed_left()
    -- Close the rightmost window with 'winfixwidth' set
    if vim.api.nvim_win_get_option(views.lfixed_id, 'winfixwidth') then
        vim.api.nvim_win_close(views.lfixed_id, true)
    else
        vim.notify("No fixed right window found.")
    end
    views.lfixed_id = nil
end

-- Map the function to a command for easy access
function views.open_fixed_left(buf)
    buf = buf or ''
    -- Open a vertical split with the buffer
    vim.cmd('vertical sbuffer ' .. (buf or ''))

    -- Move it to the far right
    vim.cmd('wincmd H')
    -- Fix its width
    vim.cmd('setlocal winfixwidth')
    -- Calculate 25% of the current screen width
    local total_width = vim.o.columns
    local new_width = math.floor(total_width * 0.25)

    -- Set the window width
    vim.cmd('vertical resize ' .. new_width)
    
    -- Save the window ID for later
    views.lfixed_id = vim.api.nvim_get_current_win()
end
-- Map the function to a command for easy access
function views.open_fixed_right(buf)

    if buf ~= nil then
        -- Open a vertical split with the buffer
        vim.cmd('vertical sbuffer ' .. buf)
    else
        -- Open a vertical split
        vim.cmd('vertical vsplit')
    end
    -- Move it to the far right
    vim.cmd('wincmd L')
    -- Fix its width
    vim.cmd('setlocal winfixwidth')
    -- Ensure splits open to the right
    vim.o.splitright = true
    -- Calculate 25% of the current screen width
    local total_width = vim.o.columns
    local new_width = math.floor(total_width * 0.25)
    -- Set the window width
    vim.cmd('vertical resize ' .. new_width)
    
    -- Save the window ID for later
    views.fixed_id = vim.api.nvim_get_current_win()
end
-- Map the function to a command or keybinding if desired
vim.api.nvim_create_user_command('FixedRight', views.toggle_fixed_right, {})

function views.get_scratch_opt()
    return {
        scratch = true,
        listed = false,
    }
end

function views.minimal()
    local Window = require('katu.nvim.ui.float').Window
    local win = Window()
    win:config({style = "minimal"})
    return win
end

function views.open_current_window()
    local Window = require('katu.nvim.ui.float').Window
    local win = Window()
    win.current = true
    win:open()
end

function views.popup(...)
    local Window = require('katu.nvim.ui.float').Window
    local win = Window()

    local args = {...}
    args = args[1]
    -- local args = {...}
    local opts = {
        size = {
            absolute = {
                width = 8,
                height = 1,
            }
        },
        border = "round",
        zindex = 50,
        position = 'center',
        anchor = 'NW',
        style = "minimal",
        option = {
            buffer = {
                modifiable = true,
            }
        },
        cursor = false,
        current = false,
    }
    if args then
        for k, v in pairs(args) do
            opts[k] = v
        end
    end
    win.config(opts)

    return win
end

function views.scratch(content, ...)
    local opts = {...}
    opts = opts[1] or {}

    local Window = require('katu.nvim.ui.float').Window
    local win = Window()

    opts.buffer = views.get_scratch_opt()
    opts.content = content
    opts.option = {
        buffer = {
            modifiable = true,
        }
    }

    win:config(opts)
    return win
end


return views
