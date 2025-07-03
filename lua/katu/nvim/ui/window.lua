local Window = require('dev.nvim.ui.float').Window
local utils = require'utils'

local Float = {
    window = nil,
    buf = nil,
}

function Float.toggle()
    if Float.window then
        Float.close()
    else
        Float.open()
    end
end

function Float.open()
    local win = nil
    if Float.window then
        win = Float.window
    else
        win = Window()
    end
    if not win then
        print('Error creating window (nil ret)')
        return
    end
    win:config(
        {
            name = 'draft',

            close_map = {
                mode = 'n',
                key = 'ESC',
                cmd = ':lua Float.close()<CR>',
                opts = { noremap = true, silent = true }
            },
        }
    )
    if Float.buf then
        win.buf = Float.buf
    end
    win:open()
    Float.buf = win.buf
    -- win:params()
    Float.window = win
    local win_config = vim.api.nvim_win_get_config(win.id)
    Float.zindex = win_config.zindex
    Float.visible = win.id
    Window.floats[win.id] = win
end

function Float.close()
    if Float.window then
        utils.traceback()
        print('Closing float')
        Float.window.close()
        Float.window = nil
    else
        print('Window is not open')
    end
end

local wins = {}


function Float.custom_win(pos,size)
    local win = Window()
    win:config(
        {
            name = 'draft1 ',
            position = pos,
            size = size
        }
    )
    win:open()
    Float.window = win
    return win
end
function Float.clear()
    if Float.window then
        Float.window:close()
        Float.window = nil
    else
        print('Window is not open')
    end
    Float.buf = nil
end

function Float.toggle_fullscreen()
    local win_id = vim.fn.win_getid()
    local win_config = vim.api.nvim_win_get_config(win_id)
    if Window.floats[win_id].fullscreen then
        Window.redraw()
    else
        Window.fullscreen()
    end
end




function close_wins()
    for _,win in ipairs(wins) do
        win:close()
    end
end

vim.api.nvim_create_user_command("Float", "lua Float.toggle()", {})
vim.api.nvim_create_user_command("FloatOpen", "lua Float.open()", {})
vim.api.nvim_create_user_command("FloatClose", "lua Float.close()", {})
vim.api.nvim_create_user_command("FloatToggleFullScreen", "lua Float.toggle_fullscreen()", {})

-- define maps
-- vim.api.nvim_set_keymap('n', 'ç+c', ':FloatClear<CR>', { noremap = true, silent = true })
-- vim.api.nvim_set_keymap('n', 'º', ':FloatToggleFullScreen<CR>', { noremap = true, silent = true })
--
local M = {
    Float = Float,
    close_wins = close_wins,
    wins = wins,
}
return M
