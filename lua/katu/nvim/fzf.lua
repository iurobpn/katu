local M = {}
local fzf_options = {
    dir = '~/path',
    options = {
        -- fzf shell options
    },
    source = 'pattern', -- {} or function?.
    sink = function(line) return line end, --function(each line) or execute (shell? there is a shell escape),
    ['sink*'] = function(lines) return lines end, -- sink* function(lines) or execute (shell? there is a shell escape),
    sinklist = function(lines) return lines end, -- function(lines) or execute (shell? there is a shell escape),
    pushd = '', -- ? see fzf_pushd
    -- might be options, called with s:present and not has_key like the above
    window = { -- has to be a dict
        'down', -- those might be out in the main options
        'up',
        'left',
        'right', -- position of the preview? semms that it is the position of the whole window

        border = true,
        rounded = true,
        sharp = false,
        highlight = '#000000', -- gives the fg color of the border
    },
}


function M.exec(source, ...)
    if source == nil then
        source = 'fd . --type f --hidden --follow --exclude .git --exclude .gtags'
    end
    local options = {...}
    options = options[1]

    if options == nil then
        options = {}
    end

    if options.sink == nil then
        options.sink = function(selected)
            for _, file in ipairs(selected) do
                vim.cmd.edit(file)
            end
        end
    end

    if options.prompt == nil then
        options.prompt = 'search>'
    end

    -- Perform the fzf search
    local fzf_lua = require'fzf-lua'
    fzf_lua.fzf_exec(source, {
        prompt = options.prompt,
        multi = options.multi or true,  -- Allow multiple selections
        actions = {
            -- On selecting tasks, ask if the user wants to refine the search
            ["default"] = options.sink
        }
    })
    --    sink = function(selected)
    --     -- capture the selected tasks
    --     local selected_tasks = {}
    --     for _, task_line in ipairs(selected) do
    --         -- extract file and line information (and other data)
    --         table.insert(selected_tasks, task_line)
    --     end
    --
    --     -- prompt for refining the search on the selected tasks
    --     m.prompt_refine_search(selected_tasks)
    -- end
end

function M.cd(opts)
    if opts == nil then
        dir = '~'
    else
        dir = opts
    end
    local source = 'fd . -td --hidden --exclude .git --exclude .gtags ' .. dir
    local options = {
        sink = function(selected)
            vim.cmd('cd ' .. selected[1])
        end
    }
    M.exec(source, options)
end
M.lcd = function(opts)
    if opts == nil then
        dir = '~'
    else
        dir = opts
    end
    local source = 'fd . -td --hidden --exclude .git --exclude .gtags ' .. dir
    local options = {
        sink = function(selected)
            vim.cmd('lcd ' .. selected[1])
        end
    }
    M.exec(source, options)
end


function M.run(arg)
    local source, sink

    local options
    if arg ~= nil then
        source = arg.source
        sink = arg.sink
        options = arg.options
    end
    if not source then
        source = 'fd . --type f --hidden --follow --exclude .git --exclude .gtags'
    end
    if arg ~= nil and type(arg.source_append) == 'string' then
        source = source .. ' ' .. arg.source_append
    end

    -- if not sink then
    --     sink = function(selected)
    --         vim.cmd('edit ' .. selected)
    --     end
    -- end
    if options == nil or options == '' then
        options = '--prompt="select> "'
    end

    return vim.fn['fzf#run']({source = source, sink = sink, options = options})
end
function M.ls_files_from_branch(args)
    require 'fzf-lua'.files({
        cmd = "git ls-tree -r --name-only " .. args,
        prompt = args .. "> ",
        actions = {
            ['default'] = false,
            ['ctrl-s'] = false,
            ['ctrl-v'] = function(selected, o)
                local file = require'fzf-lua'.path.entry_to_file(selected[1], o)
                local cmd = string.format("Gvsplit %s:%s", args, file.path)
                vim.cmd(cmd)
            end,
        },
        previewer = false,
        preview =  {
            type = "cmd",
            fn = function(items)
                local file = require'fzf-lua'.path.entry_to_file(items[1])
                return string.format("git diff %s HEAD -- %s | delta", args, file.path)
            end
        }
    })
end

return M
