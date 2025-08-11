vim.api.nvim_create_user_command(
    'ListFilesFromBranch',
    'lua require("katu.nvim.fzf").ls_files_from_branch("<args>")',
    {
        nargs = 1,
        force = true,
        complete = function()
            local branches = vim.fn.systemlist("git branch --all --sort=-committerdate")
            if vim.v.shell_error == 0 then
                return vim.tbl_map(function(x)
                    return x:match("[^%s%*]+"):gsub("^remotes/", "")
                end, branches)
            end
        end,
    }
)

vim.api.nvim_create_user_command(
    'Fcd',
    'lua require("katu.nvim.fzf").cd("<args>")',
    {
        nargs = '?',
    }
)
vim.api.nvim_create_user_command(
    'Flcd',
    'lua require("katu.nvim.fzf").lcd("<args>")',
    {
        nargs = '?',
    }
)

-- cpp
vim.api.nvim_create_user_command(
    'Cpp',
    'lua require("katu.nvim.cppbuild").command("<args>")',
    {
        nargs = '*',
        complete = require"katu.nvim.cppbuild".complete_command,
        desc = 'C++ config, build and run commands',
    }
)


-- Command to start or control the countdown timer
vim.api.nvim_create_user_command(
    "Hist",
    'lua require"katu.nvim.sh_hist".get_hist("<args>")',
    {
        nargs = "?" ,
        complete = require"katu.nvim.sh_hist".complete,
    }
)

-- Expose the function to be used as a command
vim.api.nvim_create_user_command(
    "RunFloat", 
    'lua require"katu.nvim.runfloat".run_command_in_float("<args>")',
    {
        nargs = 1
    }
)

-- create the command
vim.api.nvim_create_user_command("Win",
    'lua require"katu.nvim.ui.float".command("<args>")',
    {
        nargs = "*",
        complete = require"katu.nvim.ui.float".Window.complete,
        bang = true,
        desc = 'Window commands'
    }
)


vim.api.nvim_create_user_command("Qlink", 'lua require"katu.nvim.ui.qfloat".qlink("<args>")', {})
vim.api.nvim_create_user_command("QlinkClose", 'lua require"katu.nvim.ui.qfloat".qclose_link("<args>")', {})
vim.api.nvim_create_user_command("Qtoggle", 'lua require"katu.nvim.ui.qfloat".qtoggle("<args>")', {})
vim.api.nvim_create_user_command("Qnext", 'lua require"katu.nvim.ui.qfloat".qnext("<args>")', {})
vim.api.nvim_create_user_command("Qprev", 'lua require"katu.nvim.ui.qfloat".qprev("<args>")', {})
vim.api.nvim_create_user_command("Qopen", 'lua require"katu.nvim.ui.qfloat".qopen("<args>")', {})
vim.api.nvim_create_user_command("Qfile", 'lua require"katu.nvim.ui.qfloat".qfile("<args>")', {})
vim.api.nvim_create_user_command("QrunFzf", 'lua require"katu.nvim.ui.qfloat".qrun_fzf("<args>")', {})
vim.api.nvim_create_user_command("QrunCurrent", 'lua require"katu.nvim.ui.qfloat".qrun_current("<args>")', {})
vim.api.nvim_create_user_command("QrunLast", 'lua require"katu.nvim.ui.qfloat".qrun_last("<args>")', {})
vim.api.nvim_create_user_command("Qclose", 'lua require"katu.nvim.ui.qfloat".qclose("<args>")', {})
vim.api.nvim_create_user_command("Qmessage", 'lua require"katu.nvim.ui.qfloat".qmessage("<args>")', {})
vim.api.nvim_create_user_command(
    "Qrun",
    'lua require"katu.nvim.ui.qfloat".qrun("<args>")',
    {
        nargs = '*'
    }
)

vim.api.nvim_create_user_command("WinNew",         'lua katu.nvim.ui.views.new()',          {})
vim.api.nvim_create_user_command("WinOpenCurrent", 'lua katu.nvim.ui.views.open_current()', {})
vim.api.nvim_create_user_command("Messages",    'lua katu.nvim.ui.views.messages()',     {})

vim.api.nvim_create_user_command(
    'TemplIns', 
    'lua require"katu.lua".expand_file("<args>")',
    {
        nargs='?'
    }
)

