local M = {}
local function paste_str(line)
    -- print('lines: ' .. vim.inspect(lines))
    vim.api.nvim_put({line},'l',true,false)
end

local function get_hist(cmd,prompt)
    local opts='-m ' .. prompt
    vim.fn['fzf#run']({source = cmd, sink = paste_str, options = opts})
end

function M.get_zsh_hist()
    local cmd="cat $HOME/.zsh_history | cut -d';' -f2"
    local prompt='--prompt="zsh hist> "'
    get_hist(cmd,prompt)
end
function M.get_fish_hist()
    local cmd="cat $HOME/.local/share/fish/fish_history | sed -n '/cmd:/p' | sed -e 's/- cmd: //'"
    local prompt='--prompt="fish hist> "'
    get_hist(cmd,prompt)
end
function M.get_bash_hist()
    local cmd="cat $HOME/.bash_history"
    local prompt='--prompt="bash hist> "'
    get_hist(cmd,prompt)
end

function M.complete(arg_lead, cmd_line, cursor_pos)
    -- These are the valid completions for the command
    local options = { "bash", "zsh", "fish"}
    -- Return all options that start with the current argument lead
    return vim.tbl_filter(function(option)
        return vim.startswith(option, arg_lead)
    end, options)
end

-- Command to start or control the countdown timer
vim.api.nvim_create_user_command("Hist", function(opts)
    local args = opts.fargs
    if #args >= 1 then
        local arg = args[1]
        if arg == "bash" then
            M.get_bash_hist()
        elseif arg == "zsh" then
            M.get_zsh_hist()
        elseif arg == "fish" then
            M.get_fish_hist()
        end
    else
        print("Usage: :Hist shell_name")
    end
end, { nargs = "?" , complete = M.complete })

vim.api.nvim_set_keymap('n', '<leader>hb', '<cmd>Hist bash<CR>"', {noremap=true, desc='Search and get bash history'})
vim.api.nvim_set_keymap('n', '<leader>hz', '<cmd>Hist zsh<CR>"', {noremap=true, desc='Search and get zsh history'})
vim.api.nvim_set_keymap('n', '<leader>hf', '<cmd>Hist fish<CR>"', {noremap=true, desc='Search and get fish history'})

return M
