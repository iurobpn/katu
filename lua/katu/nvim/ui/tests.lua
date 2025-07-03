require('dev.nvim.ui.float')
function test_pos()
    local win = Window()
    table.insert(wins,win)
    win:config(
        {
            name = 'draft1 ',
            position = 'top-right'
        }
    )
    win.name = win.name .. win.position
    win:open()

    win = Window()
    table.insert(wins,win)

    win:config(
        {
            name = 'draft2 ',
            position = 'top-left'
        }
    )
    win.name = win.name .. win.position
    win:open()

    win = Window()
    table.insert(wins,win)

    win:config(

        {
            name = 'draft3 ',
            position = 'bottom-right'
        }
    )
    win.name = win.name .. win.position
    win:open()

    win = Window()
    table.insert(wins,win)
    win:config(
        {
            name = 'draft4 ',
            position = 'bottom-left'
        }
    )
    win.name = win.name .. win.position
    win:open()

    print('corner Float sizes')
    for _, wi in ipairs(wins) do
        print('Win: ' .. win.name)
        wi:params()
    end
end

function test_window()
    local win = Window()
    win.width = 0.5
    win.height = 0.5
    win.row = 0.5
    win.col = 0.5
    win:open()
    win:params()
end

function test_popup()
    local win = Window.popup({content='hello'})
    win:open()
    win:params()
end

function popup(...)
    local buf = vim.api.nvim_create_buf(false, true)  -- false for listed, true for scratch

    local ui_width = vim.api.nvim_get_option("columns")
    local ui_height = vim.api.nvim_get_option("lines")
    local opts = {
        relative = 'editor',
        width = 8,
        height = 3,
        row = math.floor((ui_height - 8) / 2),
        col = math.floor((ui_width - 3) / 2),
        style = 'minimal',
        border = 'rounded',
        option = {
            buffer = {
                modifiable = false,
            },
        },
        buffer = {
            listed = false,
            scratch = true,
        },
    }
    for k, v in pairs(arg) do
        opts[k] = v
    end

    local win = vim.api.nvim_open_win(buf, true, opts)
end

