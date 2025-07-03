-- You can use this loaded variable to enable conditional parts of your plugin.
if _G.katuLoaded then
    return
end

_G.katuLoaded = true

-- Useful if you want your plugin to be compatible with older (<0.7) neovim versions
-- if vim.fn.has("nvim-0.7") == 0 then
    -- vim.cmd("command! TasksInit lua require('tasks').toggle()")
-- else
    -- vim.api.nvim_create_user_command("TasksInitial", require'tasks'.toggle, {})
-- end
