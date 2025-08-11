-- floating_command.lua
local M = {}

-- Function to run a shell command and display the output in a floating window
function M.run_command_in_float(cmd)
    -- Run the shell command and capture the output
    local handle = io.popen(cmd)
    local output = handle:read("*a")
    handle:close()

    -- Create a new buffer for the output
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(output, "\n"))

    -- Get the dimensions of the main window
    local width = vim.api.nvim_get_option("columns")
    local height = vim.api.nvim_get_option("lines")

    -- Calculate the size and position of the floating window
    local win_width = math.floor(width * 0.8)
    local win_height = math.floor(height * 0.8)
    local row = math.floor((height - win_height) / 2)
    local col = math.floor((width - win_width) / 2)

    -- Create the floating window
    local opts = {
        style = "minimal",
        relative = "editor",
        width = win_width,
        height = win_height,
        row = row,
        col = col,
        border = "rounded"
    }

    local win = vim.api.nvim_open_win(buf, true, opts)

    -- Set some options for the floating window
    vim.api.nvim_win_set_option(win, "number", false)
    vim.api.nvim_win_set_option(win, "relativenumber", false)
    vim.api.nvim_win_set_option(win, "wrap", true)
    vim.api.nvim_win_set_option(win, "cursorline", false)

    -- Close the floating window when pressing 'q' or '<Esc>'
    vim.api.nvim_buf_set_keymap(buf, "n", "q", ":q<CR>", { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(buf, "n", "<Esc>", ":q<CR>", { noremap = true, silent = true })
end


return M
