local Clock = {
    window = nil
}

function Clock.update(buf, t_period)
    if not buf then
        error('Clock buffer not found')
        return
    end
    if not t_period then
        t_period = 1000 -- ms
    end
    -- Function to update the time in the buffer
    local function update_time()
        -- Get the current time
        local current_time = os.date("%H:%M:%S")
        -- Update the buffer content
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, {current_time})
    end

    -- Run the update_time function every 60 seconds
    vim.defer_fn(function()
        -- Check if the window still exists
        if vim.api.nvim_buf_is_valid(buf) then
            update_time()
            -- Re-run the function to continue the update loop
            Clock.update(buf, t_period)
        end
    end, t_period) -- 60000 ms = 1 min
end

function Clock.toggle()
    if Clock.window then
        Clock.close()
    else
        Clock.open()
    end
end

function Clock.redraw()
    if Clock.window then
        Clock.window:redraw()
    end
end

-- Set an autocommand to trigger the repositioning on VimResized
vim.api.nvim_create_autocmd("VimResized", {
  callback = Clock.redraw
})

function Clock.open(t)
    local win = nil
    if Clock.window then
        win = Clock.window
    else
        win = require('katu.nvim.ui.views').popup()
    end
    t = t or 1000
    win:config(
        {
            name = 'clock',
            focusable = false,
            style = 'minimal',
            -- unlisted buffer
            buffer = {
                listed = false,
                scratch = true,
            },
            size = {
                absolute = {
                    height = 1,
                    width = 8
                }
            },
            border = 'rounded',
            position = 'top-right',
            options = {
                buffer = {
                    modifiable = true,
                    -- buftype = 'nowrite',
                    bufhidden = 'wipe',
                    buflisted = false,
                    swapfile = false,
                }
            },
            is_toggleable = false
        }
    )
    win:add_map('n', ':bnext', ':wincmd p<CR>', { noremap = true, silent = true })
    win:add_map('n', ':bprev', ':wincmd p<CR>', { noremap = true, silent = true })
    win:open()
    vim.api.nvim_set_option_value('winblend', 90, {win = win.vid, scope = "local"}) -- Set transparency (0-100, 0 is opaque, 100 is fully transparent)
    vim.api.nvim_set_option_value('winhl', 'NormalFloat:Normal,FloatBorder:Normal', {win = win.vid, scope="local"}) -- Follow main colorscheme
    vim.cmd('wincmd p') -- clock is not focusable, so we need to focus the previous window
    -- win:params()
    Clock.update(win.buf, t)
    Clock.window = win
end

function Clock.close()
    if Clock.window then
        Clock.window:close()
        Clock.window = nil
    else
        print('Clock is not open')
    end
end

vim.api.nvim_create_user_command("Clock", function () Clock.toggle() end, {})

return Clock
