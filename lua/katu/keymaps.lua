-- markdown
local keymap = {
    mode = 'n',
    keys = 'gf'
}

vim.api.nvim_set_keymap(
    keymap.mode,
    keymap.keys,
    ":lua require'katu.nvim.mdlinks'.open_mdlink()<CR>",
    { noremap = true, silent = true, desc = "Open markdown link" }
)

-- cpp
vim.api.nvim_set_keymap('n', '<F10>', '<cmd>Cpp<CR>', { noremap = true, silent = true, desc = 'C++ config, build and run commands' })

vim.api.nvim_set_keymap('n', '<leader>hb', '<cmd>Hist bash<CR>"', {noremap=true, desc='Search and get bash history'})
vim.api.nvim_set_keymap('n', '<leader>hz', '<cmd>Hist zsh<CR>"', {noremap=true, desc='Search and get zsh history'})
vim.api.nvim_set_keymap('n', '<leader>hf', '<cmd>Hist fish<CR>"', {noremap=true, desc='Search and get fish history'})

vim.api.nvim_set_keymap('n', '<M-q>', ':Qtoggle<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '[q', ':Qprev<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', ']q', ':Qnext<CR>', { noremap = true, silent = true })

vim.api.nvim_set_keymap('n', '<LocalLeader>n', ':WinNew<CR>',         { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', 'gç',             ':WinOpenCurrent<CR>', { noremap = true, silent = true })
